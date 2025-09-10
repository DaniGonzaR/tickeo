import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/parsers/base_parser.dart';
import 'package:tickeo/services/ticket_classifier.dart';

/// Parser especializado para tickets de restaurantes y bares
class RestaurantParser extends BaseParser {
  @override
  TicketType get supportedType => TicketType.restaurant;

  @override
  Future<List<BillItem>> parseTicket(
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
  ) async {
    print('🍽️ PARSEANDO TICKET DE RESTAURANTE...');

    final text = ocrResult.consensusText;
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    print('📄 Procesando ${lines.length} líneas...');

    final items = <BillItem>[];

    // Estrategia 1: Parsing específico para restaurantes
    items.addAll(await _parseRestaurantFormat(lines));

    // Estrategia 2: Si no encontramos suficientes items, usar parsing genérico
    if (items.length < 2) {
      print('⚠️ Pocos items encontrados, aplicando parsing alternativo...');
      items.addAll(await _parseAlternativeFormat(lines));
    }

    // Estrategia 3: Parsing agresivo si aún no tenemos suficientes items
    if (items.isEmpty) {
      print('⚠️ Sin items, aplicando parsing agresivo...');
      items.addAll(await defaultParsing(lines));
    }

    print('✅ PARSING RESTAURANTE COMPLETADO: ${items.length} items');
    return _removeDuplicates(items);
  }

  /// Parsing específico para formato de restaurante
  Future<List<BillItem>> _parseRestaurantFormat(List<String> lines) async {
    final items = <BillItem>[];

    // Productos típicos de restaurante con sus variaciones
    final restaurantProducts = {
      'cerveza': ['cerveza', 'beer', 'caña', 'pinta', 'tercio'],
      'vino': ['vino', 'copa vino', 'tinto', 'blanco', 'rosado'],
      'agua': ['agua', 'agua mineral', 'font vella', 'bezoya'],
      'refresco': ['coca cola', 'pepsi', 'fanta', 'sprite', 'nestea'],
      'cafe': ['cafe', 'cortado', 'americano', 'cappuccino', 'latte'],
      'tapa': ['tapa', 'pincho', 'montadito', 'ración'],
      'bocadillo': ['bocadillo', 'sandwich', 'panini'],
      'ensalada': ['ensalada', 'salad'],
      'sopa': ['sopa', 'crema', 'gazpacho'],
      'carne': ['pollo', 'ternera', 'cerdo', 'cordero', 'hamburguesa'],
      'pescado': ['pescado', 'salmon', 'merluza', 'bacalao', 'atun'],
      'pasta': ['pasta', 'espagueti', 'macarrones', 'lasaña'],
      'pizza': ['pizza', 'margherita', 'carbonara', 'hawaiana'],
      'postre': ['postre', 'flan', 'tarta', 'helado', 'fruta'],
    };

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();

      if (isHeaderOrFooter(line)) continue;

      // Buscar productos conocidos de restaurante
      for (final category in restaurantProducts.entries) {
        for (final product in category.value) {
          if (line.contains(product)) {
            final prices = extractPricesFromLine(lines[i]);
            if (prices.isNotEmpty) {
              final cleanName =
                  _identifyRestaurantProduct(lines[i], category.key);
              items.add(createBillItem(cleanName, prices.first));
              break;
            }
          }
        }
      }
    }

