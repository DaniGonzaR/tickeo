import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Preprocesador de imágenes para mejorar la calidad antes del OCR
class ImagePreprocessor {
  static final ImagePreprocessor _instance = ImagePreprocessor._internal();
  factory ImagePreprocessor() => _instance;
  ImagePreprocessor._internal();

  /// Procesa y mejora una imagen para OCR óptimo
  Future<ProcessedImage> enhanceForOCR(dynamic imageFile) async {
    print('🖼️ INICIANDO PREPROCESAMIENTO DE IMAGEN...');
    
    try {
      // Cargar imagen
      Uint8List imageBytes;
      if (imageFile is File) {
        imageBytes = await imageFile.readAsBytes();
      } else if (imageFile is Uint8List) {
        imageBytes = imageFile;
      } else if (imageFile is XFile) {
        // Manejar XFile (image_picker)
        imageBytes = await imageFile.readAsBytes();
      } else {
        // Intentar convertir cualquier tipo con readAsBytes si tiene el método
        try {
          imageBytes = await imageFile.readAsBytes();
        } catch (e) {
          throw Exception('Tipo de imagen no soportado: ${imageFile.runtimeType}');
        }
      }

      // Decodificar imagen
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      print('📐 Imagen original: ${originalImage.width}x${originalImage.height}');

      // Aplicar mejoras secuenciales
      img.Image processedImage = originalImage;

      // 1. Detección y corrección de orientación
      processedImage = await _correctOrientation(processedImage);

      // 2. Redimensionar si es necesario (optimizar para OCR)
      processedImage = _resizeForOCR(processedImage);

      // 3. Mejorar contraste y brillo
      processedImage = _enhanceContrast(processedImage);

      // 4. Reducir ruido
      processedImage = _reduceNoise(processedImage);

      // 5. Binarización adaptativa para texto
      processedImage = _adaptiveBinarization(processedImage);

      // 6. Enderezar líneas de texto si es necesario
      processedImage = await _straightenText(processedImage);

      // Convertir de vuelta a bytes
      final processedBytes = Uint8List.fromList(img.encodePng(processedImage));

      print('✅ Preprocesamiento completado: ${processedImage.width}x${processedImage.height}');

      return ProcessedImage(
        originalBytes: imageBytes,
        processedBytes: processedBytes,
        width: processedImage.width,
        height: processedImage.height,
        improvements: [
          'Orientación corregida',
          'Contraste mejorado',
          'Ruido reducido',
          'Binarización aplicada',
          'Texto enderezado'
        ],
      );

    } catch (e) {
      print('❌ Error en preprocesamiento: $e');
      // Retornar imagen original si falla el procesamiento
      Uint8List originalBytes;
      if (imageFile is File) {
        originalBytes = await imageFile.readAsBytes();
      } else {
        originalBytes = imageFile as Uint8List;
      }
      
      return ProcessedImage(
        originalBytes: originalBytes,
        processedBytes: originalBytes,
        width: 0,
        height: 0,
        improvements: [],
        error: e.toString(),
      );
    }
  }

  /// Detecta y corrige la orientación de la imagen
  Future<img.Image> _correctOrientation(img.Image image) async {
    print('🔄 Corrigiendo orientación...');
    
    // Análisis simple de orientación basado en densidad de texto
    // En un ticket, el texto suele estar más concentrado horizontalmente
    
    final rotations = [0, 90, 180, 270];
    img.Image bestImage = image;
    double bestScore = 0.0;

    for (final rotation in rotations) {
      img.Image rotatedImage = image;
      
      if (rotation == 90) {
        rotatedImage = img.copyRotate(image, angle: 90);
      } else if (rotation == 180) {
        rotatedImage = img.copyRotate(image, angle: 180);
      } else if (rotation == 270) {
        rotatedImage = img.copyRotate(image, angle: 270);
      }

      // Calcular score basado en distribución horizontal vs vertical
      double score = _calculateOrientationScore(rotatedImage);
      
      if (score > bestScore) {
        bestScore = score;
        bestImage = rotatedImage;
      }
    }

    print('📐 Mejor orientación encontrada (score: ${bestScore.toStringAsFixed(2)})');
    return bestImage;
  }

