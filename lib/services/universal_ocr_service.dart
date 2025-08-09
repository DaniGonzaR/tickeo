
import 'package:flutter/foundation.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/image_preprocessor.dart';
import 'package:tickeo/services/multi_engine_ocr.dart';
import 'package:tickeo/services/ticket_classifier.dart';
import 'package:tickeo/services/intelligent_extractor.dart';
import 'package:tickeo/services/parsers/base_parser.dart';
import 'package:tickeo/services/parsers/restaurant_parser.dart';
import 'package:tickeo/services/parsers/supermarket_parser.dart';
import 'package:tickeo/services/parsers/generic_parser.dart';

/// Servicio OCR universal que maneja todos los tipos de tickets españoles
class UniversalOCRService {
  static final UniversalOCRService _instance = UniversalOCRService._internal();
  factory UniversalOCRService() => _instance;
  UniversalOCRService._internal();

  // Componentes del sistema
  final ImagePreprocessor _preprocessor = ImagePreprocessor();
  final MultiEngineOCR _ocrEngine = MultiEngineOCR();
  final TicketClassifier _classifier = TicketClassifier();
  final IntelligentExtractor _extractor = IntelligentExtractor();
  
  // Parsers especializados
  late final Map<TicketType, BaseParser> _parsers;
  
  bool _isInitialized = false;

  /// Inicializa el servicio OCR universal
  void initialize() {
    if (_isInitialized) return;
    
    print('🚀 INICIALIZANDO UNIVERSAL OCR SERVICE...');
    
    // Inicializar componentes
    _ocrEngine.initialize();
    
    // Configurar parsers especializados
    _parsers = {
      TicketType.restaurant: RestaurantParser(),
      TicketType.supermarket: SupermarketParser(),
      TicketType.pharmacy: GenericParser(), // Usar genérico por ahora
      TicketType.gasStation: GenericParser(),
      TicketType.clothing: GenericParser(),
      TicketType.electronics: GenericParser(),
      TicketType.bakery: RestaurantParser(), // Similar a restaurante
      TicketType.unknown: GenericParser(),
    };
    
    _isInitialized = true;
    print('✅ Universal OCR Service inicializado');
  }

