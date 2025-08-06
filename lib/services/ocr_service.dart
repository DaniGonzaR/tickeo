import 'dart:io';
import 'package:tickeo/models/bill_item.dart';
import 'package:uuid/uuid.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final Uuid _uuid = const Uuid();

  // Simplified OCR service for web compatibility
  // In a real implementation, this would use platform-specific OCR
  Future<Map<String, dynamic>> processReceiptImage(File imageFile) async {
    try {
      // Simulate OCR processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Return mock data for demonstration
      // In a real app, this would process the image and extract text
      return generateMockReceiptData();
    } catch (e) {
      throw Exception('Error procesando imagen: $e');
    }
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

  void dispose() {
    // Cleanup if needed
  }
}
