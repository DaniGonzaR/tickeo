enum PaymentMethod {
  cash,
  card,
  transfer,
  digitalWallet,
  other,
}

class Payment {
  final String id;
  final String participantId;
  final String participantName;
  final double amount;
  final PaymentMethod method;
  final bool isPaid;
  final DateTime? paidAt;
  final String? notes;

  Payment({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.amount,
    required this.method,
    this.isPaid = false,
    this.paidAt,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      participantId: json['participantId'] ?? '',
      participantName: json['participantName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['method']}',
        orElse: () => PaymentMethod.cash,
      ),
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'amount': amount,
      'method': method.toString().split('.').last,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }

  Payment copyWith({
    String? id,
    String? participantId,
    String? participantName,
    double? amount,
    PaymentMethod? method,
    bool? isPaid,
    DateTime? paidAt,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
    );
  }

  String get methodDisplayName {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.digitalWallet:
        return 'Billetera Digital';
      case PaymentMethod.other:
        return 'Otro';
    }
  }
}
