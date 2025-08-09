// DEPRECATED: Este archivo mantiene compatibilidad con el código existente
// El nuevo sistema está en UniversalOCRService

import 'package:tickeo/services/universal_ocr_service.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();
  
  final UniversalOCRService _universalOCR = UniversalOCRService();

  /// Initialize the OCR service
  void initialize() {
    _universalOCR.initialize();
  }

  /// Process image and extract receipt data
  Future<Map<String, dynamic>> processReceiptImage(dynamic imageFile) async {
    print('🔄 Usando Universal OCR Service (compatibilidad)...');
    return await _universalOCR.processReceiptImage(imageFile);
  }

  /// Dispose resources
  void dispose() {
    _universalOCR.dispose();
  }
}
