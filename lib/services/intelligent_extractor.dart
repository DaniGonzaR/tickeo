import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/ticket_classifier.dart';

/// Extractor inteligente que mejora y valida los resultados del parsing
class IntelligentExtractor {
  static final IntelligentExtractor _instance = IntelligentExtractor._internal();
  factory IntelligentExtractor() => _instance;
  IntelligentExtractor._internal();

  /// Mejora los items extraídos usando inteligencia artificial/ML
  Future<List<BillItem>> enhanceItems(
    List<BillItem> rawItems,
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
  ) async {
    print('🧠 MEJORANDO ITEMS CON IA...');
    
    if (rawItems.isEmpty) {
      print('⚠️ No hay items para mejorar');
      return rawItems;
    }
    
    print('📊 Items originales: ${rawItems.length}');
    
    List<BillItem> enhancedItems = List.from(rawItems);
    
    // 1. Corrección de errores OCR en nombres
    enhancedItems = await _correctOCRErrors(enhancedItems, ocrResult);
    
    // 2. Validación y filtrado inteligente
    enhancedItems = await _intelligentFiltering(enhancedItems, classification);
    
    // 3. Mejora de nombres de productos
    enhancedItems = await _improveProductNames(enhancedItems, classification.ticketType);
    
    // 4. Validación de precios por contexto
    enhancedItems = await _validatePrices(enhancedItems, classification.ticketType);
    
    // 5. Detección y corrección de duplicados inteligente
    enhancedItems = await _smartDuplicateRemoval(enhancedItems);
    
    // 6. Ordenamiento lógico
    enhancedItems = await _logicalSorting(enhancedItems, classification.ticketType);
    
    print('✅ MEJORA COMPLETADA: ${enhancedItems.length} items finales');
    
    return enhancedItems;
  }

  /// Corrige errores comunes de OCR en nombres de productos
  Future<List<BillItem>> _correctOCRErrors(List<BillItem> items, MultiEngineOCRResult ocrResult) async {
    print('🔧 Manteniendo nombres originales del ticket...');
    
    // NO aplicar correcciones - mantener texto original del ticket
    final originalItems = <BillItem>[];
    
    for (final item in items) {
      // Mantener el nombre exactamente como aparece en el ticket
      originalItems.add(BillItem(
        id: item.id,
        name: item.name, // Sin modificaciones
        price: item.price,
        selectedBy: item.selectedBy,
      ));
    }
    
    return originalItems;
  }

  /// Filtrado inteligente basado en contexto
  Future<List<BillItem>> _intelligentFiltering(List<BillItem> items, TicketClassificationResult classification) async {
    print('🎯 Aplicando filtrado inteligente...');
    
    final filteredItems = <BillItem>[];
    
    for (final item in items) {
      // Filtros básicos
      if (item.name.trim().length < 2) continue;
      if (item.price <= 0) continue;
      
      // Filtros específicos por tipo de ticket
      if (!_isValidForTicketType(item, classification.ticketType)) continue;
      
      // Filtro de confianza basado en nombre
      if (!_hasReasonableName(item.name)) continue;
      
      filteredItems.add(item);
    }
    
    print('🔍 Items filtrados: ${items.length} → ${filteredItems.length}');
    return filteredItems;
  }

  /// Mejora nombres de productos usando conocimiento del dominio
  Future<List<BillItem>> _improveProductNames(List<BillItem> items, TicketType ticketType) async {
    print('📝 Mejorando nombres de productos...');
    
    final improvedItems = <BillItem>[];
    
    for (final item in items) {
      String improvedName = _improveNameByType(item.name, ticketType);
      
      improvedItems.add(BillItem(
        id: item.id,
        name: improvedName,
        price: item.price,
        selectedBy: item.selectedBy,
      ));
    }
    
    return improvedItems;
  }

  /// Valida precios según el contexto del ticket
  Future<List<BillItem>> _validatePrices(List<BillItem> items, TicketType ticketType) async {
    print('💰 Validando precios por contexto...');
    
    final priceRange = ticketType.typicalPriceRange;
    final validItems = <BillItem>[];
    
    for (final item in items) {
      if (priceRange.isValidPrice(item.price)) {
        validItems.add(item);
      } else {
        print('⚠️ Precio inválido para ${ticketType.displayName}: ${item.name} - €${item.price.toStringAsFixed(2)}');
      }
    }
    
    return validItems;
  }

  /// Eliminación inteligente de duplicados
  Future<List<BillItem>> _smartDuplicateRemoval(List<BillItem> items) async {
    print('🔄 Eliminando duplicados inteligentemente...');
    
    final uniqueItems = <BillItem>[];
    final seen = <String, BillItem>{};
    
    for (final item in items) {
      // Crear clave normalizada para comparación
      final normalizedName = _normalizeForComparison(item.name);
      final priceKey = item.price.toStringAsFixed(2);
      final key = '${normalizedName}_$priceKey';
      
      if (!seen.containsKey(key)) {
        seen[key] = item;
        uniqueItems.add(item);
      } else {
        // Si encontramos duplicado, mantener el que tenga mejor nombre
        final existing = seen[key]!;
        if (item.name.length > existing.name.length) {
          // Reemplazar con el nombre más descriptivo
          final index = uniqueItems.indexOf(existing);
          if (index >= 0) {
            uniqueItems[index] = item;
            seen[key] = item;
          }
        }
      }
    }
    
    print('🔍 Duplicados eliminados: ${items.length} → ${uniqueItems.length}');
    return uniqueItems;
  }

