import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/ticket_types.dart';
import 'package:tickeo/models/ocr_models.dart';
import 'package:tickeo/services/ticket_classifier.dart';
import 'package:uuid/uuid.dart';

/// Interfaz base para todos los parsers de tickets
abstract class BaseParser {
  static const Uuid _uuid = Uuid();
  
  /// Tipo de ticket que maneja este parser
  TicketType get supportedType;
  
  /// Parsea el texto OCR y extrae productos
  Future<List<BillItem>> parseTicket(
    MultiEngineOCRResult ocrResult,
    TicketClassificationResult classification,
  );
  
  /// Valida si un precio es razonable para este tipo de ticket
  bool isValidPrice(double price) {
    final range = supportedType.typicalPriceRange;
    return range.isValidPrice(price);
  }
  
  /// Limpia y formatea el nombre de un producto
  String cleanProductName(String name) {
    String cleaned = name.trim();
    
    // Remover prefijos de cantidad (ej: "2x", "3 x")
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*[xX]?\s*'), '');
    
    // Remover códigos de barras al inicio
    cleaned = cleaned.replaceAll(RegExp(r'^\d{8,13}\s*'), '');
    
    // Remover símbolos de moneda y precios
    cleaned = cleaned.replaceAll(RegExp(r'[€$]\s*\d+[.,]\d{2}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\d+[.,]\d{2}\s*[€$]?'), '');
    
    // Remover códigos de IVA (A, B, C)
    cleaned = cleaned.replaceAll(RegExp(r'\s*[ABC]\s*$'), '');
    
    // Remover caracteres especiales al final
    cleaned = cleaned.replaceAll(RegExp(r'[*\-_]+$'), '');
    
    // Capitalizar correctamente
    if (cleaned.isNotEmpty) {
      return cleaned.split(' ')
          .map((word) => word.isNotEmpty 
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '')
          .join(' ')
          .trim();
    }
    
    return cleaned;
  }
  
  /// Extrae precios de una línea de texto
  List<double> extractPricesFromLine(String line) {
    final priceMatches = RegExp(r'(\d{1,4}[.,]\d{2})').allMatches(line);
    return priceMatches.map((match) {
      final priceStr = match.group(1)!.replaceAll(',', '.');
      return double.tryParse(priceStr) ?? 0.0;
    }).where((price) => price > 0 && isValidPrice(price)).toList();
  }
  
  /// Verifica si una línea es un header o footer que debe ignorarse
  bool isHeaderOrFooter(String line) {
    final lower = line.toLowerCase().trim();
    
    // Patrones comunes de headers/footers
    final skipPatterns = [
      // Información del establecimiento
      'establecimiento', 'direccion', 'telefono', 'email', 'web',
      'cif', 'nif', 'registro', 'licencia',
      
      // Información fiscal
      'factura', 'proforma', 'simplificada', 'ticket',
      
      // Totales y resúmenes (se procesan por separado)
      'subtotal', 'total', 'suma', 'importe',
      'base imponible', 'cuota', 'iva', 'impuesto',
      
      // Información de pago
      'efectivo', 'tarjeta', 'cambio', 'devolucion',
      'visa', 'mastercard', 'american express',
      
      // Información temporal
      'fecha', 'hora', 'dia', 'mes', 'año',
      
      // Agradecimientos y despedidas
      'gracias', 'visita', 'vuelva', 'hasta pronto',
      'thank you', 'merci', 'danke',
      
      // Información operacional
      'caja', 'cajero', 'operador', 'vendedor',
      'numero', 'serie', 'folio', 'documento',
    ];
    
    return skipPatterns.any((pattern) => lower.contains(pattern)) ||
           line.length < 2 ||
           RegExp(r'^[\d\s.,€*\-_]+$').hasMatch(line);
  }
  
  /// Crea un BillItem con ID único
  BillItem createBillItem(String name, double price) {
    return BillItem(
      id: _uuid.v4(),
      name: cleanProductName(name),
      price: price,
      selectedBy: [],
    );
  }
  
  /// Estrategia de parsing por defecto - puede ser sobrescrita
  Future<List<BillItem>> defaultParsing(List<String> lines) async {
    final items = <BillItem>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (isHeaderOrFooter(line)) continue;
      
      // Buscar líneas con precios
      final prices = extractPricesFromLine(line);
      if (prices.isNotEmpty) {
        // Extraer nombre del producto removiendo el precio
        String productName = line;
        for (final price in prices) {
          productName = productName.replaceAll(price.toString(), '');
          productName = productName.replaceAll(price.toStringAsFixed(2), '');
        }
        
        productName = cleanProductName(productName);
        
        if (productName.length >= 2) {
          items.add(createBillItem(productName, prices.first));
        }
      }
    }
    
    return items;
  }
}
