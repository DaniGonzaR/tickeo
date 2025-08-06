class BillItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final List<String> selectedBy;
  final String? category;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.selectedBy,
    this.category,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      selectedBy: List<String>.from(json['selectedBy'] ?? []),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'selectedBy': selectedBy,
      'category': category,
    };
  }

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    List<String>? selectedBy,
    String? category,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selectedBy: selectedBy ?? this.selectedBy,
      category: category ?? this.category,
    );
  }

  double get totalPrice => price * quantity;

  bool isSelectedBy(String participantId) {
    return selectedBy.contains(participantId);
  }

  double getPricePerPerson() {
    if (selectedBy.isEmpty) return 0.0;
    return totalPrice / selectedBy.length;
  }
}