  /// Procesa una imagen de ticket y extrae todos los datos
  Future<TicketData> processTicket(dynamic imageFile, {OCRConfig? config}) async {
    if (!_isInitialized) {
      initialize();
    }
    
    print('🎯 PROCESANDO TICKET CON UNIVERSAL OCR...');
    print('📱 Plataforma: ${kIsWeb ? 'Web' : 'Móvil'}');
    
    try {
      // FASE 1: Preprocesamiento de imagen
      print('\n📸 FASE 1: PREPROCESAMIENTO DE IMAGEN');
      final processedImage = await _preprocessor.enhanceForOCR(imageFile);
      
      if (processedImage.hasError) {
        print('⚠️ Error en preprocesamiento: ${processedImage.error}');
      } else {
        print('✅ Imagen preprocesada: ${processedImage.improvements.join(', ')}');
      }

      // FASE 2: Extracción OCR multi-engine
      print('\n🔍 FASE 2: EXTRACCIÓN OCR MULTI-ENGINE');
      final ocrResult = await _ocrEngine.extractText(processedImage);
      
      print('📝 Texto extraído (${ocrResult.consensusText.length} caracteres)');
      print('🎯 Confianza OCR: ${ocrResult.overallConfidence.toStringAsFixed(2)}');
      print('🔧 Engines usados: ${ocrResult.individualResults.map((r) => r.engine).join(', ')}');

      // FASE 3: Clasificación de tipo de ticket
      print('\n🏷️ FASE 3: CLASIFICACIÓN DE TICKET');
      final classification = await _classifier.classifyTicket(ocrResult);
      
      print('📋 Tipo detectado: ${classification.ticketType.displayName}');
      print('🎯 Confianza clasificación: ${classification.confidence.toStringAsFixed(2)}');
      print('🔍 Características: ${classification.detectedFeatures.join(', ')}');

      // FASE 4: Parsing adaptativo
      print('\n⚙️ FASE 4: PARSING ADAPTATIVO');
      final parser = _parsers[classification.ticketType] ?? _parsers[TicketType.unknown]!;
      final rawItems = await parser.parseTicket(ocrResult, classification);
      
      print('📦 Items extraídos: ${rawItems.length}');
      for (final item in rawItems) {
        print('  - ${item.name}: €${item.price.toStringAsFixed(2)}');
      }

      // FASE 5: Mejora inteligente
      print('\n🧠 FASE 5: MEJORA INTELIGENTE');
      final enhancedItems = await _extractor.enhanceItems(rawItems, ocrResult, classification);
      
      print('✨ Items mejorados: ${enhancedItems.length}');
      for (final item in enhancedItems) {
        print('  - ${item.name}: €${item.price.toStringAsFixed(2)}');
      }

      // FASE 6: Generar resultado final
      print('\n📊 FASE 6: RESULTADO FINAL');
      final finalConfidence = _calculateFinalConfidence(ocrResult, classification, enhancedItems);
      final needsReview = _shouldNeedReview(finalConfidence, enhancedItems, classification);
      final warnings = _generateWarnings(ocrResult, classification, enhancedItems);

      final ticketData = TicketData(
        items: enhancedItems,
        ticketType: classification.ticketType,
        confidence: finalConfidence,
        originalText: ocrResult.consensusText,
        needsReview: needsReview,
        warnings: warnings,
        metadata: {
          'ocrEngines': ocrResult.individualResults.map((r) => r.engine).toList(),
          'ocrConfidence': ocrResult.overallConfidence,
          'classificationConfidence': classification.confidence,
          'detectedFeatures': classification.detectedFeatures,
          'imageImprovements': processedImage.improvements,
          'processingTime': DateTime.now().millisecondsSinceEpoch,
        },
      );

      print('🎉 PROCESAMIENTO COMPLETADO');
      print('📈 Confianza final: ${finalConfidence.toStringAsFixed(2)}');
      print('🔍 Requiere revisión: ${needsReview ? 'SÍ' : 'NO'}');
      print('⚠️ Advertencias: ${warnings.length}');
      
      return ticketData;

    } catch (e, stackTrace) {
      print('❌ ERROR EN PROCESAMIENTO: $e');
      print('📍 Stack trace: $stackTrace');
      
      return TicketData(
        items: [],
        ticketType: TicketType.unknown,
        confidence: 0.0,
        originalText: '',
        needsReview: true,
        warnings: ['Error en procesamiento: $e'],
        metadata: {
          'error': e.toString(),
          'processingTime': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
  }

  /// Calcula la confianza final del procesamiento
  double _calculateFinalConfidence(
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
    List<BillItem> items,
  ) {
    double confidence = 0.0;
    
    // 30% basado en confianza OCR
    confidence += ocrResult.overallConfidence * 0.3;
    
    // 25% basado en confianza de clasificación
    confidence += classification.confidence * 0.25;
    
    // 25% basado en cantidad de items extraídos
    final itemsScore = (items.length / 10.0).clamp(0.0, 1.0); // Máximo 10 items = 100%
    confidence += itemsScore * 0.25;
    
    // 20% basado en validez de los items
    final validItemsRatio = items.isEmpty ? 0.0 : 1.0; // Si hay items, son válidos
    confidence += validItemsRatio * 0.20;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Determina si el resultado necesita revisión manual
  bool _shouldNeedReview(
    double confidence,
    List<BillItem> items,
    TicketClassificationResult classification,
  ) {
    // Necesita revisión si:
    
    // 1. Confianza muy baja
    if (confidence < 0.5) return true;
    
    // 2. No se encontraron items
    if (items.isEmpty) return true;
    
    // 3. Solo se encontró 1 item (sospechoso)
    if (items.length == 1 && confidence < 0.8) return true;
    
    // 4. Clasificación incierta
    if (classification.isUncertain) return true;
    
    // 5. Precios sospechosos (todos muy altos o muy bajos)
    if (items.isNotEmpty) {
      final avgPrice = items.map((i) => i.price).reduce((a, b) => a + b) / items.length;
      if (avgPrice < 0.5 || avgPrice > 100.0) return true;
    }
    
    return false;
  }

  /// Genera advertencias sobre el procesamiento
  List<String> _generateWarnings(
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
    List<BillItem> items,
  ) {
    final warnings = <String>[];
    
    // Advertencias sobre OCR
    if (ocrResult.overallConfidence < 0.7) {
      warnings.add('Calidad de imagen baja - considera tomar otra foto');
    }
    
    if (ocrResult.individualResults.length == 1) {
      warnings.add('Solo un motor OCR funcionó - precisión puede ser limitada');
    }
    
    // Advertencias sobre clasificación
    if (classification.isUncertain) {
      warnings.add('Tipo de ticket incierto - verifica los productos');
    }
    
    // Advertencias sobre items
    if (items.isEmpty) {
      warnings.add('No se encontraron productos - introduce manualmente');
    } else if (items.length == 1) {
      warnings.add('Solo se encontró un producto - puede haber más');
    }
    
    // Advertencias sobre precios
    if (items.isNotEmpty) {
      final prices = items.map((i) => i.price).toList();
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      
      if (maxPrice > 200.0) {
        warnings.add('Precio muy alto detectado - verifica €${maxPrice.toStringAsFixed(2)}');
      }
      
      if (minPrice < 0.10) {
        warnings.add('Precio muy bajo detectado - verifica €${minPrice.toStringAsFixed(2)}');
      }
    }
    
    return warnings;
  }

  /// Obtiene estadísticas del procesamiento
  Map<String, dynamic> getProcessingStats() {
    return {
      'isInitialized': _isInitialized,
      'availableParsers': _parsers.keys.map((t) => t.displayName).toList(),
      'supportedTicketTypes': TicketType.values.map((t) => t.displayName).toList(),
      'platform': kIsWeb ? 'web' : 'mobile',
    };
  }

  /// Libera recursos
  void dispose() {
    print('🧹 Liberando recursos de Universal OCR Service...');
    _ocrEngine.dispose();
    _isInitialized = false;
  }

  /// Método de compatibilidad con el OCRService anterior
  Future<Map<String, dynamic>> processReceiptImage(dynamic imageFile) async {
    final result = await processTicket(imageFile);
    
    // Convertir a formato compatible
    return {
      'success': result.items.isNotEmpty,
      'items': result.items,
      'confidence': result.confidence,
      'needsReview': result.needsReview,
      'extractedText': result.originalText,
      'ticketType': result.ticketType.displayName,
      'warnings': result.warnings,
      'metadata': result.metadata,
    };
  }
}
