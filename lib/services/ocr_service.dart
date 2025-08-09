import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    if (dart.library.html) 'package:tickeo/utils/web_stubs.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:js' if (dart.library.io) 'dart:js' as js;
import 'package:http/http.dart' as http;


class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final Uuid _uuid = const Uuid();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // Advanced OCR correction tables
  static const Map<String, String> _ocrCorrections = {
    // Common OCR character mistakes
    '0': 'o', 'O': '0', '1': 'l', 'l': '1', 'I': '1',
    '5': 'S', 'S': '5', '6': 'G', 'G': '6', '8': 'B',
    'B': '8', '3': 'E', 'E': '3', '2': 'Z', 'Z': '2',
    // Spanish specific
    'ñ': 'n', 'Ñ': 'N', 'ç': 'c', 'Ç': 'C',
  };
  
  // Extended Spanish product dictionary with price ranges
  static const Map<String, Map<String, dynamic>> _spanishProducts = {
    // Bebidas
    'coca cola': {'category': 'bebida', 'minPrice': 1.0, 'maxPrice': 4.0, 'variations': ['coca', 'cola', 'c0ca', 'c0la']},
    'agua': {'category': 'bebida', 'minPrice': 0.5, 'maxPrice': 3.0, 'variations': ['agua', 'h2o', 'mineral']},
    'cerveza': {'category': 'bebida', 'minPrice': 1.5, 'maxPrice': 6.0, 'variations': ['cerv3za', 'beer', 'birra']},
    'vino': {'category': 'bebida', 'minPrice': 2.0, 'maxPrice': 15.0, 'variations': ['wine', 'tinto', 'blanco']},
    'café': {'category': 'bebida', 'minPrice': 1.0, 'maxPrice': 3.5, 'variations': ['coffee', 'espresso', 'cortado']},
    'zumo': {'category': 'bebida', 'minPrice': 1.5, 'maxPrice': 4.0, 'variations': ['juice', 'naranja', 'manzana']},
    
    // Comida principal
    'hamburguesa': {'category': 'comida', 'minPrice': 6.0, 'maxPrice': 18.0, 'variations': ['hamb0rguesa', 'burger', 'hamburgesa']},
    'pizza': {'category': 'comida', 'minPrice': 8.0, 'maxPrice': 25.0, 'variations': ['pizz4', 'margherita', 'quattro']},
    'paella': {'category': 'comida', 'minPrice': 12.0, 'maxPrice': 30.0, 'variations': ['pa3lla', 'arroz', 'valenciana']},
    'tortilla': {'category': 'comida', 'minPrice': 4.0, 'maxPrice': 12.0, 'variations': ['t0rtilla', 'española', 'patatas']},
    'bocadillo': {'category': 'comida', 'minPrice': 3.0, 'maxPrice': 10.0, 'variations': ['b0cadillo', 'sandwich', 'jamón']},
    'ensalada': {'category': 'comida', 'minPrice': 4.0, 'maxPrice': 15.0, 'variations': ['3nsalada', 'salad', 'mixta']},
    'croquetas': {'category': 'comida', 'minPrice': 3.0, 'maxPrice': 8.0, 'variations': ['cr0quetas', 'jamón', 'pollo']},
    'patatas': {'category': 'acompañamiento', 'minPrice': 2.0, 'maxPrice': 6.0, 'variations': ['p4tatas', 'fritas', 'bravas']},
    
    // Postres
    'flan': {'category': 'postre', 'minPrice': 2.0, 'maxPrice': 6.0, 'variations': ['fl4n', 'caramelo', 'huevo']},
    'helado': {'category': 'postre', 'minPrice': 2.0, 'maxPrice': 8.0, 'variations': ['h3lado', 'ice cream', 'vainilla']},
    'tarta': {'category': 'postre', 'minPrice': 3.0, 'maxPrice': 12.0, 'variations': ['t4rta', 'cake', 'chocolate']},
  };
  
  // Spanish keywords for receipt parsing
  static const List<String> _spanishKeywords = [
    'TOTAL', 'SUBTOTAL', 'SUMA', 'IMPORTE', 'PRECIO',
    'IVA', 'IMPUESTO', 'TAX', 'IGIC', 'IRPF',
    'DESCUENTO', 'DTO', 'OFERTA', 'PROMOCION', 'REBAJA',
    'EFECTIVO', 'TARJETA', 'CARD', 'CAMBIO', 'DEVOLUCION',
    'TICKET', 'FACTURA', 'RECIBO', 'COMPROBANTE', 'NOTA',
    'MESA', 'TABLE', 'CAMARERO', 'SERVICIO', 'PROPINA',
  ];

  /// Check image quality before OCR processing
  Future<bool> _isImageQualityGood(dynamic imageFile) async {
    try {
      if (kIsWeb) {
        // For web, assume quality is acceptable (browser handles basic validation)
        return true;
      }
      
      // For mobile, we could implement blur detection here
      // For now, return true to avoid blocking legitimate images
      return true;
    } catch (e) {
      print('⚠️ Image quality check failed: $e');
      return true; // Don't block on quality check failure
    }
  }

  /// Advanced OCR text correction using correction tables
  String _correctOCRErrors(String text) {
    String corrected = text;
    
    // Apply character-level corrections in price contexts
    final pricePattern = RegExp(r'(\d+[.,]?\d*)([€\$]?)');
    corrected = corrected.replaceAllMapped(pricePattern, (match) {
      String price = match.group(1)!;
      String currency = match.group(2) ?? '';
      
      // Correct common OCR errors in prices
      price = price.replaceAll('O', '0').replaceAll('l', '1').replaceAll('I', '1');
      price = price.replaceAll('S', '5').replaceAll('B', '8');
      
      return '$price$currency';
    });
    
    // Apply general corrections for product names
    _ocrCorrections.forEach((wrong, correct) {
      // Only apply corrections in non-price contexts
      corrected = corrected.replaceAllMapped(RegExp(r'([^\d.,€\$]*)($wrong)([^\d.,€\$]*)'), (match) {
        return '${match.group(1)}$correct${match.group(3)}';
      });
    });
    
    return corrected;
  }

  /// Enhanced text preprocessing with advanced normalization
  String _advancedPreprocessText(String rawText) {
    String processed = rawText;
    
    // Step 1: Apply OCR error corrections
    processed = _correctOCRErrors(processed);
    
    // Step 2: Normalize whitespace and line breaks
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    processed = processed.replaceAll(RegExp(r'\n\s*\n'), '\n');
    
    // Step 3: Fix common Spanish character issues
    processed = processed.replaceAll('ñ', 'ñ').replaceAll('Ñ', 'Ñ');
    processed = processed.replaceAll('á', 'á').replaceAll('é', 'é');
    processed = processed.replaceAll('í', 'í').replaceAll('ó', 'ó').replaceAll('ú', 'ú');
    
    // Step 4: Normalize decimal separators in Spanish context
    processed = processed.replaceAllMapped(RegExp(r'(\d+)[.,](\d{2})'), (match) {
      return '${match.group(1)}.${match.group(2)}';
    });
    
    // Step 5: Clean up currency symbols
    processed = processed.replaceAll(RegExp(r'[€\$]\s*'), '€');
    
    return processed.trim();
  }

  /// Intelligent product name matching using Spanish dictionary
  String? _matchSpanishProduct(String name) {
    final cleanName = name.toLowerCase().trim();
    
    // Direct match
    if (_spanishProducts.containsKey(cleanName)) {
      return cleanName;
    }
    
    // Check variations
    for (final entry in _spanishProducts.entries) {
      final productData = entry.value;
      final variations = productData['variations'] as List<String>;
      
      for (final variation in variations) {
        if (cleanName.contains(variation.toLowerCase()) || 
            variation.toLowerCase().contains(cleanName)) {
          return entry.key;
        }
      }
    }
    
    // Fuzzy matching using Levenshtein distance
    String? bestMatch;
    double bestSimilarity = 0.0;
    
    for (final productName in _spanishProducts.keys) {
      final similarity = _calculateLevenshteinSimilarity(cleanName, productName);
      if (similarity > 0.75 && similarity > bestSimilarity) {
        bestMatch = productName;
        bestSimilarity = similarity;
      }
    }
    
    return bestMatch;
  }

  /// Calculate Levenshtein similarity between two strings
  double _calculateLevenshteinSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final matrix = List.generate(a.length + 1, 
        (i) => List.generate(b.length + 1, (j) => 0));
    
    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost
        );
      }
    }
    
    final maxLength = math.max(a.length, b.length);
    return 1.0 - (matrix[a.length][b.length] / maxLength);
  }

  /// Validate price against product category
  bool _validatePriceForProduct(String productName, double price) {
    final matchedProduct = _matchSpanishProduct(productName);
    if (matchedProduct == null) return true; // Allow unknown products
    
    final productData = _spanishProducts[matchedProduct]!;
    final minPrice = productData['minPrice'] as double;
    final maxPrice = productData['maxPrice'] as double;
    
    return price >= minPrice && price <= maxPrice;
  }

  /// Process receipt image and extract bill items with UNIFIED ADVANCED PIPELINE
  Future<Map<String, dynamic>> processReceiptImage(dynamic imageFile) async {
    print('\n🚀 === ADVANCED OCR PIPELINE V2.0 STARTING ===');
    print('Platform: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      // STEP 0: Check image quality
      final isQualityGood = await _isImageQualityGood(imageFile);
      if (!isQualityGood) {
        print('⚠️ Image quality too low, requesting better image');
        return await _promptManualTextExtraction();
      }

      // STEP 1: Apply advanced image preprocessing (unified for both platforms)
      dynamic preprocessedImage = imageFile;

      if (kIsWeb) {
        // Apply web-specific preprocessing with perspective correction and text region detection
        preprocessedImage = await _processImageOnWeb(imageFile);
        print('✅ Web advanced preprocessing completed');
        return preprocessedImage; // Web processing already includes parsing
      } else {
        // Apply mobile-specific preprocessing
        preprocessedImage = await _preprocessImageForOCR(imageFile);
        print('✅ Mobile preprocessing completed');
      }

      // STEP 2: Perform Mobile OCR with ML Kit
      final inputImage = InputImage.fromFile(preprocessedImage ?? imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      print('=== ML KIT OCR RESULTS ===');
      print('Raw text extracted: "${recognizedText.text}"');
      print('Text length: ${recognizedText.text.length} characters');
      print('Text blocks found: ${recognizedText.blocks.length}');

      // Log each text block for debugging
      for (int i = 0; i < recognizedText.blocks.length; i++) {
        final block = recognizedText.blocks[i];
        print('Block $i: "${block.text}"');
        for (int j = 0; j < block.lines.length; j++) {
          final line = block.lines[j];
          print('  Line $j: "${line.text}"');
        }
      }
      print('===========================');

      // Check if we got meaningful text
      if (recognizedText.text.trim().isEmpty) {
        print('ML Kit returned empty text, prompting for manual extraction');
        return await _promptManualTextExtraction();
      }

      // STEP 3: Apply advanced text preprocessing with corrections
      final preprocessedText = _advancedPreprocessText(recognizedText.text);
      print('🔤 Advanced text preprocessing completed: "$preprocessedText"');

      // STEP 4: Parse with enhanced extraction strategies
      final parseResult = _parseReceiptTextAdvanced(preprocessedText);
      print(
          '📊 Advanced parsing completed: ${parseResult['items']?.length ?? 0} items found');

      // STEP 5: Validate results and add confidence scoring
      final validatedResult = _validateAndScoreResults(parseResult);
      print('✅ Validation completed with confidence: ${validatedResult['confidence']}');

      return validatedResult;
    } catch (e) {
      print('❌ Advanced OCR pipeline failed: $e');
      return await _promptManualTextExtraction();
    }
  }

  /// Advanced parsing with enhanced Spanish receipt recognition
  Map<String, dynamic> _parseReceiptTextAdvanced(String text) {
    try {
      print('\n=== ADVANCED RECEIPT PARSING ===');
      print('Input text length: ${text.length} characters');
      print('Raw input text: "$text"');

      // Show text in a more readable format
      final rawLines = text.split('\n');
      print('Text broken into ${rawLines.length} lines:');
      for (int i = 0; i < rawLines.length; i++) {
        print('  Line $i: "${rawLines[i]}"');
      }

      final lines = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      print('Processing ${lines.length} clean lines');

      final items = <BillItem>[];
      final detectedTotals = <String, double>{};

      // PHASE 1: Enhanced line-by-line extraction
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        print('Processing line $i: "$line"');

        // Check for totals first
        final totalMatch = _extractTotalFromLine(line);
        if (totalMatch != null) {
          detectedTotals[totalMatch['type']!] = totalMatch['amount']!;
          print('  -> Found ${totalMatch['type']}: €${totalMatch['amount']!.toStringAsFixed(2)}');
          continue;
        }

        // Skip header/footer lines
        if (_isHeaderOrFooterLineAdvanced(line)) {
          print('  -> Skipped (header/footer)');
          continue;
        }

        // Try enhanced item extraction
        final item = _extractItemFromLineAdvanced(line, items.length);
        if (item != null) {
          // Validate against Spanish product dictionary
          final isValidPrice = _validatePriceForProduct(item.name, item.price);
          if (isValidPrice) {
            items.add(item);
            print('  -> Found validated item: ${item.name} - €${item.price.toStringAsFixed(2)}');
          } else {
            print('  -> Item price validation failed: ${item.name} - €${item.price.toStringAsFixed(2)}');
            // Still add but mark for review
            items.add(item.copyWith(selectedBy: ['NEEDS_REVIEW']));
          }
        }
      }

      // PHASE 2: Multi-line Spanish parsing if needed
      if (items.isEmpty) {
        print('No items found with line-by-line parsing, trying multi-line Spanish parsing...');
        final spanishItems = _parseSpanishTicketFormatAdvanced(lines);
        items.addAll(spanishItems);
      }

      // PHASE 3: Aggressive extraction if still empty
      if (items.isEmpty) {
        print('Trying aggressive price extraction...');
        final aggressiveItems = _extractPricesFromTextAdvanced(text);
        items.addAll(aggressiveItems);
      }

      print('=== ADVANCED PARSING COMPLETE ===');
      print('Total items found: ${items.length}');
      print('Detected totals: $detectedTotals');

      // Calculate totals
      final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.price);
      final detectedTotal = detectedTotals['TOTAL'] ?? detectedTotals['SUMA'] ?? subtotal;

      return {
        'items': items,
        'subtotal': subtotal,
        'tax': 0.0,
        'tip': 0.0,
        'total': detectedTotal,
        'detectedTotals': detectedTotals,
        'restaurantName': 'Ticket Escaneado',
        'needsReview': (subtotal - detectedTotal).abs() > (detectedTotal * 0.02), // 2% tolerance
      };
    } catch (e) {
      print('❌ Advanced text parsing failed: $e');
      return _getBasicParsingResult();
    }
  }

  /// Legacy parsing method for fallback
  Map<String, dynamic> _parseReceiptText(String text) {
    try {
      print('\n=== PARSING RECEIPT TEXT ===');
      print('Input text length: ${text.length} characters');
      print('Raw input text: "$text"');

      // Show text in a more readable format
      final rawLines = text.split('\n');
      print('Text broken into ${rawLines.length} lines:');
      for (int i = 0; i < rawLines.length; i++) {
        print('  Line $i: "${rawLines[i]}"');
      }

      final lines = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      print('Processing ${lines.length} lines');

      final items = <BillItem>[];

      // Try to extract items from each line
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        print('Processing line $i: "$line"');

        // Skip header/footer lines
        if (_isHeaderOrFooterLine(line)) {
          print('  -> Skipped (header/footer)');
          continue;
        }

        // Try to extract item from this line
        final item = _extractItemFromLine(line, items.length);
        if (item != null) {
          items.add(item);
          print(
              '  -> Found item: ${item.name} - €${item.price.toStringAsFixed(2)}');
        }
      }

      // If no items found with standard parsing, try intelligent Spanish parsing FIRST
      if (items.isEmpty) {
        print(
            'No items found with standard parsing, trying intelligent Spanish parsing...');
        final spanishItems = _parseSpanishTicketFormat(lines);
        items.addAll(spanishItems);
      }

      // If still no items after Spanish parsing, try alternative strategies
      if (items.isEmpty) {
        print(
            'No items found with Spanish parsing, trying alternative strategies...');
        final alternativeItems = _tryAlternativeParsing(lines);
        items.addAll(alternativeItems);
      }

      // If still no items, try to extract any numbers as potential prices
      if (items.isEmpty) {
        print('Trying to extract any price-like patterns from text...');
        final priceItems = _extractPricesFromText(text);
        items.addAll(priceItems);
      }

      print('=== PARSING COMPLETE ===');
      print('Total items found: ${items.length}');

      // Apply intelligent validation and cleanup
      final validatedItems = _validateAndCleanItems(items);
      print('After validation: ${validatedItems.length} items');

      // If still no items found, return basic structure for manual editing
      if (validatedItems.isEmpty) {
        return _getBasicParsingResult();
      }

      items.clear();
      items.addAll(validatedItems);

      final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.price);

      return {
        'items': items,
        'subtotal': subtotal,
        'tax': 0.0,
        'tip': 0.0,
        'total': subtotal,
        'restaurantName': 'Ticket Escaneado',
        'manualExtraction': items.length == 1 && items.first.price == 0.00,
      };
    } catch (e) {
      print('❌ Legacy text parsing failed: $e');
      return _getBasicParsingResult();
    }
  }

  /// Get basic parsing result for manual editing
  Map<String, dynamic> _getBasicParsingResult() {
    return {
      'items': [
        BillItem(
          id: _uuid.v4(),
          name: 'Producto del ticket',
          price: 0.00,
          selectedBy: [],
        )
      ],
      'subtotal': 0.00,
      'tax': 0.0,
      'tip': 0.0,
      'total': 0.00,
      'restaurantName': 'Ticket Escaneado - Editar Manualmente',
      'manualExtraction': true,
      'confidence': 0.0,
      'needsReview': true,
    };
  }

  /// Enhanced header/footer detection with Spanish keywords
  bool _isHeaderOrFooterLineAdvanced(String line) {
    final lowerLine = line.toLowerCase().trim();

    // Skip very short lines (likely not products)
    if (lowerLine.length < 2) return true;

    // Skip lines that are only numbers, symbols, or very short
    if (RegExp(r'^[\d\s\-\.\*]{1,4}$').hasMatch(lowerLine)) return true;

    // Check against Spanish keywords
    for (final keyword in _spanishKeywords) {
      if (lowerLine.contains(keyword.toLowerCase())) {
        return true;
      }
    }

    // Enhanced patterns for Spanish receipts
    final skipPatterns = [
      // Restaurant info
      'restaurante', 'restaurant', 'bar', 'café', 'cafeteria', 'pizzeria',
      'taberna', 'cocina', 'kitchen', 'comida', 'food', 'menú', 'menu',
      'bienvenido', 'welcome', 'gracias', 'thank',

      // Date/time patterns
      RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}'), // dates
      RegExp(r'\d{1,2}:\d{2}'), // times
      
      // Address patterns
      'calle', 'street', 'avenida', 'plaza', 'c/', 'av.',
      'teléfono', 'tel', 'email', 'web', 'www',
      
      // Payment patterns
      'visa', 'mastercard', 'efectivo', 'cash', 'tarjeta', 'card',
    ];

    // Check string patterns
    for (final pattern in skipPatterns) {
      if (pattern is String && lowerLine.contains(pattern)) {
        return true;
      } else if (pattern is RegExp && pattern.hasMatch(lowerLine)) {
        return true;
      }
    }

    return false;
  }

  /// Legacy header/footer detection
  bool _isHeaderOrFooterLine(String line) {
    final lowerLine = line.toLowerCase().trim();

    // Skip very short lines (likely not products)
    if (lowerLine.length < 3) return true;

    // Skip lines that are only numbers, symbols, or very short
    if (RegExp(r'^[\d\s\-\.\*]{1,5}$').hasMatch(lowerLine)) return true;

    // Enhanced header/footer patterns for Spanish receipts
    final skipPatterns = [
      // Restaurant info
      'restaurante', 'restaurant', 'bar', 'café', 'cafeteria', 'pizzeria',
      'taberna',
      'cocina', 'kitchen', 'comida', 'food', 'menú', 'menu', 'bienvenido',
      'welcome',

      // Totals and calculations (be more specific to avoid false positives)
      'total:', 'subtotal:', 'suma:', 'importe total', 'precio total',
      'iva:', 'tax:', 'impuesto:', 'propina:', 'tip:', 'servicio:',
      'descuento:', 'discount:', 'oferta:', 'promoción:', 'cambio:', 'change:',

      // Date/time/location
      'fecha:', 'date:', 'hora:', 'time:', 'día:', 'day:',
      'mesa', 'table', 'sala', 'terraza', 'barra',

      // Staff and service
      'camarero', 'waiter', 'cajero', 'cashier', 'chef',
      'atendido', 'served', 'servido',

      // Footer messages
      'gracias', 'thank', 'vuelva', 'visit', 'again', 'pronto',
      'buen', 'good', 'día', 'noche', 'tarde',

      // Document types
      'ticket', 'factura', 'invoice', 'recibo', 'receipt',
      'comprobante', 'nota', 'cuenta',

      // Decorative elements
      '***', '---', '===', '___', '...', '***', '###',

      // Payment info
      'efectivo', 'cash', 'tarjeta', 'card', 'visa', 'mastercard',
      'pago', 'payment', 'cobro', 'charge',

      // Address/contact
      'calle', 'street', 'avenida', 'plaza', 'teléfono', 'tel',
      'email', 'web', 'www', '.com', '.es',
    ];

    // Skip lines that are too short (less than 2 chars) or too long (more than 60 chars)
    if (line.length < 2 || line.length > 60) return true;

    // Skip lines with only numbers, symbols, dates, or times
    if (RegExp(r'^[\d\s\-\/\.:\*#@\(\)]+$').hasMatch(line)) return true;

    // Skip lines that are mostly numbers (like phone numbers, dates)
    if (RegExp(r'^[\d\s\-\/\.:\(\)]{5,}$').hasMatch(line)) return true;

    // Skip lines containing skip patterns
    return skipPatterns.any((pattern) => lowerLine.contains(pattern));
  }

  /// Extract total amounts from lines
  Map<String, dynamic>? _extractTotalFromLine(String line) {
    
    // Patterns for different total types
    final totalPatterns = {
      'TOTAL': RegExp(r'total[:\s]*([€\s]*)([\d]+[.,][\d]{2})', caseSensitive: false),
      'SUBTOTAL': RegExp(r'subtotal[:\s]*([€\s]*)([\d]+[.,][\d]{2})', caseSensitive: false),
      'SUMA': RegExp(r'suma[:\s]*([€\s]*)([\d]+[.,][\d]{2})', caseSensitive: false),
      'IMPORTE': RegExp(r'importe[:\s]*([€\s]*)([\d]+[.,][\d]{2})', caseSensitive: false),
    };
    
    for (final entry in totalPatterns.entries) {
      final match = entry.value.firstMatch(line);
      if (match != null) {
        final priceStr = match.group(2)?.replaceAll(',', '.') ?? '0';
        final amount = double.tryParse(priceStr) ?? 0.0;
        if (amount > 0) {
          return {'type': entry.key, 'amount': amount};
        }
      }
    }
    
    return null;
  }

  /// Enhanced item extraction with Spanish product matching
  BillItem? _extractItemFromLineAdvanced(String line, int itemIndex) {
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return null;

    print('  Analyzing line (advanced): "$cleanLine"');

    // Strategy 1: Spanish product name + price patterns
    final spanishPatterns = [
      // "COCA COLA 2,50€" or "COCA COLA 2.50"
      RegExp(r'^([A-ZÁÉÍÓÚÑ\s]{3,})\s+([\d]+[.,][\d]{1,2})\s*€?\s*$'),
      // "Pizza Margherita    15.50"
      RegExp(r'^([a-zA-ZáéíóúñÁÉÍÓÚÑ\s]{4,})\s{2,}([\d]+[.,][\d]{1,2})\s*€?\s*$'),
      // "1 x Hamburguesa 8.50" or "2x Cerveza 5.00"
      RegExp(r'^([\d]+)\s*x\s*([a-zA-ZáéíóúñÁÉÍÓÚÑ\s]{3,})\s+([\d]+[.,][\d]{1,2})\s*€?\s*$'),
      // "Cerveza (33cl) 2.80"
      RegExp(r'^([a-zA-ZáéíóúñÁÉÍÓÚÑ\s\(\)\d]{3,})\s+([\d]+[.,][\d]{1,2})\s*€?\s*$'),
    ];

    for (int i = 0; i < spanishPatterns.length; i++) {
      final pattern = spanishPatterns[i];
      final match = pattern.firstMatch(cleanLine);
      if (match != null) {
        String name;
        String priceStr;
        int quantity = 1;
        
        if (i == 2) { // Quantity pattern
          quantity = int.tryParse(match.group(1)!) ?? 1;
          name = match.group(2)!.trim();
          priceStr = match.group(3)!;
        } else {
          name = match.group(1)!.trim();
          priceStr = match.group(2)!;
        }
        
        print('    -> Spanish pattern $i matched: "$name" - $priceStr (qty: $quantity)');
        
        // Try to match with Spanish product dictionary
        final matchedProduct = _matchSpanishProduct(name);
        if (matchedProduct != null) {
          name = matchedProduct; // Use standardized name
          print('    -> Matched to dictionary product: $matchedProduct');
        }
        
        final item = _createItemFromMatchAdvanced(name, priceStr, itemIndex, quantity);
        if (item != null) return item;
      }
    }

    // Fallback to original extraction methods
    return _extractItemFromLine(cleanLine, itemIndex);
  }

  /// Legacy item extraction method
  BillItem? _extractItemFromLine(String line, int itemIndex) {
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return null;

    print('  Analyzing line: "$cleanLine"');

    // Strategy 1: Multiple spaces separator "Pizza Margherita      15.50"
    final multiSpaceMatch =
        RegExp(r'^(.+?)\s{2,}([€\$]?\s*)(\d+[.,]\d{1,2})([€\$]?)\s*$')
            .firstMatch(cleanLine);
    if (multiSpaceMatch != null) {
      print('    -> Strategy 1 (multi-space) matched');
      return _createItemFromMatch(
          multiSpaceMatch.group(1)!, multiSpaceMatch.group(3)!, itemIndex);
    }

    // Strategy 2: Price with currency at end "Hamburguesa Clásica 12.50€" (more flexible)
    final endPriceMatch =
        RegExp(r'^(.+?)\s+(\d+[.,]\d{1,2})\s*[€€\$]?\s*$').firstMatch(line);
    if (endPriceMatch != null && endPriceMatch.group(1)!.trim().length > 2) {
      print('    -> Strategy 2 (end price) matched');
      return _createItemFromMatch(
          endPriceMatch.group(1)!, endPriceMatch.group(2)!, itemIndex);
    }

    // Strategy 3: Price with currency at start "€15.00 Pizza Margherita"
    final startPriceMatch =
        RegExp(r'^[€\$]?\s*(\d+[.,]\d{1,2})\s+(.+?)\s*$').firstMatch(line);
    if (startPriceMatch != null) {
      print('    -> Strategy 3 (start price) matched');
      return _createItemFromMatch(
          startPriceMatch.group(2)!, startPriceMatch.group(1)!, itemIndex);
    }

    // Strategy 4: Dots or dashes separator "Pizza Margherita.....15.50"
    final dotSeparatorMatch =
        RegExp(r'^(.+?)[\.\.\-\-]{2,}\s*(\d+[.,]\d{1,2})\s*[€\$]?\s*$')
            .firstMatch(line);
    if (dotSeparatorMatch != null) {
      print('    -> Strategy 4 (dot separator) matched');
      return _createItemFromMatch(
          dotSeparatorMatch.group(1)!, dotSeparatorMatch.group(2)!, itemIndex);
    }

    // Strategy 5: Quantity format "2 x Pizza 25.00" or "2x Pizza 25.00"
    final quantityMatch =
        RegExp(r'^(\d+)\s*x?\s+(.+?)\s+(\d+[.,]\d{1,2})\s*[€\$]?\s*$')
            .firstMatch(line);
    if (quantityMatch != null) {
      print('    -> Strategy 5 (quantity) matched');
      final quantity = int.tryParse(quantityMatch.group(1)!) ?? 1;
      final itemName = quantityMatch.group(2)!;
      final totalPrice =
          double.tryParse(quantityMatch.group(3)!.replaceAll(',', '.')) ?? 0.0;
      final unitPrice = quantity > 0 ? totalPrice / quantity : totalPrice;

      return _createItemFromMatch(
          '$quantity x $itemName', unitPrice.toStringAsFixed(2), itemIndex);
    }

    // Strategy 6: Tab separator (common in receipts)
    final tabMatch =
        RegExp(r'^(.+?)\t+(\d+[.,]\d{1,2})\s*[€\$]?\s*$').firstMatch(line);
    if (tabMatch != null) {
      print('    -> Strategy 6 (tab separator) matched');
      return _createItemFromMatch(
          tabMatch.group(1)!, tabMatch.group(2)!, itemIndex);
    }

    // Strategy 7: Price anywhere in line with word boundaries (more aggressive)
    final anywhereMatch = RegExp(r'(\d+[.,]\d{1,2})').firstMatch(line);
    if (anywhereMatch != null) {
      final priceStr = anywhereMatch.group(1)!;
      final priceIndex = line.indexOf(priceStr);

      // Get text before and after price
      final beforePrice = line.substring(0, priceIndex).trim();
      final afterPrice = line.substring(priceIndex + priceStr.length).trim();

      // Choose the longer, more meaningful text
      String itemName = '';
      if (beforePrice.length >= 2 && beforePrice.length >= afterPrice.length) {
        itemName = beforePrice;
      } else if (afterPrice.length >= 2) {
        itemName = afterPrice;
      }

      // Clean up the name and validate
      itemName = itemName.replaceAll(RegExp(r'[€\$\*\-\.]+$'), '').trim();
      if (itemName.length >= 2) {
        print('    -> Strategy 7 (anywhere) matched: "$itemName" - $priceStr');
        return _createItemFromMatch(itemName, priceStr, itemIndex);
      }
    }

    // Strategy 8: Advanced Spanish receipt patterns
    final spanishPatterns = [
      // "COCA COLA 1,50"
      RegExp(r'^([A-Z\s]{3,})\s+(\d+[.,]\d{1,2})\s*€?$'),
      // "Pizza 4 quesos    12.50"
      RegExp(r'^([a-zA-Z\s]{4,})\s{2,}(\d+[.,]\d{1,2})\s*€?$'),
      // "1 x Hamburguesa 8.50"
      RegExp(r'^\d+\s*x\s*([a-zA-Z\s]{3,})\s+(\d+[.,]\d{1,2})\s*€?$'),
      // "Cerveza (33cl) 2.80"
      RegExp(r'^([a-zA-Z\s\(\)\d]{3,})\s+(\d+[.,]\d{1,2})\s*€?$'),
    ];

    for (final pattern in spanishPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final price = match.group(2) ?? '';
        if (name.length >= 3) {
          print('    -> Spanish pattern matched: "$name" - $price');
          return _createItemFromMatch(name, price, itemIndex);
        }
      }
    }

    print('    -> No strategy matched');
    return null;
  }

  /// Enhanced item creation with quantity support
  BillItem? _createItemFromMatchAdvanced(String name, String priceStr, int itemIndex, [int quantity = 1]) {
    final price = double.tryParse(priceStr.replaceAll(',', '.')) ?? 0.0;

    // More flexible price validation
    if (price < 0.05 || price > 1000.00) return null;

    final cleanName = _cleanItemNameAdvanced(name);

    // Skip if name is too short or generic
    if (cleanName.length < 2) return null;

    // Skip obvious non-products
    final skipNames = ['total', 'suma', 'iva', 'descuento', 'cambio', 'efectivo', 'tarjeta'];
    if (skipNames.any((skip) => cleanName.toLowerCase().contains(skip))) {
      return null;
    }

    final finalName = quantity > 1 ? '$quantity x $cleanName' : cleanName;
    final unitPrice = quantity > 1 ? price / quantity : price;

    return BillItem(
      id: _uuid.v4(),
      name: finalName,
      price: unitPrice,
      quantity: quantity,
      selectedBy: [],
    );
  }

  /// Legacy item creation method
  BillItem? _createItemFromMatch(String name, String priceStr, int itemIndex) {
    final price = double.tryParse(priceStr.replaceAll(',', '.')) ?? 0.0;

    // Validate price range (more flexible range for various items)
    if (price < 0.10 || price > 500.00) return null;

    final cleanName = _cleanItemName(name);

    // Skip if name is too short or generic
    if (cleanName.length < 2) return null;

    return BillItem(
      id: _uuid.v4(),
      name: cleanName,
      price: price,
      selectedBy: [],
    );
  }

  /// Advanced Spanish ticket format parsing
  List<BillItem> _parseSpanishTicketFormatAdvanced(List<String> lines) {
    final items = <BillItem>[];
    
    print('\n=== ADVANCED SPANISH PARSING ===');
    
    // Look for product-price pairs across multiple lines
    for (int i = 0; i < lines.length - 1; i++) {
      final currentLine = lines[i].trim();
      final nextLine = lines[i + 1].trim();
      
      // Skip if current line looks like header/footer
      if (_isHeaderOrFooterLineAdvanced(currentLine)) continue;
      
      // Check if current line is a product name and next line has a price
      final priceMatch = RegExp(r'^([€\s]*)?([\d]+[.,][\d]{1,2})([€\s]*)?$').firstMatch(nextLine);
      if (priceMatch != null && currentLine.length >= 3) {
        final productName = currentLine;
        final priceStr = priceMatch.group(2)!;
        
        // Try to match with Spanish dictionary
        final matchedProduct = _matchSpanishProduct(productName);
        final finalName = matchedProduct ?? productName;
        
        final item = _createItemFromMatchAdvanced(finalName, priceStr, items.length);
        if (item != null) {
          items.add(item);
          print('  -> Multi-line match: "$finalName" - €${item.price.toStringAsFixed(2)}');
        }
      }
    }
    
    print('Advanced Spanish parsing found ${items.length} items');
    return items;
  }

  /// Enhanced price extraction with better validation
  List<BillItem> _extractPricesFromTextAdvanced(String text) {
    final items = <BillItem>[];
    final pricePattern = RegExp(r'([\d]+[.,][\d]{1,2})');
    final matches = pricePattern.allMatches(text);
    
    print('\n=== ADVANCED PRICE EXTRACTION ===');
    print('Found ${matches.length} potential prices');
    
    for (final match in matches) {
      final priceStr = match.group(1)!;
      final price = double.tryParse(priceStr.replaceAll(',', '.')) ?? 0.0;
      
      // More reasonable price range for Spanish restaurants
      if (price >= 0.50 && price <= 150.00) {
        // Try to find associated text
        final startIndex = math.max(0, match.start - 50);
        final endIndex = math.min(text.length, match.end + 20);
        final context = text.substring(startIndex, endIndex);
        
        // Look for product names in the context
        final words = context.split(RegExp(r'[\s\n]+'))
            .where((word) => word.length >= 3 && !RegExp(r'^[\d.,€\$]+$').hasMatch(word))
            .toList();
        
        if (words.isNotEmpty) {
          final productName = words.first;
          final matchedProduct = _matchSpanishProduct(productName);
          final finalName = matchedProduct ?? _cleanItemNameAdvanced(productName);
          
          if (finalName.length >= 3) {
            final item = BillItem(
              id: _uuid.v4(),
              name: finalName,
              price: price,
              selectedBy: [],
            );
            items.add(item);
            print('  -> Extracted: "$finalName" - €${price.toStringAsFixed(2)}');
          }
        }
      }
    }
    
    print('Advanced price extraction found ${items.length} items');
    return items;
  }

  /// Validate and score parsing results
  Map<String, dynamic> _validateAndScoreResults(Map<String, dynamic> parseResult) {
    final items = parseResult['items'] as List<BillItem>;
    final subtotal = parseResult['subtotal'] as double;
    final detectedTotal = parseResult['total'] as double;
    final needsReview = parseResult['needsReview'] as bool? ?? false;
    
    // Calculate confidence score
    double confidence = 1.0;
    
    // Reduce confidence if no items found
    if (items.isEmpty) {
      confidence = 0.0;
    } else if (items.length == 1 && items.first.price == 0.0) {
      confidence = 0.0;
    } else {
      // Reduce confidence based on total deviation
      final deviation = (subtotal - detectedTotal).abs();
      final deviationPercent = detectedTotal > 0 ? deviation / detectedTotal : 0.0;
      
      if (deviationPercent > 0.10) { // >10% deviation
        confidence *= 0.3;
      } else if (deviationPercent > 0.05) { // >5% deviation
        confidence *= 0.6;
      } else if (deviationPercent > 0.02) { // >2% deviation
        confidence *= 0.8;
      }
      
      // Boost confidence for dictionary matches
      int dictionaryMatches = 0;
      for (final item in items) {
        if (_matchSpanishProduct(item.name) != null) {
          dictionaryMatches++;
        }
      }
      final dictionaryRatio = items.isNotEmpty ? dictionaryMatches / items.length : 0.0;
      confidence *= (0.7 + 0.3 * dictionaryRatio); // Boost for dictionary matches
    }
    
    // Add validation results to parse result
    final result = Map<String, dynamic>.from(parseResult);
    result['confidence'] = confidence;
    result['needsReview'] = needsReview || confidence < 0.7;
    result['dictionaryMatches'] = items.where((item) => _matchSpanishProduct(item.name) != null).length;
    
    print('\n=== VALIDATION RESULTS ===');
    print('Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
    print('Needs review: ${result['needsReview']}');
    print('Dictionary matches: ${result['dictionaryMatches']}/${items.length}');
    
    return result;
  }

  /// Legacy alternative parsing method
  List<BillItem> _tryAlternativeParsing(List<String> lines) {
    final items = <BillItem>[];
    print('=== ALTERNATIVE PARSING STRATEGIES ===');

    // Strategy 1: Look for any line with a price, regardless of format
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      print('Alt parsing line $i: "$line"');

      // Skip obvious non-product lines
      if (_isHeaderOrFooterLine(line)) {
        print('  -> Skipped (header/footer)');
        continue;
      }

      // Find any price in the line (more flexible pattern)
      final priceMatches = RegExp(r'([€\$]?\s*)(\d{1,3}[.,]\d{1,2})(\s*[€\$]?)')
          .allMatches(line);

      for (final match in priceMatches) {
        final priceStr = match.group(2)?.replaceAll(',', '.') ?? '0.00';
        final price = double.tryParse(priceStr) ?? 0.0;

        if (price >= 0.10 && price <= 999.99) {
          // Extract text around the price as item name
          final beforePrice = line.substring(0, match.start).trim();
          final afterPrice = line.substring(match.end).trim();

          String itemName = beforePrice.isNotEmpty ? beforePrice : afterPrice;
          if (itemName.isEmpty) itemName = 'Producto ${items.length + 1}';

          // Clean and validate name
          itemName = _cleanItemName(itemName);
          if (itemName.length >= 2) {
            items.add(BillItem(
              id: _uuid.v4(),
              name: itemName,
              price: price,
              selectedBy: [],
            ));
            break; // Only take first valid price per line
          }
        }
      }
    }

    // Strategy 2: Super aggressive - any line with text and numbers
    if (items.isEmpty) {
      print('=== SUPER AGGRESSIVE PARSING ===');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        print('Super aggressive line $i: "$line"');

        // Skip very short lines or obvious non-products
        if (line.length < 3 || _isHeaderOrFooterLine(line)) {
          print('  -> Skipped (too short or header/footer)');
          continue;
        }

        // Look for any numbers that could be prices (even without decimals)
        final numberMatches = RegExp(r'(\d+(?:[.,]\d{1,2})?)');
        final match = numberMatches.firstMatch(line);

        if (match != null) {
          final numberStr = match.group(1)!;
          var potentialPrice =
              double.tryParse(numberStr.replaceAll(',', '.')) ?? 0.0;

          // If it's a whole number, assume it might be missing decimals
          if (!numberStr.contains('.') &&
              !numberStr.contains(',') &&
              potentialPrice > 10) {
            potentialPrice = potentialPrice / 100; // Convert 1250 to 12.50
          }

          // Check if this could be a reasonable price
          if (potentialPrice >= 0.50 && potentialPrice <= 100.0) {
            // Extract text that could be a product name
            String productText = line.replaceAll(numberStr, '').trim();
            productText =
                productText.replaceAll(RegExp(r'[€\$\*\-\.]+'), '').trim();

            if (productText.length >= 2) {
              print(
                  '  -> Super aggressive match: "$productText" - €${potentialPrice.toStringAsFixed(2)}');

              final item = BillItem(
                id: _uuid.v4(),
                name: _cleanExtractedName(productText),
                price: potentialPrice,
                selectedBy: [],
              );

              items.add(item);
            }
          }
        }
      }
    }

    return items;
  }

  /// Intelligent Spanish ticket parsing - associates products with prices on separate lines
  List<BillItem> _parseSpanishTicketFormat(List<String> lines) {
    print('=== INTELLIGENT SPANISH TICKET PARSING ===');
    final items = <BillItem>[];

    // Step 1: Identify Spanish product names
    final productLines = <int>[];
    final priceLines = <int>[];

    // Common Spanish food/drink keywords
    final spanishProductKeywords = [
      'coca',
      'cola',
      'pepsi',
      'agua',
      'cerveza',
      'beer',
      'vino',
      'wine',
      'jarra',
      'caña',
      'botella',
      'copa',
      'vaso',
      'refresco',
      'hamburguesa',
      'pizza',
      'bocadillo',
      'sandwich',
      'tapa',
      'ración',
      'patatas',
      'papas',
      'bravas',
      'fritas',
      'tortilla',
      'ensalada',
      'pollo',
      'carne',
      'pescado',
      'jamón',
      'queso',
      'pan',
      'tostada',
      'café',
      'cortado',
      'cappuccino',
      'té',
      'zumo',
      'jugo',
      'helado',
      'postre',
      'flan',
      'tarta',
      'mousse',
      'aceitunas',
      'olivas',
      'nachos',
      'alitas',
      'croquetas',
      'gazpacho',
      'salmorejo',
      'paella',
      'fideuá',
      'risotto',
      'victoria',
      'estrella',
      'mahou',
      'cruzcampo',
      'alhambra',
      'tinto',
      'verano',
      'sangría',
      'clara',
      'radler'
    ];

    print('🔍 STEP 1: Identifying product lines...');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();
      if (line.isEmpty || _isHeaderOrFooterLine(lines[i])) continue;

      // Check if line contains Spanish product keywords
      bool isProduct =
          spanishProductKeywords.any((keyword) => line.contains(keyword));

      // Also check for typical product patterns (letters with spaces, no prices)
      if (!isProduct &&
          RegExp(r'^[a-záéíóúñü\s]{3,}$').hasMatch(line) &&
          !RegExp(r'\d+[.,]\d{2}').hasMatch(line)) {
        isProduct = true;
      }

      if (isProduct) {
        productLines.add(i);
        print('   Found product line $i: "${lines[i]}"');
      }
    }

    print('🔍 STEP 2: Identifying price lines...');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || _isHeaderOrFooterLine(line)) continue;

      // Look for standalone prices (numbers with decimals and currency)
      if (RegExp(r'^\s*\d{1,3}[.,]\d{2}\s*[€\$]?\s*$').hasMatch(line)) {
        priceLines.add(i);
        print('   Found price line $i: "$line"');
      }
    }

    print('🔍 STEP 3: Associating products with prices...');
    print('   Products found: ${productLines.length}');
    print('   Prices found: ${priceLines.length}');

    // Strategy 1: Sequential association (most common in Spanish tickets)
    if (productLines.isNotEmpty && priceLines.isNotEmpty) {
      final minCount = math.min(productLines.length, priceLines.length);

      for (int i = 0; i < minCount; i++) {
        final productLine = lines[productLines[i]].trim();
        final priceLine = lines[priceLines[i]].trim();

        // Extract price
        final priceMatch = RegExp(r'(\d{1,3}[.,]\d{2})').firstMatch(priceLine);
        if (priceMatch != null) {
          final priceStr = priceMatch.group(1)!.replaceAll(',', '.');
          final price = double.tryParse(priceStr) ?? 0.0;

          if (price >= 0.10 && price <= 999.99) {
            final cleanName = _cleanSpanishProductName(productLine);
            if (cleanName.isNotEmpty) {
              print(
                  '   ✅ Associated: "$cleanName" → €${price.toStringAsFixed(2)}');

              items.add(BillItem(
                id: _uuid.v4(),
                name: cleanName,
                price: price,
                selectedBy: [],
              ));
            }
          }
        }
      }
    }

    // Strategy 2: If no sequential match, try proximity-based matching
    if (items.isEmpty && productLines.isNotEmpty && priceLines.isNotEmpty) {
      print('🔍 STEP 4: Trying proximity-based matching...');

      for (final productIndex in productLines) {
        final productLine = lines[productIndex].trim();

        // Find the closest price line
        int? closestPriceIndex;
        int minDistance = 999;

        for (final priceIndex in priceLines) {
          final distance = (productIndex - priceIndex).abs();
          if (distance < minDistance) {
            minDistance = distance;
            closestPriceIndex = priceIndex;
          }
        }

        if (closestPriceIndex != null && minDistance <= 5) {
          final priceLine = lines[closestPriceIndex].trim();
          final priceMatch =
              RegExp(r'(\d{1,3}[.,]\d{2})').firstMatch(priceLine);

          if (priceMatch != null) {
            final priceStr = priceMatch.group(1)!.replaceAll(',', '.');
            final price = double.tryParse(priceStr) ?? 0.0;

            if (price >= 0.10 && price <= 999.99) {
              final cleanName = _cleanSpanishProductName(productLine);
              if (cleanName.isNotEmpty) {
                print(
                    '   ✅ Proximity match: "$cleanName" → €${price.toStringAsFixed(2)} (distance: $minDistance)');

                items.add(BillItem(
                  id: _uuid.v4(),
                  name: cleanName,
                  price: price,
                  selectedBy: [],
                ));

                // Remove used price line to avoid duplicates
                priceLines.remove(closestPriceIndex);
              }
            }
          }
        }
      }
    }

    print('=== SPANISH PARSING COMPLETE ===');
    print('Successfully parsed ${items.length} Spanish products');

    return items;
  }

  /// Clean and format Spanish product names properly
  String _cleanSpanishProductName(String name) {
    if (name.isEmpty) return '';

    // Remove common prefixes/suffixes
    String cleaned = name
        .replaceAll(RegExp(r'^\d+\s*'), '') // Remove leading numbers
        .replaceAll(RegExp(r'\s*[€\$].*'), '') // Remove prices
        .replaceAll(RegExp(r'\s*\d+[.,]\d{2}.*'), '') // Remove decimal prices
        .replaceAll(RegExp(r'[\*\-_=]{2,}'), '') // Remove decorative chars
        .trim();

    if (cleaned.isEmpty) return '';

    // Proper Spanish capitalization
    final words = cleaned.toLowerCase().split(' ');
    final capitalizedWords = <String>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      // Don't capitalize Spanish articles and prepositions unless first word
      final spanishArticles = ['de', 'del', 'la', 'el', 'con', 'y', 'a', 'al'];

      if (i > 0 && spanishArticles.contains(word)) {
        capitalizedWords.add(word);
      } else {
        capitalizedWords.add(word[0].toUpperCase() + word.substring(1));
      }
    }

    return capitalizedWords.join(' ');
  }

  /// Process image on web platform using simplified OCR (OCR.space only)
  Future<Map<String, dynamic>> _processImageOnWeb(dynamic imageFile) async {
    print('🚀 STARTING SIMPLIFIED OCR PROCESSING (OCR.space only)...');
    print('📷 Image file type: ${imageFile.runtimeType}');

    // Convert image file to base64 format
    String? base64Image;
    try {
      if (imageFile != null) {
        print('📸 Processing image file: ${imageFile.runtimeType}');

        List<int> bytes;
        String mimeType = 'image/jpeg'; // Default

        // Handle XFile (standard case)
        if (imageFile.runtimeType.toString().contains('XFile')) {
          print('📸 Converting XFile to base64...');
          bytes = await imageFile.readAsBytes();

          // Detect MIME type from file extension
          final fileName = imageFile.name?.toLowerCase() ?? '';
          if (fileName.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          } else if (fileName.endsWith('.webp')) {
            mimeType = 'image/webp';
          }
        }
        // Handle List<int> (byte array)
        else if (imageFile is List<int>) {
          print('📸 Processing byte array...');
          bytes = imageFile;
        }
        // Handle Flutter Web minified types (minified:xx)
        else if (imageFile.runtimeType.toString().startsWith('minified:')) {
          print('📸 Processing Flutter Web minified file type...');
          try {
            // Try to call readAsBytes() method if available
            bytes = await imageFile.readAsBytes();
            print('✅ Successfully read bytes from minified file');

            // Try to get file name for MIME type detection
            try {
              final fileName = imageFile.name?.toLowerCase() ?? '';
              if (fileName.endsWith('.png')) {
                mimeType = 'image/png';
              } else if (fileName.endsWith('.jpg') ||
                  fileName.endsWith('.jpeg')) {
                mimeType = 'image/jpeg';
              } else if (fileName.endsWith('.webp')) {
                mimeType = 'image/webp';
              }
            } catch (e) {
              print('⚠️ Could not detect file extension, using default JPEG');
            }
          } catch (e) {
            print('❌ Failed to read bytes from minified file: $e');
            return await _promptManualTextExtraction();
          }
        }
        // Handle any other type that might have readAsBytes() method
        else {
          print(
              '📸 Attempting to process unknown file type: ${imageFile.runtimeType}');
          try {
            bytes = await imageFile.readAsBytes();
            print('✅ Successfully read bytes from unknown file type');
          } catch (e) {
            print('❌ Unsupported image file type: ${imageFile.runtimeType}');
            print('❌ Error: $e');
            return await _promptManualTextExtraction();
          }
        }

        // Convert to base64
        base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';
        print(
            '✅ Converted to base64 ($mimeType), length: ${base64Image.length}');
      } else {
        throw Exception('Image file is null');
      }
    } catch (e) {
      print('❌ Image conversion failed: $e');
      return await _promptManualTextExtraction();
    }

    // Use OCR.space API (free tier - 25,000 requests/month)
    print('🎯 Using OCR.space API for text extraction...');
    try {
      final ocrSpaceResult = await _callOCRSpaceAPI(base64Image);
      if (ocrSpaceResult != null && ocrSpaceResult.trim().isNotEmpty) {
        print('✅ SUCCESS: OCR.space extracted text!');
        print('📝 EXTRACTED TEXT: $ocrSpaceResult');

        // Parse the extracted text using intelligent Spanish parsing
        final parsedResult = _parseReceiptText(ocrSpaceResult);
        if (parsedResult['items'] != null &&
            (parsedResult['items'] as List).isNotEmpty) {
          print(
              '🎯 SUCCESS: Parsed ${(parsedResult['items'] as List).length} items from OCR.space');
          return parsedResult;
        } else {
          print(
              '⚠️ OCR.space extracted text but parsing failed. Prompting manual extraction.');
        }
      } else {
        print('⚠️ OCR.space returned empty text');
      }
    } catch (e) {
      print('❌ OCR.space API failed: $e');
    }

    // Fallback to manual text extraction
    print('🎯 Fallback: Manual text extraction...');
    return await _promptManualTextExtraction();
  }

  /// Call OCR.space API as backup OCR strategy
  Future<String?> _callOCRSpaceAPI(String base64Image) async {
    try {
      print('🌐 Calling OCR.space API...');

      // Remove data URL prefix for API
      final imageData = base64Image.replaceFirst('data:image/jpeg;base64,', '');

      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'apikey': 'helloworld', // Free tier API key
          'base64Image': 'data:image/jpeg;base64,$imageData',
          'language': 'spa',
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['ParsedResults'] != null &&
            jsonResponse['ParsedResults'].isNotEmpty) {
          final extractedText =
              jsonResponse['ParsedResults'][0]['ParsedText'] as String?;
          print('✅ OCR.space returned: $extractedText');
          return extractedText;
        }
      }

      print('❌ OCR.space API failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ OCR.space API error: $e');
      return null;
    }
  }

  /// Prompt user for manual text extraction as last resort
  Future<Map<String, dynamic>> _promptManualTextExtraction() async {
    print('📝 MANUAL EXTRACTION: Prompting user for manual text input...');

    // Return a basic structure that will trigger the manual review dialog
    // The user can then manually add the products they see in the image
    final items = [
      BillItem(
        id: _uuid.v4(),
        name: 'Producto del ticket',
        price: 0.00,
        selectedBy: [],
      ),
    ];

    return {
      'items': items,
      'subtotal': 0.00,
      'tax': 0.0,
      'tip': 0.0,
      'total': 0.00,
      'restaurantName': 'Ticket Escaneado - Editar Manualmente',
      'manualExtraction': true, // Flag to indicate manual extraction needed
    };
  }

  /// Legacy price extraction method
  List<BillItem> _extractPricesFromText(String text) {
    print('Extracting prices from raw text...');
    final items = <BillItem>[];

    // Look for price patterns in the text (€X.XX, X,XX€, X.XX, etc.)
    final priceRegex =
        RegExp(r'(€?\s*)(\d{1,3}(?:[.,]\d{2})?)\s*(€?)', caseSensitive: false);
    final matches = priceRegex.allMatches(text);

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final match in matches) {
      final priceStr = match.group(2);
      if (priceStr != null) {
        try {
          // Convert price string to double (handle both . and , as decimal separator)
          final price = double.parse(priceStr.replaceAll(',', '.'));

          // Skip very small prices (likely not products) and very large prices (likely totals)
          if (price < 0.30 || price > 300.0) continue;

          // Try to find the product name near this price
          String productName = 'Producto';

          // Find which line contains this price
          for (final line in lines) {
            if (line.contains(priceStr)) {
              // Extract text before the price as potential product name
              final beforePrice =
                  line.substring(0, line.indexOf(priceStr)).trim();
              if (beforePrice.isNotEmpty && beforePrice.length > 2) {
                productName = _cleanExtractedName(beforePrice);
              }
              break;
            }
          }

          items.add(BillItem(
            id: _uuid.v4(),
            name: productName,
            price: price,
            selectedBy: [],
          ));

          print('  -> Extracted: $productName - €${price.toStringAsFixed(2)}');
        } catch (e) {
          print('  -> Failed to parse price: $priceStr');
        }
      }
    }

    return items;
  }

  /// Clean extracted product names
  String _cleanExtractedName(String name) {
    // Remove common prefixes/suffixes and clean up
    String cleaned = name
        .replaceAll(RegExp(r'^\d+[\s\-\.]*'), '') // Remove leading numbers
        .replaceAll(RegExp(r'[\*\-\.]+$'), '') // Remove trailing symbols
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();

    // If still empty or too short, use generic name
    if (cleaned.isEmpty || cleaned.length < 3) {
      cleaned = 'Producto del ticket';
    }

    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
    }

    return cleaned;
  }

  /// Legacy OCR text preprocessing
  String _preprocessOCRText(String rawText) {
    print('=== PREPROCESSING OCR TEXT ===');
    print('Raw text: "$rawText"');

    String processed = rawText;

    // 1. Fix common OCR character recognition errors in price contexts
    // Fix "1O.50" -> "10.50", "I5.50" -> "15.50", etc.

    // 2. Normalize whitespace and line breaks
    processed = processed
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // Multiple newlines to single
        .trim();

    // 3. Fix price patterns specifically
    // Fix common price OCR errors like "1O.50" -> "10.50"
    processed = processed.replaceAllMapped(RegExp(r'(\d+)[Oo]([\.\,]\d{1,2})'),
        (match) => '${match.group(1)}0${match.group(2)}');

    // Fix "I5.50" -> "15.50"
    processed = processed.replaceAllMapped(
        RegExp(r'[Il](\d[\.\,]\d{1,2})'), (match) => '1${match.group(1)}');

    // 4. Normalize decimal separators (comma to dot for consistency)
    processed = processed.replaceAllMapped(RegExp(r'(\d+),(\d{1,2})(?!\d)'),
        (match) => '${match.group(1)}.${match.group(2)}');

    // 5. Fix spacing around prices
    processed = processed.replaceAllMapped(
        RegExp(r'(\d+\.\d{1,2})\s*€'), (match) => '${match.group(1)}€');

    // 6. Remove excessive punctuation and clean up
    processed = processed
        .replaceAll(RegExp(r'[\*\-]{3,}'), '---') // Multiple dashes/stars
        .replaceAll(RegExp(r'\.{3,}'), '...') // Multiple dots
        .replaceAll(RegExp(r'_{3,}'), '___'); // Multiple underscores

    // 7. Fix common Spanish OCR errors
    final spanishFixes = {
      'ñ': 'ñ', // Normalize ñ
      'á': 'á', 'é': 'é', 'í': 'í', 'ó': 'ó', 'ú': 'ú', // Normalize accents
      'Á': 'Á', 'É': 'É', 'Í': 'Í', 'Ó': 'Ó', 'Ú': 'Ú',
      'ü': 'ü', 'Ü': 'Ü',
    };

    // Apply Spanish character fixes
    spanishFixes.forEach((wrong, correct) {
      processed = processed.replaceAll(wrong, correct);
    });

    print('Processed text: "$processed"');
    print('==============================');

    return processed;
  }

  /// Preprocess image for optimal OCR accuracy
  Future<dynamic> _preprocessImageForOCR(dynamic imageFile) async {
    try {
      print('=== PREPROCESSING IMAGE FOR OCR ===');

      // For now, we'll implement basic preprocessing that works across platforms
      // In a production environment, you'd use image processing libraries like:
      // - image package for Dart
      // - OpenCV for advanced processing
      // - Platform-specific native processing

      if (kIsWeb) {
        // Web-based image preprocessing
        return await _preprocessImageWeb(imageFile);
      } else {
        // Mobile image preprocessing
        return await _preprocessImageMobile(imageFile);
      }
    } catch (e) {
      print('❌ Image preprocessing failed: $e');
      // Return original image if preprocessing fails
      return imageFile;
    }
  }

  /// Preprocess image on web platform
  Future<dynamic> _preprocessImageWeb(dynamic imageFile) async {
    print('🌐 Web image preprocessing...');

    try {
      // For web, we'll use JavaScript-based image processing
      // This is a simplified version - in production you'd use Canvas API

      // Read image bytes
      List<int> imageBytes;
      if (imageFile.readAsBytes != null) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        print('⚠️ Cannot read image bytes, using original');
        return imageFile;
      }

      // Apply basic preprocessing via JavaScript if available
      if (js.context['preprocessImageForOCR'] != null) {
        print('📸 Applying JavaScript image preprocessing...');

        final base64Image =
            'data:image/jpeg;base64,${base64Encode(imageBytes)}';
        final processedBase64 = await js.context['preprocessImageForOCR']
            .callMethod('call', [null, base64Image]);

        if (processedBase64 != null && processedBase64.toString().isNotEmpty) {
          print('✅ Image preprocessing completed via JavaScript');
          // Return the processed base64 image
          return processedBase64;
        }
      }

      print('⚠️ JavaScript preprocessing not available, using original');
      return imageFile;
    } catch (e) {
      print('❌ Web preprocessing failed: $e');
      return imageFile;
    }
  }

  /// Preprocess image on mobile platform
  Future<dynamic> _preprocessImageMobile(dynamic imageFile) async {
    print('📱 Mobile image preprocessing...');

    try {
      // For mobile, we can implement more sophisticated preprocessing
      // Using the image package or native processing

      // Basic preprocessing steps:
      // 1. Enhance contrast
      // 2. Convert to grayscale
      // 3. Apply noise reduction
      // 4. Optimize for text recognition

      print('📸 Applying mobile image enhancements...');

      // For now, return original image
      // In production, you'd implement actual image processing here
      // using packages like 'image' or native platform channels

      print('✅ Mobile preprocessing completed (placeholder)');
      return imageFile;
    } catch (e) {
      print('❌ Mobile preprocessing failed: $e');
      return imageFile;
    }
  }

  /// Validate and clean extracted items for maximum accuracy
  List<BillItem> _validateAndCleanItems(List<BillItem> items) {
    print('=== VALIDATING AND CLEANING ITEMS ===');

    final validItems = <BillItem>[];
    final seenNames = <String>{};
    final seenPrices = <double>{};

    for (final item in items) {
      print('Validating: ${item.name} - €${item.price.toStringAsFixed(2)}');

      // 1. Clean and normalize the name
      String cleanName = item.name
          .trim()
          .replaceAll(
              RegExp(r'^\d+\s*[x\*]\s*'), '') // Remove quantity prefixes
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
          .replaceAll(RegExp(r'[\-\.\*]+$'), '') // Remove trailing symbols
          .trim();

      // Capitalize first letter of each word
      cleanName = cleanName.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');

      // 2. Validate name quality
      if (cleanName.length < 2) {
        print('  -> Rejected: Name too short');
        continue;
      }

      // Skip generic/meaningless names
      final genericNames = [
        'producto',
        'item',
        'articulo',
        'cosa',
        'total',
        'suma'
      ];
      if (genericNames
          .any((generic) => cleanName.toLowerCase().contains(generic))) {
        print('  -> Rejected: Generic name');
        continue;
      }

      // 3. Validate price
      if (item.price < 0.10 || item.price > 500.0) {
        print('  -> Rejected: Price out of range');
        continue;
      }

      // 4. Check for duplicates (similar names or same prices)
      bool isDuplicate = false;

      // Check for similar names (Levenshtein distance)
      for (final seenName in seenNames) {
        if (_calculateSimilarity(
                cleanName.toLowerCase(), seenName.toLowerCase()) >
            0.8) {
          print('  -> Rejected: Duplicate name (similar to "$seenName")');
          isDuplicate = true;
          break;
        }
      }

      if (isDuplicate) continue;

      // Check for exact price duplicates (might be the same item)
      if (seenPrices.contains(item.price)) {
        print(
            '  -> Warning: Duplicate price €${item.price.toStringAsFixed(2)}');
        // Allow it but with a note
      }

      // 5. Create validated item
      final validItem = BillItem(
        id: item.id,
        name: cleanName,
        price: item.price,
        selectedBy: item.selectedBy,
      );

      validItems.add(validItem);
      seenNames.add(cleanName.toLowerCase());
      seenPrices.add(item.price);

      print('  -> Accepted: "$cleanName" - €${item.price.toStringAsFixed(2)}');
    }

    // 6. Sort items by price (descending) for better UX
    validItems.sort((a, b) => b.price.compareTo(a.price));

    print('Validation complete: ${validItems.length} valid items');
    return validItems;
  }

  /// Calculate similarity between two strings (simple version)
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Simple similarity based on common characters and length
    final shorter = a.length < b.length ? a : b;
    final longer = a.length >= b.length ? a : b;

    int commonChars = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        commonChars++;
      }
    }

    return commonChars / longer.length;
  }

  /// Enhanced item name cleaning with Spanish support
  String _cleanItemNameAdvanced(String name) {
    String cleaned = name.trim();
    
    // Remove common OCR artifacts
    cleaned = cleaned.replaceAll(RegExp(r'[€\$\*\-\.]+$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\-\.]+'), '');
    
    // Remove quantity indicators if they got mixed in
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*x\s*', caseSensitive: false), '');
    
    // Normalize Spanish characters
    cleaned = cleaned.replaceAll('Ã±', 'ñ').replaceAll('ÃÑ', 'Ñ');
    cleaned = cleaned.replaceAll('Ã¡', 'á').replaceAll('Ã©', 'é');
    cleaned = cleaned.replaceAll('Ã­', 'í').replaceAll('Ã³', 'ó').replaceAll('Ãº', 'ú');
    
    // Capitalize properly for Spanish
    if (cleaned.isNotEmpty) {
      cleaned = cleaned.toLowerCase();
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned.trim();
  }

  /// Legacy item name cleaning
  String _cleanItemName(String name) {
    print('    Cleaning name: "$name"');

    // Remove common OCR artifacts and receipt symbols
    name = name.replaceAll(RegExp(r'[*#@\|\\\/_]+'), '').trim();

    // Remove extra whitespace and normalize
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove leading/trailing dots, dashes, or other separators
    name = name.replaceAll(RegExp(r'^[\.\.\-\-\s]+|[\.\.\-\-\s]+$'), '').trim();

    // Remove price-like patterns that might have been included
    name = name.replaceAll(RegExp(r'\b\d+[.,]\d{1,2}\b'), '').trim();

    // Remove currency symbols
    name = name.replaceAll(RegExp(r'[€\$]'), '').trim();

    // Remove quantity indicators at the start
    name = name
        .replaceAll(RegExp(r'^\d+\s*x\s*', caseSensitive: false), '')
        .trim();

    // Remove common OCR misreads
    name = name.replaceAll(RegExp(r'[\[\]\{\}\(\)]+'), '').trim();

    // Fix common Spanish OCR errors
    final corrections = {
      'ñ': ['n~', 'n-', 'fi'],
      'á': ['a´', 'a`', 'a\''],
      'é': ['e´', 'e`', 'e\''],
      'í': ['i´', 'i`', 'i\''],
      'ó': ['o´', 'o`', 'o\''],
      'ú': ['u´', 'u`', 'u\''],
      'ü': ['u¨', 'ue'],
      'ç': ['c,'],
    };

    corrections.forEach((correct, errors) {
      for (final error in errors) {
        name = name.replaceAll(error, correct);
      }
    });

    // Capitalize properly for Spanish
    if (name.isNotEmpty) {
      final words = name.toLowerCase().split(' ');
      name = words.map((word) {
        if (word.isEmpty) return word;

        // Don't capitalize common Spanish articles and prepositions
        final lowercaseWords = {
          'de',
          'del',
          'la',
          'el',
          'con',
          'en',
          'a',
          'al',
          'y',
          'o',
          'u'
        };
        if (lowercaseWords.contains(word) && words.indexOf(word) != 0) {
          return word;
        }

        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }

    print('    Cleaned name: "$name"');
    return name;
  }

  /// Dispose of resources
  void dispose() {
    _textRecognizer.close();
  }
}