    return items;
  }

  /// Parsing alternativo para restaurantes con formato diferente
  Future<List<BillItem>> _parseAlternativeFormat(List<String> lines) async {
    final items = <BillItem>[];

    print(
        '🔍 DEBUG: Analizando ${lines.length} líneas del ticket de restaurante:');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      print('📝 Línea $i: "$line"');

      if (isHeaderOrFooter(line)) {
        print('   ⏭️ Saltando header/footer');
        continue;
      }

      // Patrón A: cantidad + nombre + unit + total ("2 Coca Cola 1,45 2,90")
      final qtyNameUnitTotal = RegExp(
          r'^(\d+)\s+([A-Za-záéíóúñü0-9\./\- ]+?)\s+(\d+[.,]\d{2})\s+(\d+[.,]\d{2})');
      final a = qtyNameUnitTotal.firstMatch(line);
      if (a != null) {
        final quantity = int.tryParse(a.group(1)!) ?? 1;
        String productName = _cleanRestaurantProductName(a.group(2)!.trim());
        final unit = double.tryParse(a.group(3)!.replaceAll(',', '.')) ?? 0.0;
        final total = double.tryParse(a.group(4)!.replaceAll(',', '.')) ?? 0.0;

        final price =
            isValidPrice(unit) ? unit : (quantity > 0 ? total / quantity : 0.0);

        if (isValidPrice(price) && productName.length >= 2) {
          for (int j = 0; j < quantity; j++) {
            items.add(createBillItem(productName, price));
          }
          continue;
        }
      }

      // Patrón B: nombre + qty x unit + total ("Coca Cola 2 x 1,45 2,90")
      final nameQtyxUnitTotal = RegExp(
          r'^([A-Za-záéíóúñü0-9\./\- ]+?)\s+(\d+)\s*[xX*]\s*(\d+[.,]\d{2})\s+(\d+[.,]\d{2})');
      final b = nameQtyxUnitTotal.firstMatch(line);
      if (b != null) {
        String productName = _cleanRestaurantProductName(b.group(1)!.trim());
        final quantity = int.tryParse(b.group(2)!) ?? 1;
        final unit = double.tryParse(b.group(3)!.replaceAll(',', '.')) ?? 0.0;
        final total = double.tryParse(b.group(4)!.replaceAll(',', '.')) ?? 0.0;

        final price =
            isValidPrice(unit) ? unit : (quantity > 0 ? total / quantity : 0.0);

        if (isValidPrice(price) && productName.length >= 2) {
          for (int j = 0; j < quantity; j++) {
            items.add(createBillItem(productName, price));
          }
          continue;
        }
      }

      // Patrón existente: "1    Coca Cola                2,90 €"
      final restaurantPattern = RegExp(
          r'^(\d+)\s+([A-Za-záéíóúñü\s\d\./\-]+?)\s+(\d+[.,]\d{2})\s*€?');
      final restaurantMatch = restaurantPattern.firstMatch(line);

      if (restaurantMatch != null) {
        print(
            '   ✅ RESTAURANT MATCH: "${restaurantMatch.group(1)}" - "${restaurantMatch.group(2)}" - "${restaurantMatch.group(3)}"');
        final quantity = int.tryParse(restaurantMatch.group(1)!) ?? 1;
        String productName = restaurantMatch.group(2)!.trim();
        final priceStr = restaurantMatch.group(3)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;

        // Limpiar nombre del producto
        productName = _cleanRestaurantProductName(productName);

        if (isValidPrice(price) && productName.length >= 3) {
          // Crear items según la cantidad
          for (int j = 0; j < quantity; j++) {
            items.add(createBillItem(productName, price));
          }
          continue;
        }
      }

      // Fallback genérico en la línea actual
      final prices = extractPricesFromLine(line);
      if (prices.isNotEmpty) {
        print('   💰 Precio encontrado: ${prices.first}');
        String productName = line;

        // Remover precios (decimales, miles y enteros con €) y símbolo € del nombre
        productName = productName.replaceAll(
            RegExp(
                r'\d{1,3}(?:[.,]\d{3})+[.,]\d{2}|\d+[.,]\d{2}|\b\d{2,4}\s*€'),
            '');
        productName = productName.replaceAll('€', '');

        productName = _cleanRestaurantProductName(productName);
        if (productName.length >= 2) {
          print('   ✅ Producto extraído: "$productName" - €${prices.first}');
          items.add(createBillItem(productName, prices.first));
        }
      }
    }

    return items;
  }

  /// Limpia nombres de productos de restaurante
  String _cleanRestaurantProductName(String name) {
    String cleaned = name.trim();

    // Remover números al inicio (cantidad)
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*'), '');

    // Remover precios y símbolos
    cleaned = cleaned.replaceAll(RegExp(r'\d+[.,]\d{2}'), '');
    cleaned = cleaned.replaceAll('€', '');
    cleaned = cleaned.replaceAll(RegExp(r'[*]+'), '');

    // Limpiar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalizar primera letra de cada palabra
    return cleaned
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  /// Identifica y mejora el nombre de productos de restaurante
  String _identifyRestaurantProduct(String line, String category) {
    final cleanLine = cleanProductName(line);

    // Mejorar nombres basado en la categoría
    switch (category) {
      case 'cerveza':
        if (cleanLine.toLowerCase().contains('mahou')) return 'Cerveza Mahou';
        if (cleanLine.toLowerCase().contains('estrella')) {
          return 'Cerveza Estrella';
        }
        if (cleanLine.toLowerCase().contains('cruzcampo')) {
          return 'Cerveza Cruzcampo';
        }
        return 'Cerveza';

      case 'vino':
        if (cleanLine.toLowerCase().contains('tinto')) return 'Vino Tinto';
        if (cleanLine.toLowerCase().contains('blanco')) return 'Vino Blanco';
        if (cleanLine.toLowerCase().contains('rosado')) return 'Vino Rosado';
        return 'Copa de Vino';

      case 'refresco':
        if (cleanLine.toLowerCase().contains('coca')) return 'Coca Cola';
        if (cleanLine.toLowerCase().contains('fanta')) return 'Fanta';
        if (cleanLine.toLowerCase().contains('sprite')) return 'Sprite';
        return 'Refresco';

      case 'cafe':
        if (cleanLine.toLowerCase().contains('cortado')) return 'Café Cortado';
        if (cleanLine.toLowerCase().contains('americano')) {
          return 'Café Americano';
        }
        return 'Café';

      default:
        return cleanLine.isNotEmpty ? cleanLine : category.capitalize();
    }
  }

  @override
  bool isHeaderOrFooter(String line) {
    final upperLine = line.toUpperCase();

    // Detectar líneas que son claramente totales o resúmenes
    if (RegExp(r'TOTAL.*\d+[.,]\d{2}').hasMatch(upperLine)) {
      return true;
    }

    // Detectar líneas con formato de total confuso del OCR
    if (RegExp(r'(TOTE|TOT|TSTEL).*€?.*\d+[.,]\d{2}').hasMatch(upperLine)) {
      return true;
    }

    // Detectar líneas de IVA/bases
    if (RegExp(r'\d+%.*BASE.*\d+[.,]\d{2}').hasMatch(upperLine)) {
      return true;
    }

    // Coincidencia de "BAR" solo como palabra completa (evita "Barbacoa", "Barra")
    if (RegExp(r'\bBAR\b').hasMatch(upperLine)) {
      return true;
    }

    // Patrones específicos de restaurantes (sin "BAR" genérico)
    final restaurantPatterns = [
      'TOTAL',
      'SUBTOTAL',
      'IVA',
      'BASE',
      'IMPUESTO',
      'CAMBIO',
      'TARJETA',
      'EFECTIVO',
      'VISA',
      'MASTERCARD',
      'GRACIAS',
      'FACTURA',
      'TICKET',
      'FECHA',
      'HORA',
      'MESA',
      'CAMARERO',
      'RESTAURANTE',
      'CAFETERIA',
      'TERRAZA',
      'ESTABLECIMIENTO',
      'DIRECCION',
      'TELEFONO',
      'CIF',
      'NIF',
      'LOCALIDAD',
      'CUOTA',
      'TSTEL',
      'TOTE',
      'TOT',
      '3ASE',
      'SUOTA',
      'IMPUESTOS INCL',
      'GRACIAS POR SU VISITA'
    ];

    // Usar detección base más patrones específicos
    return super.isHeaderOrFooter(line) ||
        restaurantPatterns.any((pattern) => upperLine.contains(pattern));
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

/// Extensión para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