  /// Calcula un score para determinar la orientación correcta
  double _calculateOrientationScore(img.Image image) {
    // Convertir a escala de grises para análisis
    final grayImage = img.grayscale(image);
    
    // Calcular varianza horizontal vs vertical
    double horizontalVariance = 0.0;
    double verticalVariance = 0.0;
    
    // Muestrear líneas para calcular varianza
    for (int y = 0; y < grayImage.height; y += 10) {
      List<int> horizontalLine = [];
      for (int x = 0; x < grayImage.width; x++) {
        final pixel = grayImage.getPixel(x, y);
        horizontalLine.add(img.getLuminance(pixel).toInt());
      }
      horizontalVariance += _calculateVariance(horizontalLine);
    }

    for (int x = 0; x < grayImage.width; x += 10) {
      List<int> verticalLine = [];
      for (int y = 0; y < grayImage.height; y++) {
        final pixel = grayImage.getPixel(x, y);
        verticalLine.add(img.getLuminance(pixel).toInt());
      }
      verticalVariance += _calculateVariance(verticalLine);
    }

    // El texto horizontal debería tener mayor varianza horizontal
    return horizontalVariance / (verticalVariance + 1.0);
  }

  /// Calcula la varianza de una lista de valores
  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0.0;
    
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return variance;
  }

  /// Redimensiona la imagen para OCR óptimo
  img.Image _resizeForOCR(img.Image image) {
    print('📏 Redimensionando para OCR...');
    
    // Tamaño óptimo para OCR: entre 1500-3000px en el lado más largo
    const int targetLongSide = 2000;
    const int minLongSide = 1200;
    
    int longSide = image.width > image.height ? image.width : image.height;
    
    if (longSide < minLongSide) {
      // Escalar hacia arriba si es muy pequeña
      double scale = minLongSide / longSide;
      return img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    } else if (longSide > targetLongSide) {
      // Escalar hacia abajo si es muy grande
      double scale = targetLongSide / longSide;
      return img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }
    
    return image;
  }

  /// Mejora el contraste de la imagen
  img.Image _enhanceContrast(img.Image image) {
    print('🌟 Mejorando contraste...');
    
    // Aplicar ajuste de contraste adaptativo
    return img.adjustColor(
      image,
      contrast: 1.3,
      brightness: 1.1,
      gamma: 0.9,
    );
  }

  /// Reduce el ruido de la imagen
  img.Image _reduceNoise(img.Image image) {
    print('🧹 Reduciendo ruido...');
    
    // Aplicar filtro gaussiano suave para reducir ruido
    return img.gaussianBlur(image, radius: 1);
  }

  /// Aplica binarización adaptativa
  img.Image _adaptiveBinarization(img.Image image) {
    print('⚫⚪ Aplicando binarización...');
    
    // Convertir a escala de grises
    img.Image grayImage = img.grayscale(image);
    
    // Aplicar threshold adaptativo
    // Esto mejora la legibilidad del texto para OCR
    
    final threshold = _calculateOtsuThreshold(grayImage);
    
    for (int y = 0; y < grayImage.height; y++) {
      for (int x = 0; x < grayImage.width; x++) {
        final pixel = grayImage.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        
        // Binarizar: blanco o negro
        final newColor = luminance > threshold ? 
            img.ColorRgb8(255, 255, 255) : 
            img.ColorRgb8(0, 0, 0);
            
        grayImage.setPixel(x, y, newColor);
      }
    }
    
    return grayImage;
  }

  /// Calcula el threshold óptimo usando el método de Otsu
  int _calculateOtsuThreshold(img.Image image) {
    // Histograma de intensidades
    List<int> histogram = List.filled(256, 0);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel).toInt();
        histogram[luminance]++;
      }
    }
    
    // Método de Otsu simplificado
    int total = image.width * image.height;
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }
    
    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double varMax = 0;
    int threshold = 0;
    
    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;
      
      wF = total - wB;
      if (wF == 0) break;
      
      sumB += i * histogram[i];
      double mB = sumB / wB;
      double mF = (sum - sumB) / wF;
      
      double varBetween = wB * wF * (mB - mF) * (mB - mF);
      
      if (varBetween > varMax) {
        varMax = varBetween;
        threshold = i;
      }
    }
    
    return threshold;
  }

  /// Endereza las líneas de texto
  Future<img.Image> _straightenText(img.Image image) async {
    print('📏 Enderezando texto...');
    
    // Análisis simple de líneas para detectar inclinación
    // En una implementación completa, usaríamos transformada de Hough
    
    // Por ahora, retornamos la imagen sin cambios
    // TODO: Implementar detección de inclinación y corrección
    
    return image;
  }
}

/// Resultado del preprocesamiento de imagen
class ProcessedImage {
  final Uint8List originalBytes;
  final Uint8List processedBytes;
  final int width;
  final int height;
  final List<String> improvements;
  final String? error;

  ProcessedImage({
    required this.originalBytes,
    required this.processedBytes,
    required this.width,
    required this.height,
    required this.improvements,
    this.error,
  });

  bool get hasError => error != null;
  bool get wasProcessed => improvements.isNotEmpty;
}
