import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';

/// Clasificador inteligente que determina el tipo de ticket basado en el contenido
class TicketClassifier {
  static final TicketClassifier _instance = TicketClassifier._internal();
  factory TicketClassifier() => _instance;
  TicketClassifier._internal();

  /// Clasifica un ticket basado en el texto extraído por OCR
  Future<TicketClassificationResult> classifyTicket(MultiEngineOCRResult ocrResult) async {
    print('🏷️ CLASIFICANDO TIPO DE TICKET...');
    
    final text = ocrResult.consensusText.toLowerCase();
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    print('📄 Analizando ${lines.length} líneas de texto...');
    
    // Calcular scores para cada tipo de ticket
    final scores = <TicketType, double>{};
    
    for (final ticketType in TicketType.values) {
      if (ticketType == TicketType.unknown) continue;
      
      final score = _calculateTypeScore(text, lines, ticketType);
      scores[ticketType] = score;
      
      print('  ${ticketType.displayName}: ${score.toStringAsFixed(2)}');
    }
    
    // Encontrar el tipo con mayor score
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final bestMatch = sortedScores.first;
    final confidence = bestMatch.value;
    
    // Si la confianza es muy baja, marcar como desconocido
    final finalType = confidence < 0.3 ? TicketType.unknown : bestMatch.key;
    final finalConfidence = confidence < 0.3 ? 0.0 : confidence;
    
    print('✅ CLASIFICACIÓN COMPLETADA');
    print('🎯 Tipo detectado: ${finalType.displayName}');
    print('📊 Confianza: ${finalConfidence.toStringAsFixed(2)}');
    
    return TicketClassificationResult(
      ticketType: finalType,
      confidence: finalConfidence,
      allScores: scores,
      detectedFeatures: _extractFeatures(text, lines, finalType),
    );
  }

  /// Calcula el score de probabilidad para un tipo específico de ticket
  double _calculateTypeScore(String text, List<String> lines, TicketType ticketType) {
    double score = 0.0;
    
    // 1. Score basado en palabras clave específicas
    score += _calculateKeywordScore(text, ticketType);
    
    // 2. Score basado en patrones de precios
    score += _calculatePricePatternScore(text, ticketType);
    
    // 3. Score basado en estructura del ticket
    score += _calculateStructureScore(lines, ticketType);
    
    // 4. Score basado en marcas/nombres conocidos
    score += _calculateBrandScore(text, ticketType);
    
    // 5. Score basado en patrones de formato
    score += _calculateFormatScore(text, lines, ticketType);
    
    return score.clamp(0.0, 1.0);
  }

