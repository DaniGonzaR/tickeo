import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/parsers/base_parser.dart';
import 'package:tickeo/services/ticket_classifier.dart';

/// Parser genérico para tickets de tipo desconocido o fallback
class GenericParser extends BaseParser {
  @override
  TicketType get supportedType => TicketType.unknown;

  @override
  Future<List<BillItem>> parseTicket(
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
  ) async {
    print('🔧 PARSEANDO TICKET GENÉRICO...');
    
    final text = ocrResult.consensusText;
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    print('📄 Procesando ${lines.length} líneas con parsing genérico...');
    
    final items = <BillItem>[];
    
    // Estrategia 1: Parsing agresivo - buscar cualquier línea con precio
    items.addAll(await _parseAggressively(lines));
    
    // Estrategia 2: Parsing por patrones comunes
    if (items.length < 2) {
      print('⚠️ Aplicando patrones comunes...');
      items.addAll(await _parseCommonPatterns(lines));
    }
    
    // Estrategia 3: Parsing de emergencia - extraer todo lo posible
    if (items.isEmpty) {
      print('⚠️ Parsing de emergencia...');
      items.addAll(await _emergencyParsing(lines));
    }
    
    print('✅ PARSING GENÉRICO COMPLETADO: ${items.length} items');
    return _removeDuplicates(items);
  }

  /// Parsing agresivo que busca cualquier línea con precio válido
  Future<List<BillItem>> _parseAggressively(List<String> lines) async {
    final items = <BillItem>[];
    
    for (final line in lines) {
      if (isHeaderOrFooter(line)) continue;
      
      final prices = extractPricesFromLine(line);
      if (prices.isNotEmpty) {
        // Extraer nombre del producto
        String productName = line;
        for (final price in prices) {
          productName = productName.replaceAll(price.toString(), '');
          productName = productName.replaceAll(price.toStringAsFixed(2), '');
        }
        
        productName = cleanProductName(productName);
        
        // Validar que el nombre tenga sentido
        if (productName.length >= 2 && _isValidProductName(productName)) {
          items.add(createBillItem(productName, prices.first));
        }
      }
    }
    
    return items;
  }

  /// Parsing usando patrones comunes en tickets españoles
  Future<List<BillItem>> _parseCommonPatterns(List<String> lines) async {
    final items = <BillItem>[];
    
    // Patrones comunes en tickets españoles
    final patterns = [
      // Patrón: CANTIDAD PRODUCTO PRECIO
      RegExp(r'^(\d+)\s+([A-Za-záéíóúñü\s]+?)\s+(\d+[.,]\d{2})'),
      
      // Patrón: PRODUCTO .... PRECIO
      RegExp(r'^([A-Za-záéíóúñü\s]+?)\s*[.]{2,}\s*(\d+[.,]\d{2})'),
      
      // Patrón: PRODUCTO PRECIO (espacios múltiples)
      RegExp(r'^([A-Za-záéíóúñü\s]+?)\s{3,}(\d+[.,]\d{2})'),
      
      // Patrón: PRODUCTO * PRECIO
      RegExp(r'^([A-Za-záéíóúñü\s]+?)\s*\*\s*(\d+[.,]\d{2})'),
    ];
    
    for (final line in lines) {
      if (isHeaderOrFooter(line)) continue;
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          String productName;
          String priceStr;
          
          if (match.groupCount >= 3) {
            // Patrón con cantidad
            productName = match.group(2)!.trim();
            priceStr = match.group(3)!.replaceAll(',', '.');
          } else {
            // Patrón simple
            productName = match.group(1)!.trim();
            priceStr = match.group(2)!.replaceAll(',', '.');
          }
          
          final price = double.tryParse(priceStr) ?? 0.0;
          
          if (_isReasonablePrice(price) && _isValidProductName(productName)) {
            items.add(createBillItem(productName, price));
            break; // Solo usar el primer patrón que coincida
          }
        }
      }
    }
    
    return items;
  }

  /// Parsing de emergencia cuando todo lo demás falla
  Future<List<BillItem>> _emergencyParsing(List<String> lines) async {
    final items = <BillItem>[];
    
    print('🚨 Aplicando parsing de emergencia...');
    
    // Extraer todos los precios del texto
    final allPrices = <double>[];
    final priceLines = <int, List<double>>{};
    
    for (int i = 0; i < lines.length; i++) {
      final prices = extractPricesFromLine(lines[i]);
      if (prices.isNotEmpty) {
        allPrices.addAll(prices);
        priceLines[i] = prices;
      }
    }
    
    if (allPrices.isEmpty) {
      print('❌ No se encontraron precios válidos');
      return items;
    }
    
    print('💰 Encontrados ${allPrices.length} precios: ${allPrices.map((p) => '€${p.toStringAsFixed(2)}').join(', ')}');
    
    // Buscar líneas que podrían ser productos cerca de los precios
    for (final entry in priceLines.entries) {
      final lineIndex = entry.key;
      final prices = entry.value;
      
      // Buscar nombres de productos en líneas cercanas
      for (int offset = -2; offset <= 2; offset++) {
        final targetIndex = lineIndex + offset;
        if (targetIndex >= 0 && targetIndex < lines.length) {
          final candidateLine = lines[targetIndex];
          
          if (!isHeaderOrFooter(candidateLine) && 
              extractPricesFromLine(candidateLine).isEmpty && // No debe tener precios
              _isValidProductName(candidateLine)) {
            
            final cleanName = cleanProductName(candidateLine);
            if (cleanName.length >= 2) {
              items.add(createBillItem(cleanName, prices.first));
              break;
            }
          }
        }
      }
    }
    
    // Si aún no tenemos items, crear productos genéricos
    if (items.isEmpty && allPrices.isNotEmpty) {
      print('🔄 Creando productos genéricos...');
      for (int i = 0; i < allPrices.length && i < 10; i++) {
        items.add(createBillItem('Producto ${i + 1}', allPrices[i]));
      }
    }
    
    return items;
  }

  /// Valida si un nombre de producto es válido
  bool _isValidProductName(String name) {
    final trimmed = name.trim();
    
    // Debe tener al menos 2 caracteres
    if (trimmed.length < 2) return false;
    
    // No debe ser solo números o símbolos
    if (RegExp(r'^[\d\s.,€*\-_]+$').hasMatch(trimmed)) return false;
    
    // Debe contener al menos una letra
    if (!RegExp(r'[a-zA-ZáéíóúñüÁÉÍÓÚÑÜ]').hasMatch(trimmed)) return false;
    
    // No debe ser una palabra de control común
    final controlWords = [
      'total', 'subtotal', 'iva', 'base', 'cuota', 'importe',
      'fecha', 'hora', 'caja', 'operador', 'tarjeta', 'efectivo',
      'cambio', 'gracias', 'visita', 'cliente', 'numero'
    ];
    
    final lowerName = trimmed.toLowerCase();
    if (controlWords.any((word) => lowerName == word || lowerName.contains(word))) {
      return false;
    }
    
    return true;
  }

  /// Valida si un precio es razonable (rango muy amplio para genérico)
  bool _isReasonablePrice(double price) {
    return price >= 0.05 && price <= 2000.0; // Rango muy amplio
  }

  @override
  bool isValidPrice(double price) {
    return _isReasonablePrice(price);
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
}
