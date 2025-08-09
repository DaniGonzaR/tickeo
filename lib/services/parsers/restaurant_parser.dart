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
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
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
              final cleanName = _identifyRestaurantProduct(lines[i], category.key);
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
    
    // Buscar patrones típicos: cantidad + producto + precio
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (isHeaderOrFooter(line)) continue;
      
      // Patrón: "2 CERVEZA MAHOU 5,00"
      final quantityPattern = RegExp(r'^(\d+)\s+([A-Za-záéíóúñü\s]+?)\s+(\d+[.,]\d{2})');
      final match = quantityPattern.firstMatch(line);
      
      if (match != null) {
        final quantity = int.tryParse(match.group(1)!) ?? 1;
        final productName = match.group(2)!.trim();
        final priceStr = match.group(3)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (isValidPrice(price) && productName.length >= 3) {
          // Si hay cantidad > 1, crear items individuales
          for (int j = 0; j < quantity; j++) {
            items.add(createBillItem(productName, price / quantity));
          }
        }
      } else {
        // Patrón simple: producto seguido de precio
        final prices = extractPricesFromLine(line);
        if (prices.isNotEmpty) {
          String productName = line;
          for (final price in prices) {
            productName = productName.replaceAll(price.toString(), '');
            productName = productName.replaceAll(price.toStringAsFixed(2), '');
          }
          
          productName = cleanProductName(productName);
          if (productName.length >= 2) {
            items.add(createBillItem(productName, prices.first));
          }
        }
      }
    }
    
    return items;
  }

  /// Identifica y mejora el nombre de productos de restaurante
  String _identifyRestaurantProduct(String line, String category) {
    final cleanLine = cleanProductName(line);
    
    // Mejorar nombres basado en la categoría
    switch (category) {
      case 'cerveza':
        if (cleanLine.toLowerCase().contains('mahou')) return 'Cerveza Mahou';
        if (cleanLine.toLowerCase().contains('estrella')) return 'Cerveza Estrella';
        if (cleanLine.toLowerCase().contains('cruzcampo')) return 'Cerveza Cruzcampo';
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
        if (cleanLine.toLowerCase().contains('americano')) return 'Café Americano';
        return 'Café';
        
      default:
        return cleanLine.isNotEmpty ? cleanLine : category.capitalize();
    }
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
