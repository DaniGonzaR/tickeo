import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/parsers/base_parser.dart';
import 'package:tickeo/services/ticket_classifier.dart';

/// Parser especializado para tickets de supermercados
class SupermarketParser extends BaseParser {
  @override
  TicketType get supportedType => TicketType.supermarket;

  @override
  Future<List<BillItem>> parseTicket(
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
  ) async {
    print('🛒 PARSEANDO TICKET DE SUPERMERCADO...');
    
    final text = ocrResult.consensusText;
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    print('📄 Procesando ${lines.length} líneas...');
    
    final items = <BillItem>[];
    
    // Estrategia 1: Parsing específico para supermercados
    items.addAll(await _parseSupermarketFormat(lines));
    
    // Estrategia 2: Parsing de productos con códigos de barras
    if (items.length < 3) {
      print('⚠️ Pocos items encontrados, buscando códigos de barras...');
      items.addAll(await _parseWithBarcodes(lines));
    }
    
    // Estrategia 3: Parsing por columnas (producto | precio)
    if (items.length < 2) {
      print('⚠️ Aplicando parsing por columnas...');
      items.addAll(await _parseColumnFormat(lines));
    }
    
    // Estrategia 4: Parsing genérico como fallback
    if (items.isEmpty) {
      print('⚠️ Sin items, aplicando parsing genérico...');
      items.addAll(await defaultParsing(lines));
    }
    
    print('✅ PARSING SUPERMERCADO COMPLETADO: ${items.length} items');
    return _removeDuplicates(items);
  }

  /// Parsing específico para formato de supermercado
  Future<List<BillItem>> _parseSupermarketFormat(List<String> lines) async {
    final items = <BillItem>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (isHeaderOrFooter(line)) continue;
      
      // Patrón típico de supermercado: PRODUCTO + PRECIO al final
      // Ej: "LECHE PASCUAL DESNATADA 1L    2,45"
      final supermarketPattern = RegExp(r'^([A-Za-záéíóúñü\s\d]+?)\s+(\d+[.,]\d{2})\s*[ABC]?\s*$');
      final match = supermarketPattern.firstMatch(line);
      
      if (match != null) {
        final productName = match.group(1)!.trim();
        final priceStr = match.group(2)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (isValidPrice(price) && productName.length >= 3) {
          final cleanName = _improveSupermarketProductName(productName);
          items.add(createBillItem(cleanName, price));
        }
      } else {
        // Patrón alternativo: cantidad x precio unitario = total
        // Ej: "2 x 1,25 YOGUR DANONE = 2,50"
        final quantityPattern = RegExp(r'(\d+)\s*x\s*(\d+[.,]\d{2})\s*([A-Za-záéíóúñü\s]+?)\s*=?\s*(\d+[.,]\d{2})');
        final qMatch = quantityPattern.firstMatch(line);
        
        if (qMatch != null) {
          final quantity = int.tryParse(qMatch.group(1)!) ?? 1;
          final unitPriceStr = qMatch.group(2)!.replaceAll(',', '.');
          final productName = qMatch.group(3)!.trim();
          
          final unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
          
          if (isValidPrice(unitPrice) && productName.length >= 3) {
            final cleanName = _improveSupermarketProductName(productName);
            
            // Crear items individuales si hay cantidad > 1
            for (int j = 0; j < quantity; j++) {
              items.add(createBillItem(cleanName, unitPrice));
            }
          }
        }
      }
    }
    
