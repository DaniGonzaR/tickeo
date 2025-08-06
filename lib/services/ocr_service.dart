import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:uuid/uuid.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final Uuid _uuid = const Uuid();

  Future<Map<String, dynamic>> processReceiptImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return _parseReceiptText(recognizedText.text);
    } catch (e) {
      throw Exception('Error procesando la imagen: $e');
    }
  }

  Map<String, dynamic> _parseReceiptText(String text) {
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    List<BillItem> items = [];
    double subtotal = 0.0;
    double tax = 0.0;
    double total = 0.0;
    String? restaurantName;

    // Patrones de regex mejorados para español
    final pricePattern = RegExp(
        r'[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})|[\$]?(\d+[.,]\d{2})|[\$]?(\d+)');
    final totalPattern = RegExp(
        r'(total|suma|importe|monto|pagar|cobrar)\s*:?\s*[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)',
        caseSensitive: false);
    final taxPattern = RegExp(
        r'(tax|iva|impuesto|gravamen)\s*:?\s*[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)',
        caseSensitive: false);
    final subtotalPattern = RegExp(
        r'(subtotal|sub-total|sub total|neto)\s*:?\s*[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)',
        caseSensitive: false);

    // Patrones más flexibles para items
    final itemPatterns = [
      RegExp(
          r'^(.+?)\s+[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)$'),
      RegExp(
          r'^(\d+)\s*x\s*(.+?)\s+[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)$'),
      RegExp(
          r'^(.+?)\s*-\s*[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)$'),
      RegExp(
          r'^(.+?)\s*\.\s*[\$]?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)$'),
    ];

    // Buscar nombre del restaurante (mejorado)
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();
      if (line.length > 3 &&
          line.length < 50 &&
          !pricePattern.hasMatch(line) &&
          !_containsCommonReceiptWords(line) &&
          !RegExp(r'^\d+$').hasMatch(line)) {
        restaurantName = line;
        break;
      }
    }

    // Procesar cada línea
    for (String line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      // Buscar total
      final totalMatch = totalPattern.firstMatch(cleanLine);
      if (totalMatch != null) {
        final totalStr = totalMatch.group(2) ?? '0';
        total = _parsePrice(totalStr);
        continue;
      }

      // Buscar subtotal
      final subtotalMatch = subtotalPattern.firstMatch(cleanLine);
      if (subtotalMatch != null) {
        final subtotalStr = subtotalMatch.group(2) ?? '0';
        subtotal = _parsePrice(subtotalStr);
        continue;
      }

      // Buscar impuestos
      final taxMatch = taxPattern.firstMatch(cleanLine);
      if (taxMatch != null) {
        final taxStr = taxMatch.group(2) ?? '0';
        tax = _parsePrice(taxStr);
        continue;
      }

      // Buscar items con diferentes patrones
      bool itemFound = false;
      for (final pattern in itemPatterns) {
        final itemMatch = pattern.firstMatch(cleanLine);
        if (itemMatch != null) {
          String itemName;
          String priceStr;
          int quantity = 1;

          if (itemMatch.groupCount >= 3) {
            // Patrón con cantidad
            quantity = int.tryParse(itemMatch.group(1) ?? '1') ?? 1;
            itemName = itemMatch.group(2)?.trim() ?? '';
            priceStr = itemMatch.group(3) ?? '0';
          } else {
            // Patrón simple
            itemName = itemMatch.group(1)?.trim() ?? '';
            priceStr = itemMatch.group(2) ?? '0';
          }

          final itemPrice = _parsePrice(priceStr);

          if (itemName.isNotEmpty &&
              itemPrice > 0 &&
              !_isLikelyNotProduct(itemName)) {
            items.add(BillItem(
              id: _uuid.v4(),
              name: _cleanItemName(itemName),
              price: itemPrice,
              quantity: quantity,
              selectedBy: [],
            ));
            itemFound = true;
            break;
          }
        }
      }
    }

    // Calcular subtotal si no se encontró
    if (subtotal == 0.0 && items.isNotEmpty) {
      subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    }

    // Calcular total si no se encontró
    if (total == 0.0) {
      total = subtotal + tax;
    }

    // Si el subtotal calculado no coincide, usar el encontrado
    if (subtotal > 0 && total > subtotal) {
      // El subtotal del ticket es correcto, recalcular items si es necesario
      final calculatedSubtotal =
          items.fold(0.0, (sum, item) => sum + item.totalPrice);
      if ((calculatedSubtotal - subtotal).abs() > 0.01) {
        // Hay discrepancia, confiar en el subtotal del ticket
        subtotal = calculatedSubtotal;
      }
    }

    return {
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'restaurantName': restaurantName,
    };
  }

  double _parsePrice(String priceStr) {
    try {
      // Limpiar el string de precio
      String cleanPrice = priceStr
          .replaceAll(RegExp(r'[^\d.,]'),
              '') // Remover todo excepto dígitos, comas y puntos
          .trim();

      // Manejar formato con separadores de miles
      if (cleanPrice.contains(',') && cleanPrice.contains('.')) {
        // Formato: 1,234.56 o 1.234,56
        final lastComma = cleanPrice.lastIndexOf(',');
        final lastDot = cleanPrice.lastIndexOf('.');

        if (lastDot > lastComma) {
          // Formato: 1,234.56
          cleanPrice = cleanPrice.replaceAll(',', '');
        } else {
          // Formato: 1.234,56
          cleanPrice = cleanPrice.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (cleanPrice.contains(',')) {
        // Solo comas - puede ser separador de miles o decimales
        final parts = cleanPrice.split(',');
        if (parts.length == 2 && parts[1].length <= 2) {
          // Probablemente decimales
          cleanPrice = cleanPrice.replaceAll(',', '.');
        } else {
          // Probablemente separador de miles
          cleanPrice = cleanPrice.replaceAll(',', '');
        }
      }

      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  bool _containsCommonReceiptWords(String text) {
    final lowercaseText = text.toLowerCase();
    final commonWords = [
      'ticket',
      'factura',
      'recibo',
      'comprobante',
      'fecha',
      'date',
      'hora',
      'time',
      'cajero',
      'cashier',
      'vendedor',
      'gracias',
      'thank',
      'vuelva',
      'visit',
      'rfc',
      'nit',
      'cuit',
      'tel',
      'phone',
    ];

    return commonWords.any((word) => lowercaseText.contains(word));
  }

  bool _isLikelyNotProduct(String text) {
    final lowercaseText = text.toLowerCase();
    final excludePatterns = [
      // Totales y subtotales
      'subtotal', 'sub-total', 'sub total',
      'total', 'suma', 'importe', 'monto',
      'neto', 'bruto',

      // Impuestos
      'tax', 'iva', 'impuesto', 'gravamen',
      'igv', 'itbis', 'iva incluido',

      // Propinas y descuentos
      'propina', 'tip', 'servicio',
      'descuento', 'discount', 'rebaja',
      'oferta', 'promocion',

      // Pagos
      'cambio', 'change', 'vuelto',
      'efectivo', 'cash', 'tarjeta', 'card',
      'credito', 'debito', 'transferencia',

      // Información del establecimiento
      'fecha', 'date', 'hora', 'time',
      'mesa', 'table', 'orden', 'order',
      'mesero', 'waiter', 'cajero', 'cashier',
      'ticket', 'factura', 'recibo',

      // Agradecimientos
      'gracias', 'thank', 'buen', 'good',
      'vuelva', 'visit', 'pronto', 'again',

      // Información fiscal
      'rfc', 'nit', 'cuit', 'regimen',
      'contribuyente', 'fiscal',

      // Otros
      'folio', 'numero', 'no.', '#',
      'tel', 'phone', 'direccion', 'address',
    ];

    return excludePatterns.any((pattern) => lowercaseText.contains(pattern)) ||
        RegExp(r'^\d+$').hasMatch(text) || // Solo números
        RegExp(r'^[^\w\s]+$').hasMatch(text); // Solo símbolos
  }

  String _cleanItemName(String name) {
    // Limpiar y normalizar nombre del producto
    return name
        .replaceAll(RegExp(r'[^\w\s\-áéíóúñüÁÉÍÓÚÑÜ]'),
            '') // Mantener caracteres en español
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase()
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Future<List<BillItem>> extractItemsFromText(String text) async {
    final result = _parseReceiptText(text);
    return result['items'] as List<BillItem>;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
