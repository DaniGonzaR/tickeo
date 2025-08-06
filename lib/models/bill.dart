import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';

class Bill {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double tip;
  final double total;
  final List<String> participants;
  final List<Payment> payments;
  final String? restaurantName;
  final String? imageUrl;
  final bool isCompleted;
  final String shareCode;

  Bill({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.tip,
    required this.total,
    required this.participants,
    required this.payments,
    this.restaurantName,
    this.imageUrl,
    this.isCompleted = false,
    required this.shareCode,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => BillItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      tip: (json['tip'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      participants: List<String>.from(json['participants'] ?? []),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((payment) => Payment.fromJson(payment))
              .toList() ??
          [],
      restaurantName: json['restaurantName'],
      imageUrl: json['imageUrl'],
      isCompleted: json['isCompleted'] ?? false,
      shareCode: json['shareCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'tip': tip,
      'total': total,
      'participants': participants,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'restaurantName': restaurantName,
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
      'shareCode': shareCode,
    };
  }

  Bill copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<BillItem>? items,
    double? subtotal,
    double? tax,
    double? tip,
    double? total,
    List<String>? participants,
    List<Payment>? payments,
    String? restaurantName,
    String? imageUrl,
    bool? isCompleted,
    String? shareCode,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      participants: participants ?? this.participants,
      payments: payments ?? this.payments,
      restaurantName: restaurantName ?? this.restaurantName,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      shareCode: shareCode ?? this.shareCode,
    );
  }

  double getAmountForParticipant(String participantId) {
    double amount = 0.0;
    for (var item in items) {
      if (item.selectedBy.contains(participantId)) {
        amount += item.price / item.selectedBy.length;
      }
    }

    // Add proportional tax and tip
    if (subtotal > 0) {
      double proportion = amount / subtotal;
      amount += (tax + tip) * proportion;
    }

    return amount;
  }

  bool isParticipantPaid(String participantId) {
    return payments.any(
        (payment) => payment.participantId == participantId && payment.isPaid);
  }

  double getTotalPaid() {
    return payments
        .where((payment) => payment.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double getRemainingAmount() {
    return total - getTotalPaid();
  }
}
