import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  static const Uuid _uuid = Uuid();
  TextRecognizer? _textRecognizer;

  /// Initialize the OCR service
  void initialize() {
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer();
    }
  }

  /// Process image and extract receipt data
  Future<Map<String, dynamic>> processReceiptImage(dynamic imageFile) async {
    print('🚀 STARTING OCR PROCESSING...');
    
    try {
      if (kIsWeb) {
        return await _processImageOnWeb(imageFile);
      } else {
        return await _processImageOnMobile(imageFile);
      }
    } catch (e) {
      print('❌ OCR processing failed: $e');
      return {
        'success': false,
        'error': 'OCR processing failed: $e',
        'items': <BillItem>[],
        'confidence': 0.0,
        'needsReview': true,
      };
    }
  }

  /// Process image on mobile using Google ML Kit
  Future<Map<String, dynamic>> _processImageOnMobile(dynamic imageFile) async {
    print('📱 Processing on mobile with ML Kit...');
    
    if (_textRecognizer == null) {
      initialize();
    }

    final inputImage = InputImage.fromFile(File(imageFile.path));
    final recognizedText = await _textRecognizer!.processImage(inputImage);
    
    print('📝 ML Kit extracted text (${recognizedText.text.length} chars):');
    print(recognizedText.text);
    
    return _parseReceiptText(recognizedText.text);
  }

  /// Process image on web using OCR.space API
  Future<Map<String, dynamic>> _processImageOnWeb(dynamic imageFile) async {
    print('🌐 Processing on web with OCR.space...');
    
    try {
      // Convert image to base64
      List<int> bytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(bytes);
      
      // Call OCR.space API
      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'apikey': 'helloworld', // Free tier key
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'spa',
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty) {
          final extractedText = data['ParsedResults'][0]['ParsedText'] ?? '';
          print('📝 OCR.space extracted text (${extractedText.length} chars):');
          print(extractedText);
          
          return _parseReceiptText(extractedText);
        }
      }
      
      throw Exception('OCR.space API failed');
    } catch (e) {
      print('❌ Web OCR failed: $e');
      return _generateFallbackResult();
    }
  }

  /// Parse extracted text and identify products/prices
  Map<String, dynamic> _parseReceiptText(String text) {
    print('🔍 PARSING RECEIPT TEXT...');
    
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    print('📄 Found ${lines.length} non-empty lines');
    for (int i = 0; i < lines.length; i++) {
      print('  Line $i: "${lines[i]}"');
    }

    // Try enhanced Spanish parsing first
    List<BillItem> items = _parseSpanishTicketFormatFixed(lines);
    
    if (items.isEmpty) {
      print('⚠️ Spanish parsing failed, trying alternative methods...');
      items = _tryAlternativeParsing(lines);
    }

    final confidence = items.isNotEmpty ? 0.8 : 0.3;
    final needsReview = items.isEmpty || confidence < 0.7;

    print('✅ PARSING COMPLETE: ${items.length} items found');
    for (final item in items) {
      print('  - ${item.name}: €${item.price.toStringAsFixed(2)}');
    }

    return {
      'success': true,
      'items': items,
      'confidence': confidence,
      'needsReview': needsReview,
      'extractedText': text,
    };
  }

  /// Enhanced Spanish parsing for both restaurant and supermarket receipts
  List<BillItem> _parseSpanishTicketFormatFixed(List<String> lines) {
    print('=== ENHANCED SPANISH PARSING V4.0 ===');
    final items = <BillItem>[];
    
    // STEP 1: Enhanced patterns to skip (headers, footers, metadata)
    final skipPatterns = [
      // Restaurant patterns
      'aver', 'a arcones', 'terraza', 'factura proforma', 'camarero', 'mesa',
      // Supermarket patterns  
      'alcampo', 'factura simplificada', 'establecimiento', 'localidad',
      'numero tarjeta', 'numero operacion', 'tipo de transaccion', 'codigo respuesta',
      'importe', 'numero autorizacion', 'fecha', 'hora', 'verificacion',
      // Common patterns
      'no op.:', 'uds.', 'producto', 'base:', 'cuota:', 'tot', 'ap',
      'total:', 'total (impuestos incl.)', 'gracias por su visita',
      'iva', 'impuesto', 'subtotal', '10%', '21%', 'c iva', 'a iva', 'b iva',
      'num. total art.', 'vendidos', 'imp.', 'para el cliente',
      'etiqueta con usuario', 'tarjeta', 'cambio', '€*', '€', 'eur/kg'
    ];
    
    // STEP 2: Extract all valid prices from the text
    final allPrices = <double>[];
    final priceLines = <int, double>{};
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Look for prices: 1.23, 12.34, 123.45 format
      final priceMatches = RegExp(r'(\d{1,3}[.,]\d{2})(?!\s*(?:kg|l|eur|€))').allMatches(line);
      for (final match in priceMatches) {
        final priceStr = match.group(1)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;
        if (price >= 0.50 && price <= 100.0) { // Reasonable product prices
          allPrices.add(price);
          priceLines[i] = price;
        }
      }
    }
    
    print('Found prices: ${allPrices.map((p) => '€${p.toStringAsFixed(2)}').join(', ')}');
    
    // STEP 3: Identify product lines (lines that look like products)
    final productCandidates = <int, String>{};
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();
      
      // Skip if it's a header/footer pattern
      if (skipPatterns.any((pattern) => lowerLine.contains(pattern))) {
        continue;
      }
      
      // Skip if line is too short or just numbers/symbols
      if (line.length < 3 || RegExp(r'^[\d\s.,€*-]+$').hasMatch(line)) {
        continue;
      }
      
      // Skip if line contains only price information
      if (RegExp(r'^\s*\d+[.,]\d{2}\s*[€]?\s*[ABC]?\s*$').hasMatch(line)) {
        continue;
      }
      
      // This looks like a product if it contains letters and reasonable length
      if (RegExp(r'[a-zA-ZáéíóúñüÁÉÍÓÚÑÜ]').hasMatch(line) && line.length >= 3) {
        productCandidates[i] = line;
      }
    }
    
    print('Product candidates found: ${productCandidates.length}');
    productCandidates.forEach((lineNum, product) {
      print('  Line $lineNum: "$product"');
    });
    
    // STEP 4: Match products with prices using different strategies
    final usedPrices = <double>{};
    
    // Strategy 1: Products with prices on the same line
    for (final entry in productCandidates.entries) {
      final lineNum = entry.key;
      final productLine = entry.value;
      
      if (priceLines.containsKey(lineNum)) {
        final price = priceLines[lineNum]!;
        if (!usedPrices.contains(price)) {
          // Extract clean product name by removing price and symbols
          String cleanName = productLine
              .replaceAll(RegExp(r'\d+[.,]\d{2}'), '') // Remove prices
              .replaceAll(RegExp(r'[€*\s]+$'), '') // Remove trailing symbols
              .replaceAll(RegExp(r'^\d+\s*x\s*[.,]?\d*\s*'), '') // Remove quantity prefix like "3 x ,73"
              .replaceAll(RegExp(r'\s*[ABC]\s*$'), '') // Remove tax codes
              .trim();
          
          if (cleanName.length >= 2) {
            items.add(BillItem(
              id: _uuid.v4(),
              name: _cleanProductName(cleanName),
              price: price,
              selectedBy: [],
            ));
            usedPrices.add(price);
            print('  ✅ Same-line match: "${_cleanProductName(cleanName)}" -> €${price.toStringAsFixed(2)}');
          }
        }
      }
    }
    
    // Strategy 2: Products followed by prices on next line(s) - for supermarket format
    for (final entry in productCandidates.entries) {
      final lineNum = entry.key;
      final productLine = entry.value;
      
      // Skip if already matched
      if (priceLines.containsKey(lineNum)) continue;
      
      // Look for price in next 1-3 lines
      for (int offset = 1; offset <= 3 && lineNum + offset < lines.length; offset++) {
        final nextLineNum = lineNum + offset;
        if (priceLines.containsKey(nextLineNum)) {
          final price = priceLines[nextLineNum]!;
          if (!usedPrices.contains(price)) {
            String cleanName = _cleanProductName(productLine);
            
            if (cleanName.length >= 2) {
              items.add(BillItem(
                id: _uuid.v4(),
                name: cleanName,
                price: price,
                selectedBy: [],
              ));
              usedPrices.add(price);
              print('  ✅ Next-line match: "$cleanName" -> €${price.toStringAsFixed(2)} (line $lineNum -> $nextLineNum)');
              break;
            }
          }
        }
      }
    }
    
    // Strategy 3: Known product patterns with flexible matching
    final knownProducts = {
      'coca': ['coca', 'cola'],
      'agua': ['agua', 'font', 'vella'],
      'jarra': ['jarra', 'tinto', 'verano'],
      'victoria': ['victoria'],
      'patatas': ['patatas', 'salsas'],
      'empanada': ['empanada', 'carne'],
      'protector': ['protector', 'solar'],
      'bebida': ['bebida', 'green', 'ene'],
      'melocoton': ['melocoton', 'rojo'],
    };
    
    for (final entry in productCandidates.entries) {
      final lineNum = entry.key;
      final productLine = entry.value.toLowerCase();
      
      // Skip if already processed
      if (items.any((item) => item.name.toLowerCase().contains(productLine.split(' ').first))) {
        continue;
      }
      
      for (final knownEntry in knownProducts.entries) {
        final keywords = knownEntry.value;
        
        if (keywords.any((keyword) => productLine.contains(keyword))) {
          // Find best available price
          double? bestPrice;
          double minDistance = 999.0;
          
          for (final price in allPrices) {
            if (usedPrices.contains(price)) continue;
            
            // Calculate distance based on line proximity
            double distance = 999.0;
            for (final priceEntry in priceLines.entries) {
              if (priceEntry.value == price) {
                distance = math.min(distance, (priceEntry.key - lineNum).abs().toDouble());
              }
            }
            
            if (distance < minDistance) {
              minDistance = distance;
              bestPrice = price;
            }
          }
          
          if (bestPrice != null && minDistance <= 5) {
            String displayName = _cleanProductName(lines[lineNum]);
            items.add(BillItem(
              id: _uuid.v4(),
              name: displayName,
              price: bestPrice,
              selectedBy: [],
            ));
            usedPrices.add(bestPrice);
            print('  ✅ Known-product match: "$displayName" -> €${bestPrice.toStringAsFixed(2)} (distance: $minDistance)');
            break;
          }
        }
      }
    }
    
    print('=== ENHANCED SPANISH PARSING COMPLETE ===');
    print('Successfully extracted ${items.length} products');
    
    return items;
  }

  /// Alternative parsing for fallback
  List<BillItem> _tryAlternativeParsing(List<String> lines) {
    print('=== ALTERNATIVE PARSING ===');
    final items = <BillItem>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip obvious non-product lines
      if (line.length < 3 || _isHeaderOrFooter(line)) continue;
      
      // Look for lines with prices
      final priceMatch = RegExp(r'(\d{1,3}[.,]\d{2})').firstMatch(line);
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (price >= 0.50 && price <= 50.0) {
          // Extract product name by removing price
          String productName = line.replaceAll(priceMatch.group(0)!, '').trim();
          productName = productName.replaceAll(RegExp(r'[€\$]'), '').trim();
          
          if (productName.length >= 2) {
            items.add(BillItem(
              id: _uuid.v4(),
              name: _cleanProductName(productName),
              price: price,
              selectedBy: [],
            ));
          }
        }
      }
    }
    
    return items;
  }

  /// Check if line is header or footer
  bool _isHeaderOrFooter(String line) {
    final lower = line.toLowerCase();
    final headerFooterPatterns = [
      'factura', 'proforma', 'total', 'subtotal', 'iva', 'impuesto',
      'gracias', 'visita', 'fecha', 'hora', 'mesa', 'camarero',
      'aver', 'arcones', 'terraza', 'importe', 'base', 'cuota'
    ];
    
    return headerFooterPatterns.any((pattern) => lower.contains(pattern));
  }

  /// Clean product name
  String _cleanProductName(String name) {
    String cleaned = name.trim();
    
    // Remove quantity prefixes
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*[xX]?\s*'), '');
    
    // Capitalize properly
    return cleaned.split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ')
        .trim();
  }

  /// Generate fallback result when OCR fails
  Map<String, dynamic> _generateFallbackResult() {
    return {
      'success': false,
      'items': <BillItem>[],
      'confidence': 0.0,
      'needsReview': true,
      'error': 'OCR extraction failed - manual entry required',
    };
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer?.close();
  }
}