    return items;
  }

  /// Parsing con códigos de barras
  Future<List<BillItem>> _parseWithBarcodes(List<String> lines) async {
    final items = <BillItem>[];
    
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      final nextLine = lines[i + 1].trim();
      
      // Buscar código de barras seguido de producto y precio
      final barcodePattern = RegExp(r'^\d{8,13}$');
      if (barcodePattern.hasMatch(line)) {
        // La siguiente línea debería tener el producto y precio
        final prices = extractPricesFromLine(nextLine);
        if (prices.isNotEmpty && !isHeaderOrFooter(nextLine)) {
          String productName = nextLine;
          for (final price in prices) {
            productName = productName.replaceAll(price.toString(), '');
            productName = productName.replaceAll(price.toStringAsFixed(2), '');
          }
          
          productName = cleanProductName(productName);
          if (productName.length >= 2) {
            final cleanName = _improveSupermarketProductName(productName);
            items.add(createBillItem(cleanName, prices.first));
          }
        }
      }
    }
    
    return items;
  }

  /// Parsing por columnas (formato tabular)
  Future<List<BillItem>> _parseColumnFormat(List<String> lines) async {
    final items = <BillItem>[];
    
    // Detectar si hay un formato de columnas
    // Buscar líneas que tengan espacios consistentes entre producto y precio
    
    for (final line in lines) {
      if (isHeaderOrFooter(line)) continue;
      
      // Buscar patrón: texto + espacios múltiples + precio
      final columnPattern = RegExp(r'^([A-Za-záéíóúñü\s\d]+?)\s{3,}(\d+[.,]\d{2})\s*$');
      final match = columnPattern.firstMatch(line);
      
      if (match != null) {
        final productName = match.group(1)!.trim();
        final priceStr = match.group(2)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (isValidPrice(price) && productName.length >= 3) {
          final cleanName = _improveSupermarketProductName(productName);
          items.add(createBillItem(cleanName, price));
        }
      }
    }
    
    return items;
  }

  /// Mejora nombres de productos de supermercado
  String _improveSupermarketProductName(String productName) {
    String improved = cleanProductName(productName);
    
    // Diccionario de mejoras específicas para supermercados
    final improvements = {
      // Lácteos
      'leche': 'Leche',
      'yogur': 'Yogur',
      'queso': 'Queso',
      'mantequilla': 'Mantequilla',
      
      // Carnes
      'pollo': 'Pollo',
      'ternera': 'Ternera',
      'cerdo': 'Cerdo',
      'jamon': 'Jamón',
      
      // Frutas y verduras
      'platano': 'Plátano',
      'manzana': 'Manzana',
      'tomate': 'Tomate',
      'lechuga': 'Lechuga',
      'patata': 'Patata',
      
      // Productos envasados
      'conserva': 'Conserva',
      'pasta': 'Pasta',
      'arroz': 'Arroz',
      'aceite': 'Aceite',
      'vinagre': 'Vinagre',
      
      // Bebidas
      'agua': 'Agua',
      'zumo': 'Zumo',
      'refresco': 'Refresco',
      'cerveza': 'Cerveza',
      'vino': 'Vino',
      
      // Limpieza
      'detergente': 'Detergente',
      'suavizante': 'Suavizante',
      'lejia': 'Lejía',
      
      // Higiene
      'champu': 'Champú',
      'gel': 'Gel de Baño',
      'pasta dientes': 'Pasta de Dientes',
    };
    
    final lowerImproved = improved.toLowerCase();
    for (final entry in improvements.entries) {
      if (lowerImproved.contains(entry.key)) {
        // Reemplazar manteniendo el contexto
        improved = improved.replaceAllMapped(
          RegExp(entry.key, caseSensitive: false),
          (match) => entry.value,
        );
        break;
      }
    }
    
    // Limpiar marcas y códigos específicos de supermercados
    improved = improved.replaceAll(RegExp(r'\b(MARCA\s+BLANCA|M\.BLANCA|HACENDADO|CARREFOUR)\b', caseSensitive: false), '');
    improved = improved.replaceAll(RegExp(r'\b\d+[GKLM][LG]?\b'), ''); // Pesos y medidas
    improved = improved.trim();
    
    return improved.isNotEmpty ? improved : productName;
  }

  /// Elimina items duplicados
  List<BillItem> _removeDuplicates(List<BillItem> items) {
    final seen = <String>{};
    final unique = <BillItem>[];
    
    for (final item in items) {
      final key = '${item.name.toLowerCase()}_${item.price.toStringAsFixed(2)}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(item);
      }
    }
    
    return unique;
  }

  @override
  bool isHeaderOrFooter(String line) {
    final lower = line.toLowerCase().trim();
    
    // Patrones específicos de supermercados además de los generales
    final supermarketSkipPatterns = [
      'mercadona', 'carrefour', 'alcampo', 'lidl', 'dia', 'eroski',
      'hipermercado', 'supermercado', 'establecimiento',
      'total articulos', 'num articulos', 'vendidos',
      'ahorro', 'descuento', 'oferta', 'promocion',
      'tarjeta cliente', 'puntos', 'saldo',
      'bolsa', 'bolsas', 'kg', 'unidades', 'uds',
    ];
    
    return super.isHeaderOrFooter(line) || 
           supermarketSkipPatterns.any((pattern) => lower.contains(pattern));
  }
}
