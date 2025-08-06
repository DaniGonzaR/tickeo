import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';

void main() {
  group('Bill Model Tests', () {
    late Bill testBill;
    late List<BillItem> testItems;
    late List<Payment> testPayments;

    setUp(() {
      testItems = [
        BillItem(
          id: '1',
          name: 'Pizza Margherita',
          price: 15.99,
          selectedBy: ['user1', 'user2'],
        ),
        BillItem(
          id: '2',
          name: 'Coca Cola',
          price: 2.50,
          selectedBy: ['user1'],
        ),
        BillItem(
          id: '3',
          name: 'Tiramisu',
          price: 6.00,
          selectedBy: ['user2'],
        ),
      ];

      final payment1 = Payment(
        id: 'payment1',
        participantId: 'user1',
        participantName: 'John',
        amount: 10.75,
        method: PaymentMethod.cash,
        isPaid: true,
        paidAt: DateTime.now(),
      );
      final payment2 = Payment(
        id: 'payment2',
        participantId: 'user2',
        participantName: 'Jane',
        method: PaymentMethod.card,
        amount: 13.74,
        isPaid: false,
      );

      testPayments = [payment1, payment2];

      testBill = Bill(
        id: 'test-bill-1',
        name: 'Test Restaurant Bill',
        createdAt: DateTime(2024, 1, 15, 19, 30),
        items: testItems,
        subtotal: 24.49,
        tax: 2.45,
        tip: 0.0,
        total: 26.94,
        participants: ['user1', 'user2'],
        payments: testPayments,
        restaurantName: 'Test Restaurant',
        shareCode: 'TEST123',
        isCompleted: false,
      );
    });

    test('should create Bill with all required fields', () {
      expect(testBill.id, 'test-bill-1');
      expect(testBill.name, 'Test Restaurant Bill');
      expect(testBill.items.length, 3);
      expect(testBill.participants.length, 2);
      expect(testBill.total, 26.94);
      expect(testBill.isCompleted, false);
    });

    test('should serialize to JSON correctly', () {
      final json = testBill.toJson();
      
      expect(json['id'], 'test-bill-1');
      expect(json['name'], 'Test Restaurant Bill');
      expect(json['subtotal'], 24.49);
      expect(json['tax'], 2.45);
      expect(json['total'], 26.94);
      expect(json['participants'], ['user1', 'user2']);
      expect(json['restaurantName'], 'Test Restaurant');
      expect(json['shareCode'], 'TEST123');
      expect(json['isCompleted'], false);
      expect(json['items'], isA<List>());
      expect(json['payments'], isA<List>());
    });

    test('should deserialize from JSON correctly', () {
      final json = testBill.toJson();
      final deserializedBill = Bill.fromJson(json);
      
      expect(deserializedBill.id, testBill.id);
      expect(deserializedBill.name, testBill.name);
      expect(deserializedBill.subtotal, testBill.subtotal);
      expect(deserializedBill.tax, testBill.tax);
      expect(deserializedBill.total, testBill.total);
      expect(deserializedBill.participants, testBill.participants);
      expect(deserializedBill.restaurantName, testBill.restaurantName);
      expect(deserializedBill.shareCode, testBill.shareCode);
      expect(deserializedBill.isCompleted, testBill.isCompleted);
    });

    test('should handle null values in JSON gracefully', () {
      final jsonWithNulls = {
        'id': null,
        'name': null,
        'createdAt': '2024-01-15T19:30:00.000Z',
        'items': null,
        'subtotal': null,
        'tax': null,
        'tip': null,
        'total': null,
        'participants': null,
        'payments': null,
        'restaurantName': null,
        'imageUrl': null,
        'isCompleted': null,
        'shareCode': null,
      };
      
      final bill = Bill.fromJson(jsonWithNulls);
      
      expect(bill.id, '');
      expect(bill.name, '');
      expect(bill.items, []);
      expect(bill.subtotal, 0.0);
      expect(bill.tax, 0.0);
      expect(bill.tip, 0.0);
      expect(bill.total, 0.0);
      expect(bill.participants, []);
      expect(bill.payments, []);
      expect(bill.restaurantName, null);
      expect(bill.imageUrl, null);
      expect(bill.isCompleted, false);
      expect(bill.shareCode, '');
    });

    test('should copy with new values correctly', () {
      final copiedBill = testBill.copyWith(
        name: 'Updated Restaurant Bill',
        total: 30.00,
        isCompleted: true,
      );
      
      expect(copiedBill.id, testBill.id); // unchanged
      expect(copiedBill.name, 'Updated Restaurant Bill'); // changed
      expect(copiedBill.total, 30.00); // changed
      expect(copiedBill.isCompleted, true); // changed
      expect(copiedBill.subtotal, testBill.subtotal); // unchanged
    });

    test('should calculate amount for participant correctly', () {
      // user1: Pizza (15.99/2) + Coca Cola (2.50/1) = 7.995 + 2.50 = 10.495
      // Plus proportional tax: (10.495/24.49) * 2.45 = ~1.05
      // Total: ~11.545
      final user1Amount = testBill.getAmountForParticipant('user1');
      expect(user1Amount, closeTo(11.55, 0.01));
      
      // user2: Pizza (15.99/2) + Tiramisu (6.00/1) = 7.995 + 6.00 = 13.995
      // Plus proportional tax: (13.995/24.49) * 2.45 = ~1.40
      // Total: ~15.395
      final user2Amount = testBill.getAmountForParticipant('user2');
      expect(user2Amount, closeTo(15.39, 0.01));
    });

    test('should check if participant has paid correctly', () {
      expect(testBill.isParticipantPaid('user1'), true);
      expect(testBill.isParticipantPaid('user2'), false);
      expect(testBill.isParticipantPaid('user3'), false);
    });

    test('should calculate total paid correctly', () {
      expect(testBill.getTotalPaid(), 10.75);
    });

    test('should calculate remaining amount correctly', () {
      expect(testBill.getRemainingAmount(), 16.19); // 26.94 - 10.75
    });

    test('should handle empty items list', () {
      final emptyBill = testBill.copyWith(items: []);
      expect(emptyBill.getAmountForParticipant('user1'), 0.0);
    });

    test('should handle zero subtotal', () {
      final zeroBill = testBill.copyWith(subtotal: 0.0);
      expect(zeroBill.getAmountForParticipant('user1'), greaterThan(0.0));
    });
  });
}
