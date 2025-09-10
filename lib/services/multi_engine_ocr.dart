import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/image_preprocessor.dart';
// Conditional import: web bridge vs stub
import 'package:tickeo/services/tesseract_stub.dart'
    if (dart.library.html) 'package:tickeo/services/tesseract_web.dart';

/// Motor OCR multi-engine que combina varios servicios para máxima precisión
class MultiEngineOCR {
  static final MultiEngineOCR _instance = MultiEngineOCR._internal();
  factory MultiEngineOCR() => _instance;
  MultiEngineOCR._internal();

  TextRecognizer? _textRecognizer;

  /// Inicializar los motores OCR
  void initialize() {
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer();
    }
  }

  /// Extrae texto usando múltiples engines y genera consenso
  Future<MultiEngineOCRResult> extractText(ProcessedImage processedImage) async {
    print('🔍 INICIANDO EXTRACCIÓN MULTI-ENGINE...');
    
    final results = <OCRResult>[];
    
    try {
      // Engine 1: Google ML Kit (móvil)
      if (!kIsWeb && _textRecognizer != null) {
        final mlKitResult = await _extractWithMLKit(processedImage);
        if (mlKitResult != null) {
          results.add(mlKitResult);
        }
      }

      // Engine 2: OCR.space API (web y móvil) con reintento alternativo
      final ocrSpaceResult = await _extractWithOCRSpace(processedImage);
      if (ocrSpaceResult != null) {
        results.add(ocrSpaceResult);
      } else {
        final ocrSpaceRetry = await _extractWithOCRSpace(processedImage, retryAlternate: true);
        if (ocrSpaceRetry != null) results.add(ocrSpaceRetry);
      }

      // Engine 3: Tesseract.js (web fallback)
      if (kIsWeb) {
        final tesseractResult = await _extractWithTesseract(processedImage);
        if (tesseractResult != null) {
          results.add(tesseractResult);
        }
      }

      // Engine 4: Azure Computer Vision (premium, opcional)
      // final azureResult = await _extractWithAzure(processedImage);
      // if (azureResult != null) results.add(azureResult);

    } catch (e) {
      print('❌ Error en extracción multi-engine: $e');
    }

    if (results.isEmpty) {
      print('⚠️ Ningún motor devolvió texto. Devolviendo resultado vacío para continuar el flujo.');
      final empty = OCRResult(extractedText: '', confidence: 0.0, engine: 'none');
      return MultiEngineOCRResult(
        individualResults: [empty],
        bestResult: empty,
        consensusText: '',
        overallConfidence: 0.0,
      );
    }

    // Generar consenso entre resultados
    final consensusResult = _generateConsensus(results);
    
    print('✅ EXTRACCIÓN MULTI-ENGINE COMPLETADA');
    print('📊 Engines exitosos: ${results.length}');
    print('🎯 Confianza general: ${consensusResult.overallConfidence.toStringAsFixed(2)}');
    
    return consensusResult;
  }

  /// Extrae texto usando Google ML Kit
  Future<OCRResult?> _extractWithMLKit(ProcessedImage image) async {
    if (kIsWeb || _textRecognizer == null) return null;
    
    print('📱 Extrayendo con Google ML Kit...');
    
    try {
      // Crear archivo temporal para ML Kit
      final tempFile = File.fromRawPath(image.processedBytes);
      final inputImage = InputImage.fromFile(tempFile);
      
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      
      // Calcular confianza basada en la cantidad y calidad del texto
      final confidence = _calculateMLKitConfidence(recognizedText);
      
      print('✅ ML Kit extrajo ${recognizedText.text.length} caracteres (confianza: ${confidence.toStringAsFixed(2)})');
      
      return OCRResult(
        extractedText: recognizedText.text,
        confidence: confidence,
        engine: 'ml_kit',
        metadata: {
          'blocks': recognizedText.blocks.length,
          'lines': recognizedText.blocks.fold<int>(0, (sum, block) => sum + block.lines.length),
          'elements': recognizedText.blocks.fold<int>(0, (sum, block) => 
            sum + block.lines.fold<int>(0, (lineSum, line) => lineSum + line.elements.length)),
        },
      );
      
    } catch (e) {
      print('❌ Error en ML Kit: $e');
      return null;
    }
  }

  /// Extrae texto usando OCR.space API
  Future<OCRResult?> _extractWithOCRSpace(ProcessedImage image, {bool retryAlternate = false}) async {
    print('🌐 Extrayendo con OCR.space...');
    
    try {
      final base64Image = base64Encode(image.processedBytes);
      
      final body = <String, String>{
        'apikey': 'helloworld',
        'base64Image': 'data:image/png;base64,$base64Image',
        'language': retryAlternate ? 'spa+eng' : 'spa',
        'isOverlayRequired': 'false',
        'detectOrientation': 'true',
        'scale': retryAlternate ? 'false' : 'true',
      };
      if (!retryAlternate) {
        body['OCREngine'] = '2';
        body['isTable'] = 'true';
      } else {
        // Alternate: default engine, no table mode
      }

      final response = await http
          .post(
            Uri.parse('https://api.ocr.space/parse/image'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(Duration(seconds: retryAlternate ? 20 : 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty) {
          final extractedText = data['ParsedResults'][0]['ParsedText'] ?? '';
          final confidence = _calculateOCRSpaceConfidence(data);
          
          print('✅ OCR.space extrajo ${extractedText.length} caracteres (confianza: ${confidence.toStringAsFixed(2)})');
          
          return OCRResult(
            extractedText: extractedText,
            confidence: confidence,
            engine: 'ocr_space',
            metadata: {
              'processingTimeInMilliseconds': data['ProcessingTimeInMilliseconds'],
              'isErroredOnProcessing': data['IsErroredOnProcessing'],
              'ocrExitCode': data['OCRExitCode'],
              'retryAlternate': retryAlternate,
            },
          );
        }
      }
      
      print('❌ OCR.space falló: ${response.statusCode} (retryAlternate=$retryAlternate)');
      return null;
      
    } catch (e) {
      print('❌ Error en OCR.space: $e (retryAlternate=$retryAlternate)');
      return null;
    }
  }

  /// Extrae texto usando Tesseract.js (web)
  Future<OCRResult?> _extractWithTesseract(ProcessedImage image) async {
    if (!kIsWeb) return null;
    
    print('🕸️ Extrayendo con Tesseract.js...');
    
    try {
      final base64Image = base64Encode(image.processedBytes);
      final dataUrl = 'data:image/png;base64,$base64Image';
      final text = await runTesseractOnWeb(dataUrl, 'spa');

      if (text.isEmpty) {
        print('⚠️ Tesseract.js devolvió texto vacío');
        return null;
      }

      // Heurística simple de confianza
      double confidence = 0.5;
      final priceMatches = RegExp(r'\d+[.,]\d{2}').allMatches(text).length;
      if (text.length > 150) confidence += 0.1;
      if (priceMatches >= 2) confidence += 0.1;
      if (priceMatches >= 5) confidence += 0.1;
      confidence = confidence.clamp(0.0, 1.0);

      print('✅ Tesseract.js extrajo ${text.length} caracteres (confianza: ${confidence.toStringAsFixed(2)})');

      return OCRResult(
        extractedText: text,
        confidence: confidence,
        engine: 'tesseract_js',
        metadata: {},
      );
      
    } catch (e) {
      print('❌ Error en Tesseract.js: $e');
      return null;
    }
  }

  /// Calcula la confianza para ML Kit basada en la estructura del texto
  double _calculateMLKitConfidence(RecognizedText recognizedText) {
    if (recognizedText.text.isEmpty) return 0.0;
    
    double confidence = 0.5; // Base
    
    // Bonus por cantidad de texto
    if (recognizedText.text.length > 100) confidence += 0.1;
    if (recognizedText.text.length > 300) confidence += 0.1;
    
    // Bonus por estructura (bloques y líneas)
    if (recognizedText.blocks.length > 5) confidence += 0.1;
    
    // Bonus por detección de precios (patrón €)
    final priceMatches = RegExp(r'\d+[.,]\d{2}').allMatches(recognizedText.text);
    if (priceMatches.length > 2) confidence += 0.1;
    if (priceMatches.length > 5) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Calcula la confianza para OCR.space basada en metadatos
  double _calculateOCRSpaceConfidence(Map<String, dynamic> data) {
    double confidence = 0.6; // Base más alta para OCR.space
    
    // Penalizar si hay errores
    if (data['IsErroredOnProcessing'] == true) {
      confidence -= 0.3;
    }
    
    // Bonus por exit code exitoso
    if (data['OCRExitCode'] == 1) {
      confidence += 0.2;
    }
    
    // Bonus por tiempo de procesamiento razonable
    final processingTimeRaw = data['ProcessingTimeInMilliseconds'];
    int processingTime = 0;
    if (processingTimeRaw != null) {
      if (processingTimeRaw is int) {
        processingTime = processingTimeRaw;
      } else if (processingTimeRaw is String) {
        processingTime = int.tryParse(processingTimeRaw) ?? 0;
      }
    }
    if (processingTime > 0 && processingTime < 10000) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Genera consenso entre múltiples resultados OCR
  MultiEngineOCRResult _generateConsensus(List<OCRResult> results) {
    print('🤝 Generando consenso entre ${results.length} resultados...');
    
    // Ordenar por confianza
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // El mejor resultado es el de mayor confianza
    final bestResult = results.first;
    
    // Generar texto de consenso
    String consensusText = bestResult.extractedText;
    
    // Si tenemos múltiples resultados, intentar mejorar el consenso
    if (results.length > 1) {
      consensusText = _improveTextWithConsensus(results);
    }
    
    // Calcular confianza general
    double overallConfidence = results.fold<double>(0.0, (sum, result) => sum + result.confidence) / results.length;
    
    // Bonus si múltiples engines coinciden
    if (results.length > 1) {
      final similarity = _calculateTextSimilarity(results[0].extractedText, results[1].extractedText);
      overallConfidence += similarity * 0.2;
    }
    
    overallConfidence = overallConfidence.clamp(0.0, 1.0);
    
    print('📈 Consenso generado - Confianza: ${overallConfidence.toStringAsFixed(2)}');
    
    return MultiEngineOCRResult(
      individualResults: results,
      bestResult: bestResult,
      consensusText: consensusText,
      overallConfidence: overallConfidence,
    );
  }

  /// Mejora el texto usando consenso entre múltiples resultados
  String _improveTextWithConsensus(List<OCRResult> results) {
    // Implementación simplificada - usar el mejor resultado
    // En una implementación completa, compararíamos línea por línea
    
    String bestText = results.first.extractedText;
    
    // TODO: Implementar algoritmo de consenso más sofisticado
    // - Comparar línea por línea
    // - Usar algoritmos de distancia de edición
    // - Corregir caracteres con mayor consenso
    
    return bestText;
  }

  /// Calcula la similitud entre dos textos (0.0 - 1.0)
  double _calculateTextSimilarity(String text1, String text2) {
    if (text1.isEmpty && text2.isEmpty) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    
    // Algoritmo simple de similitud basado en caracteres comunes
    final set1 = text1.toLowerCase().split('').toSet();
    final set2 = text2.toLowerCase().split('').toSet();
    
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Liberar recursos
  void dispose() {
    _textRecognizer?.close();
  }
}