  /// Ordenamiento lógico de items
  Future<List<BillItem>> _logicalSorting(List<BillItem> items, TicketType ticketType) async {
    print('📋 Ordenando items lógicamente...');
    
    // Ordenar por precio descendente por defecto
    items.sort((a, b) => b.price.compareTo(a.price));
    
    // Ordenamiento específico por tipo
    switch (ticketType) {
      case TicketType.restaurant:
        return _sortRestaurantItems(items);
      case TicketType.supermarket:
        return _sortSupermarketItems(items);
      default:
        return items;
    }
  }

  /// Ordenamiento específico para restaurantes
  List<BillItem> _sortRestaurantItems(List<BillItem> items) {
    // Orden típico: bebidas → platos principales → postres
    final categories = <String, int>{
      'bebida': 1, 'cerveza': 1, 'vino': 1, 'agua': 1, 'refresco': 1,
      'plato': 2, 'carne': 2, 'pescado': 2, 'pasta': 2, 'pizza': 2,
      'postre': 3, 'helado': 3, 'tarta': 3, 'flan': 3,
    };
    
    items.sort((a, b) {
      final categoryA = _getItemCategory(a.name.toLowerCase(), categories);
      final categoryB = _getItemCategory(b.name.toLowerCase(), categories);
      
      if (categoryA != categoryB) {
        return categoryA.compareTo(categoryB);
      }
      
      return b.price.compareTo(a.price); // Por precio si misma categoría
    });
    
    return items;
  }

  /// Ordenamiento específico para supermercados
  List<BillItem> _sortSupermarketItems(List<BillItem> items) {
    // Orden típico: frescos → envasados → limpieza
    final categories = <String, int>{
      'fruta': 1, 'verdura': 1, 'carne': 1, 'pescado': 1,
      'leche': 2, 'yogur': 2, 'queso': 2, 'pan': 2,
      'conserva': 3, 'pasta': 3, 'arroz': 3, 'aceite': 3,
      'detergente': 4, 'limpieza': 4, 'gel': 4,
    };
    
    items.sort((a, b) {
      final categoryA = _getItemCategory(a.name.toLowerCase(), categories);
      final categoryB = _getItemCategory(b.name.toLowerCase(), categories);
      
      if (categoryA != categoryB) {
        return categoryA.compareTo(categoryB);
      }
      
      return a.name.compareTo(b.name); // Alfabético si misma categoría
    });
    
    return items;
  }

  /// Obtiene la categoría de un item
  int _getItemCategory(String itemName, Map<String, int> categories) {
    for (final entry in categories.entries) {
      if (itemName.contains(entry.key)) {
        return entry.value;
      }
    }
    return 999; // Categoría desconocida al final
  }

  /// Capitaliza correctamente en español
  String _capitalizeSpanish(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ')
        .trim();
  }

  /// Valida si un item es válido para el tipo de ticket
  bool _isValidForTicketType(BillItem item, TicketType ticketType) {
    final itemName = item.name.toLowerCase();
    
    // Validaciones específicas por tipo
    switch (ticketType) {
      case TicketType.pharmacy:
        // En farmacias no deberían aparecer bebidas alcohólicas
        if (itemName.contains('cerveza') || itemName.contains('vino')) {
          return false;
        }
        break;
        
      case TicketType.gasStation:
        // En gasolineras, precios muy bajos son sospechosos
        if (item.price < 1.0) return false;
        break;
        
      default:
        break;
    }
    
    return true;
  }

  /// Verifica si un nombre de producto es razonable
  bool _hasReasonableName(String name) {
    final trimmed = name.trim();
    
    // Debe tener contenido significativo
    if (trimmed.length < 2) return false;
    
    // No debe ser solo números o símbolos
    if (RegExp(r'^[\d\s.,€*\-_]+$').hasMatch(trimmed)) return false;
    
    // Debe contener letras
    if (!RegExp(r'[a-zA-ZáéíóúñüÁÉÍÓÚÑÜ]').hasMatch(trimmed)) return false;
    
    return true;
  }

  /// Mejora nombre según el tipo de establecimiento
  String _improveNameByType(String name, TicketType ticketType) {
    String improved = name;
    
    switch (ticketType) {
      case TicketType.restaurant:
        improved = _improveRestaurantName(improved);
        break;
      case TicketType.supermarket:
        improved = _improveSupermarketName(improved);
        break;
      default:
        break;
    }
    
    return improved;
  }

  /// Mejora nombres de restaurante
  String _improveRestaurantName(String name) {
    final improvements = {
      'coca': 'Coca Cola',
      'fanta': 'Fanta',
      'sprite': 'Sprite',
      'cerveza': 'Cerveza',
      'agua': 'Agua',
      'cafe': 'Café',
      'cortado': 'Café Cortado',
    };
    
    String improved = name;
    final lowerName = name.toLowerCase();
    
    for (final entry in improvements.entries) {
      if (lowerName.contains(entry.key)) {
        improved = entry.value;
        break;
      }
    }
    
    return improved;
  }

  /// Mejora nombres de supermercado
  String _improveSupermarketName(String name) {
    // Ya implementado en SupermarketParser, aquí solo refinamos
    return _capitalizeSpanish(name);
  }

  /// Normaliza nombre para comparación de duplicados
  String _normalizeForComparison(String name) {
    return name.toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }
}
