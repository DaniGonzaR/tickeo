import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/services/universal_ocr_service.dart';
import 'package:tickeo/services/ticket_classifier.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';

void main() {
  group('Universal OCR Service Tests', () {
    late UniversalOCRService ocrService;

    setUp(() {
      ocrService = UniversalOCRService();
      ocrService.initialize();
    });

    tearDown(() {
      ocrService.dispose();
    });

    test('should initialize correctly', () {
      expect(ocrService.getProcessingStats()['isInitialized'], isTrue);
      expect(ocrService.getProcessingStats()['availableParsers'], isNotEmpty);
    });

    test('should have all ticket type parsers', () {
      final stats = ocrService.getProcessingStats();
      final parsers = stats['availableParsers'] as List<String>;
      
      expect(parsers, contains('Restaurante/Bar'));
      expect(parsers, contains('Supermercado'));
      expect(parsers, contains('Desconocido'));
    });

    test('should support all Spanish ticket types', () {
      final stats = ocrService.getProcessingStats();
      final supportedTypes = stats['supportedTicketTypes'] as List<String>;
      
      expect(supportedTypes, contains('Restaurante/Bar'));
      expect(supportedTypes, contains('Supermercado'));
      expect(supportedTypes, contains('Farmacia'));
      expect(supportedTypes, contains('Gasolinera'));
    });
  });

  group('Ticket Classifier Tests', () {
    late TicketClassifier classifier;

    setUp(() {
      classifier = TicketClassifier();
    });

    test('should classify restaurant ticket correctly', () async {
      final mockOCRResult = MultiEngineOCRResult(
        individualResults: [
          OCRResult(
            extractedText: 'RESTAURANTE LA TERRAZA\nCERVEZA MAHOU 2.50\nPATATAS BRAVAS 4.00\nTOTAL 6.50',
            confidence: 0.8,
            engine: 'test',
          ),
        ],
        bestResult: OCRResult(
          extractedText: 'RESTAURANTE LA TERRAZA\nCERVEZA MAHOU 2.50\nPATATAS BRAVAS 4.00\nTOTAL 6.50',
          confidence: 0.8,
          engine: 'test',
        ),
        consensusText: 'RESTAURANTE LA TERRAZA\nCERVEZA MAHOU 2.50\nPATATAS BRAVAS 4.00\nTOTAL 6.50',
        overallConfidence: 0.8,
      );

      final result = await classifier.classifyTicket(mockOCRResult);
      
      expect(result.ticketType, equals(TicketType.restaurant));
      expect(result.confidence, greaterThan(0.5));
      expect(result.detectedFeatures, isNotEmpty);
    });

    test('should classify supermarket ticket correctly', () async {
      final mockOCRResult = MultiEngineOCRResult(
        individualResults: [
          OCRResult(
            extractedText: 'MERCADONA S.A.\nLECHE PASCUAL 1L 1.25\nPAN BIMBO 2.10\nYOGUR DANONE 3.50\nTOTAL 6.85',
            confidence: 0.8,
            engine: 'test',
          ),
        ],
        bestResult: OCRResult(
          extractedText: 'MERCADONA S.A.\nLECHE PASCUAL 1L 1.25\nPAN BIMBO 2.10\nYOGUR DANONE 3.50\nTOTAL 6.85',
          confidence: 0.8,
          engine: 'test',
        ),
        consensusText: 'MERCADONA S.A.\nLECHE PASCUAL 1L 1.25\nPAN BIMBO 2.10\nYOGUR DANONE 3.50\nTOTAL 6.85',
        overallConfidence: 0.8,
      );

      final result = await classifier.classifyTicket(mockOCRResult);
      
      expect(result.ticketType, equals(TicketType.supermarket));
      expect(result.confidence, greaterThan(0.5));
    });
  });

  group('Ticket Types Tests', () {
    test('should have correct price ranges', () {
      expect(TicketType.restaurant.typicalPriceRange.min, equals(1.0));
      expect(TicketType.restaurant.typicalPriceRange.max, equals(150.0));
      
      expect(TicketType.supermarket.typicalPriceRange.min, equals(0.10));
      expect(TicketType.supermarket.typicalPriceRange.max, equals(500.0));
    });

    test('should validate prices correctly', () {
      final restaurantRange = TicketType.restaurant.typicalPriceRange;
      
      expect(restaurantRange.isValidPrice(5.0), isTrue);
      expect(restaurantRange.isValidPrice(0.5), isFalse);
      expect(restaurantRange.isValidPrice(200.0), isFalse);
    });

    test('should have keyword patterns', () {
      expect(TicketType.restaurant.keywordPatterns, contains('cerveza'));
      expect(TicketType.restaurant.keywordPatterns, contains('restaurante'));
      
      expect(TicketType.supermarket.keywordPatterns, contains('mercadona'));
      expect(TicketType.supermarket.keywordPatterns, contains('supermercado'));
    });
  });

  group('OCR Models Tests', () {
    test('should create OCRResult correctly', () {
      final result = OCRResult(
        extractedText: 'Test text',
        confidence: 0.8,
        engine: 'test_engine',
        metadata: {'test': 'data'},
      );

      expect(result.extractedText, equals('Test text'));
      expect(result.confidence, equals(0.8));
      expect(result.engine, equals('test_engine'));
      expect(result.metadata['test'], equals('data'));
    });

    test('should serialize OCRResult to JSON', () {
      final result = OCRResult(
        extractedText: 'Test text',
        confidence: 0.8,
        engine: 'test_engine',
      );

      final json = result.toJson();
      final restored = OCRResult.fromJson(json);

      expect(restored.extractedText, equals(result.extractedText));
      expect(restored.confidence, equals(result.confidence));
      expect(restored.engine, equals(result.engine));
    });

    test('should create TicketData correctly', () {
      final ticketData = TicketData(
        items: [],
        ticketType: TicketType.restaurant,
        confidence: 0.8,
        originalText: 'Original text',
        needsReview: false,
        warnings: ['Warning 1'],
      );

      expect(ticketData.ticketType, equals(TicketType.restaurant));
      expect(ticketData.confidence, equals(0.8));
      expect(ticketData.needsReview, isFalse);
      expect(ticketData.warnings, contains('Warning 1'));
    });
  });
}