  /// Calcula score basado en palabras clave
  double _calculateKeywordScore(String text, TicketType ticketType) {
    final keywords = ticketType.keywordPatterns;
    int matches = 0;
    
    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        matches++;
      }
    }
    
    // Score proporcional a las coincidencias
    return (matches / keywords.length) * 0.4; // Máximo 0.4 puntos
  }

  /// Calcula score basado en patrones de precios
  double _calculatePricePatternScore(String text, TicketType ticketType) {
    final priceMatches = RegExp(r'\d+[.,]\d{2}').allMatches(text);
    final prices = priceMatches.map((match) {
      final priceStr = match.group(0)!.replaceAll(',', '.');
      return double.tryParse(priceStr) ?? 0.0;
    }).where((price) => price > 0).toList();
    
    if (prices.isEmpty) return 0.0;
    
    final priceRange = ticketType.typicalPriceRange;
    int validPrices = 0;
    
    for (final price in prices) {
      if (priceRange.isValidPrice(price)) {
        validPrices++;
      }
    }
    
    return (validPrices / prices.length) * 0.3; // Máximo 0.3 puntos
  }

  /// Calcula score basado en estructura del ticket
  double _calculateStructureScore(List<String> lines, TicketType ticketType) {
    double score = 0.0;
    
    switch (ticketType) {
      case TicketType.restaurant:
        // Restaurantes suelen tener menos líneas, más informales
        if (lines.length >= 5 && lines.length <= 25) score += 0.1;
        // Buscar patrones de mesa, camarero
        if (lines.any((line) => line.contains('mesa') || line.contains('camarero'))) {
          score += 0.1;
        }
        break;
        
      case TicketType.supermarket:
        // Supermercados suelen tener muchas líneas, muy estructurados
        if (lines.length > 15) score += 0.1;
        // Buscar códigos de barras o referencias
        if (lines.any((line) => RegExp(r'\d{8,13}').hasMatch(line))) {
          score += 0.1;
        }
        break;
        
      case TicketType.pharmacy:
        // Farmacias suelen tener códigos nacionales, menos productos
        if (lines.length >= 3 && lines.length <= 15) score += 0.1;
        break;
        
      default:
        break;
    }
    
    return score;
  }

  /// Calcula score basado en marcas conocidas
  double _calculateBrandScore(String text, TicketType ticketType) {
    final brandPatterns = _getBrandPatterns(ticketType);
    
    for (final brand in brandPatterns) {
      if (text.contains(brand.toLowerCase())) {
        return 0.2; // Bonus fuerte por marca reconocida
      }
    }
    
    return 0.0;
  }

  /// Obtiene patrones de marcas para cada tipo
  List<String> _getBrandPatterns(TicketType ticketType) {
    switch (ticketType) {
      case TicketType.restaurant:
        return [
          'telepizza', 'mcdonalds', 'burger king', 'kfc', 'dominos',
          'starbucks', 'subway', 'taco bell', 'pizza hut'
        ];
        
      case TicketType.supermarket:
        return [
          'mercadona', 'carrefour', 'alcampo', 'lidl', 'dia',
          'eroski', 'auchan', 'simply', 'hipercor', 'el corte ingles'
        ];
        
      case TicketType.pharmacy:
        return [
          'farmacia', 'botica', 'cruz verde', 'cinfa', 'kern pharma'
        ];
        
      case TicketType.gasStation:
        return [
          'repsol', 'cepsa', 'bp', 'shell', 'galp', 'petronor'
        ];
        
      case TicketType.clothing:
        return [
          'zara', 'h&m', 'mango', 'bershka', 'pull&bear',
          'stradivarius', 'massimo dutti', 'primark'
        ];
        
      case TicketType.electronics:
        return [
          'media markt', 'fnac', 'worten', 'carrefour tech',
          'pc componentes', 'amazon'
        ];
        
      case TicketType.bakery:
        return [
          'panaderia', 'horno', 'bolleria', 'pasteleria'
        ];
        
      default:
        return [];
    }
  }

  /// Calcula score basado en formato del ticket
  double _calculateFormatScore(String text, List<String> lines, TicketType ticketType) {
    double score = 0.0;
    
    // Detectar patrones específicos de formato
    switch (ticketType) {
      case TicketType.supermarket:
        // Supermercados suelen tener totales, subtotales, IVA
        if (text.contains('total') && text.contains('iva')) score += 0.1;
        if (text.contains('subtotal')) score += 0.05;
        break;
        
      case TicketType.restaurant:
        // Restaurantes pueden tener menos estructura fiscal
        if (!text.contains('iva') && text.contains('total')) score += 0.05;
        break;
        
      case TicketType.gasStation:
        // Gasolineras tienen litros y precios por litro
        if (text.contains('litros') || text.contains('l.')) score += 0.1;
        break;
        
      default:
        break;
    }
    
    return score;
  }

  /// Extrae características detectadas del ticket
  List<String> _extractFeatures(String text, List<String> lines, TicketType ticketType) {
    final features = <String>[];
    
    // Características generales
    if (RegExp(r'\d+[.,]\d{2}').hasMatch(text)) {
      features.add('Precios detectados');
    }
    
    if (text.contains('total')) {
      features.add('Total encontrado');
    }
    
    if (text.contains('iva')) {
      features.add('IVA mencionado');
    }
    
    // Características específicas por tipo
    switch (ticketType) {
      case TicketType.restaurant:
        if (text.contains('mesa')) features.add('Número de mesa');
        if (text.contains('camarero')) features.add('Camarero identificado');
        break;
        
      case TicketType.supermarket:
        if (RegExp(r'\d{8,13}').hasMatch(text)) features.add('Códigos de barras');
        if (text.contains('oferta')) features.add('Ofertas detectadas');
        break;
        
      case TicketType.pharmacy:
        if (text.contains('medicamento')) features.add('Medicamentos');
        break;
        
      default:
        break;
    }
    
    return features;
  }
}

/// Resultado de la clasificación de ticket
class TicketClassificationResult {
  final TicketType ticketType;
  final double confidence;
  final Map<TicketType, double> allScores;
  final List<String> detectedFeatures;

  TicketClassificationResult({
    required this.ticketType,
    required this.confidence,
    required this.allScores,
    required this.detectedFeatures,
  });

  bool get isConfident => confidence >= 0.7;
  bool get isUncertain => confidence < 0.5;
}
