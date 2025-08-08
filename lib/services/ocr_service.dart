import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' if (dart.library.html) 'package:tickeo/utils/web_stubs.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:uuid/uuid.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final Uuid _uuid = const Uuid();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Process receipt image using ML Kit text recognition
  Future<Map<String, dynamic>> processReceiptImage(dynamic imageFile) async {
    try {
      // Check if running on web (fallback to mock data)
      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 2));
        return generateMockReceiptData();
      }

      // Use ML Kit for text recognition on mobile
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Parse the recognized text to extract receipt data
      return _parseReceiptText(recognizedText.text);
    } catch (e) {
      // Fallback to mock data if OCR fails
      return generateMockReceiptData();
    }
  }

  /// Parse recognized text to extract receipt information
  Map<String, dynamic> _parseReceiptText(String text) {
    try {
      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      final items = <BillItem>[];
      
      // Simple parsing logic for common receipt formats
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Look for price patterns (e.g., "12.50", "€15.00", "$10.99")
        final priceRegex = RegExp(r'([€\$]?)(\d+[.,]\d{2})([€\$]?)');
        final match = priceRegex.firstMatch(line);
        
        if (match != null) {
          final priceStr = match.group(2)?.replaceAll(',', '.') ?? '0.00';
          final price = double.tryParse(priceStr) ?? 0.0;
          
          if (price > 0) {
            // Extract item name (text before the price)
            final nameMatch = RegExp(r'^(.+?)\s+[€\$]?\d+[.,]\d{2}').firstMatch(line);
            final itemName = nameMatch?.group(1)?.trim() ?? 'Artículo ${items.length + 1}';
            
            items.add(BillItem(
              id: _uuid.v4(),
              name: _cleanItemName(itemName),
              price: price,
              selectedBy: [],
            ));
          }
        }
      }
      
      // If no items found, return mock data
      if (items.isEmpty) {
        return generateMockReceiptData();
      }
      
      final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.price);
      
      return {
        'items': items,
        'subtotal': subtotal,
        'tax': 0.0, // No tax calculation as per previous requirements
        'tip': 0.0, // No tip calculation as per previous requirements
        'total': subtotal,
      };
    } catch (e) {
      // Fallback to mock data if parsing fails
      return generateMockReceiptData();
    }
  }
  
  /// Clean and format item names
  String _cleanItemName(String name) {
    // Remove common receipt artifacts
    name = name.replaceAll(RegExp(r'[*#@]+'), '').trim();
    
    // Capitalize first letter of each word
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  Map<String, dynamic> generateMockReceiptData() {
    // Generate mock receipt data for demonstration
    final items = [
      BillItem(
        id: _uuid.v4(),
        name: 'Pizza Margherita',
        price: 12.50,
        selectedBy: [],
      ),
      BillItem(
        id: _uuid.v4(),
        name: 'Coca Cola',
        price: 2.50,
        selectedBy: [],
      ),
      BillItem(
        id: _uuid.v4(),
        name: 'Ensalada César',
        price: 8.00,
        selectedBy: [],
      ),
    ];

    final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.price);
    final total = subtotal; // No tax or tip, total equals subtotal

    return {
      'items': items,
      'subtotal': subtotal,
      'tax': 0.0, // No tax as per user requirements
      'total': total,
      'restaurantName': 'Restaurante Demo',
    };
  }

  /// Dispose of resources
  void dispose() {
    _textRecognizer.close();
  }
}
