import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';

/// Resultado del OCR con múltiples engines
class OCRResult {
  final String extractedText;
  final double confidence;
  final String engine;
  final Map<String, dynamic> metadata;

  OCRResult({
    required this.extractedText,
    required this.confidence,
    required this.engine,
    this.metadata = const {},
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      extractedText: json['extractedText'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      engine: json['engine'] ?? 'unknown',
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extractedText': extractedText,
      'confidence': confidence,
      'engine': engine,
      'metadata': metadata,
    };
  }
}

/// Resultado consolidado de múltiples engines OCR
class MultiEngineOCRResult {
  final List<OCRResult> individualResults;
  final OCRResult bestResult;
  final String consensusText;
  final double overallConfidence;

  MultiEngineOCRResult({
    required this.individualResults,
    required this.bestResult,
    required this.consensusText,
    required this.overallConfidence,
  });
}

/// Datos procesados del ticket
class TicketData {
  final List<BillItem> items;
  final TicketType ticketType;
  final double confidence;
  final String originalText;
  final Map<String, dynamic> metadata;
  final bool needsReview;
  final List<String> warnings;

  TicketData({
    required this.items,
    required this.ticketType,
    required this.confidence,
    required this.originalText,
    this.metadata = const {},
    this.needsReview = false,
    this.warnings = const [],
  });

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => BillItem.fromJson(item))
          .toList() ?? [],
      ticketType: TicketType.values.firstWhere(
        (type) => type.toString() == json['ticketType'],
        orElse: () => TicketType.unknown,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      originalText: json['originalText'] ?? '',
      metadata: json['metadata'] ?? {},
      needsReview: json['needsReview'] ?? false,
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'ticketType': ticketType.toString(),
      'confidence': confidence,
      'originalText': originalText,
      'metadata': metadata,
      'needsReview': needsReview,
      'warnings': warnings,
    };
  }

  /// Crea una copia con campos modificados
  TicketData copyWith({
    List<BillItem>? items,
    TicketType? ticketType,
    double? confidence,
    String? originalText,
    Map<String, dynamic>? metadata,
    bool? needsReview,
    List<String>? warnings,
  }) {
    return TicketData(
      items: items ?? this.items,
      ticketType: ticketType ?? this.ticketType,
      confidence: confidence ?? this.confidence,
      originalText: originalText ?? this.originalText,
      metadata: metadata ?? this.metadata,
      needsReview: needsReview ?? this.needsReview,
      warnings: warnings ?? this.warnings,
    );
  }
}

/// Configuración para el procesamiento OCR
class OCRConfig {
  final bool enablePreprocessing;
  final bool useMultipleEngines;
  final double minConfidenceThreshold;
  final List<String> preferredEngines;
  final Map<String, dynamic> engineSettings;

  const OCRConfig({
    this.enablePreprocessing = true,
    this.useMultipleEngines = true,
    this.minConfidenceThreshold = 0.7,
    this.preferredEngines = const ['ml_kit', 'ocr_space', 'tesseract'],
    this.engineSettings = const {},
  });

  factory OCRConfig.forTicketType(TicketType ticketType) {
    switch (ticketType) {
      case TicketType.restaurant:
        return const OCRConfig(
          minConfidenceThreshold: 0.6,
          preferredEngines: ['ml_kit', 'ocr_space'],
        );
      case TicketType.supermarket:
        return const OCRConfig(
          minConfidenceThreshold: 0.8,
          preferredEngines: ['ocr_space', 'ml_kit', 'tesseract'],
        );
      default:
        return const OCRConfig();
    }
  }
}
