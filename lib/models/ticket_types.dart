/// Tipos de tickets soportados por el sistema OCR universal
enum TicketType {
  restaurant,
  supermarket,
  pharmacy,
  gasStation,
  clothing,
  electronics,
  bakery,
  unknown
}

/// Extensión para obtener información sobre cada tipo de ticket
extension TicketTypeExtension on TicketType {
  String get displayName {
    switch (this) {
      case TicketType.restaurant:
        return 'Restaurante/Bar';
      case TicketType.supermarket:
        return 'Supermercado';
      case TicketType.pharmacy:
        return 'Farmacia';
      case TicketType.gasStation:
        return 'Gasolinera';
      case TicketType.clothing:
        return 'Tienda de Ropa';
      case TicketType.electronics:
        return 'Electrónica';
      case TicketType.bakery:
        return 'Panadería';
      case TicketType.unknown:
        return 'Desconocido';
    }
  }

  /// Rango de precios típicos para cada tipo de establecimiento
  PriceRange get typicalPriceRange {
    switch (this) {
      case TicketType.restaurant:
        return PriceRange(min: 1.0, max: 150.0);
      case TicketType.supermarket:
        return PriceRange(min: 0.10, max: 500.0);
      case TicketType.pharmacy:
        return PriceRange(min: 0.50, max: 200.0);
      case TicketType.gasStation:
        return PriceRange(min: 5.0, max: 200.0);
      case TicketType.clothing:
        return PriceRange(min: 2.0, max: 1000.0);
      case TicketType.electronics:
        return PriceRange(min: 5.0, max: 5000.0);
      case TicketType.bakery:
        return PriceRange(min: 0.50, max: 50.0);
      case TicketType.unknown:
        return PriceRange(min: 0.10, max: 1000.0);
    }
  }

  /// Patrones de palabras clave para identificar el tipo de ticket
  List<String> get keywordPatterns {
    switch (this) {
      case TicketType.restaurant:
        return [
          'restaurante', 'bar', 'cafeteria', 'taberna', 'terraza',
          'menu', 'bebida', 'cerveza', 'vino', 'copa', 'tapa',
          'plato', 'ración', 'camarero', 'mesa', 'comida'
        ];
      case TicketType.supermarket:
        return [
          'supermercado', 'hipermercado', 'mercadona', 'carrefour',
          'alcampo', 'lidl', 'dia', 'eroski', 'auchan', 'simply',
          'producto', 'oferta', 'descuento', 'kg', 'unidad'
        ];
      case TicketType.pharmacy:
        return [
          'farmacia', 'medicamento', 'medicina', 'pastilla',
          'jarabe', 'crema', 'vitamina', 'paracetamol', 'ibuprofeno'
        ];
      case TicketType.gasStation:
        return [
          'gasolinera', 'combustible', 'gasolina', 'diesel',
          'gasoil', 'litros', 'repsol', 'cepsa', 'bp', 'shell'
        ];
      case TicketType.clothing:
        return [
          'ropa', 'moda', 'zara', 'h&m', 'mango', 'bershka',
          'camiseta', 'pantalon', 'vestido', 'zapatos', 'talla'
        ];
      case TicketType.electronics:
        return [
          'electronica', 'media markt', 'fnac', 'worten',
          'telefono', 'ordenador', 'television', 'auriculares'
        ];
      case TicketType.bakery:
        return [
          'panaderia', 'pan', 'bolleria', 'croissant', 'magdalena',
          'pastel', 'tarta', 'empanada', 'bocadillo'
        ];
      case TicketType.unknown:
        return [];
    }
  }
}

/// Rango de precios para validación
class PriceRange {
  final double min;
  final double max;

  const PriceRange({required this.min, required this.max});

  bool isValidPrice(double price) {
    return price >= min && price <= max;
  }
}
