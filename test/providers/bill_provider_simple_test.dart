import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/models/payment.dart';

void main() {
  group('BillProvider Simple Tests', () {
    test('should initialize correctly', () {
      final billProvider = BillProvider();
      
      expect(billProvider.currentBill, isNull);
      expect(billProvider.isLoading, isFalse);
      expect(billProvider.error, isNull);
      
      billProvider.dispose();
    });

    test('should create manual bill with valid name', () {
      final billProvider = BillProvider();
      
      final success = billProvider.createManualBill('Test Bill');
      
      expect(success, isTrue);
      expect(billProvider.currentBill, isNotNull);
      expect(billProvider.currentBill!.name, equals('Test Bill'));
      expect(billProvider.error, isNull);
      
      billProvider.dispose();
    });

    test('should fail to create bill with empty name', () {
      final billProvider = BillProvider();
      
      final success = billProvider.createManualBill('');
      
      expect(success, isFalse);
      expect(billProvider.currentBill, isNull);
      expect(billProvider.error, isNotNull);
      
      billProvider.dispose();
    });

    test('should add participant successfully', () {
      final billProvider = BillProvider();
      
      billProvider.createManualBill('Test Bill');
      final success = billProvider.addParticipant('John Doe');
      
      expect(success, isTrue);
      expect(billProvider.currentBill!.participants, hasLength(1));
      expect(billProvider.currentBill!.payments, hasLength(1));
      expect(billProvider.error, isNull);
      
      billProvider.dispose();
    });

    test('should add manual item successfully', () async {
      final billProvider = BillProvider();
      
      await billProvider.createManualBill('Test Bill');
      final success = billProvider.addManualItem('Pizza', 15.99);
      
      expect(success, isTrue);
      expect(billProvider.currentBill!.items, hasLength(1));
      expect(billProvider.currentBill!.items.first.name, equals('Pizza'));
      expect(billProvider.currentBill!.items.first.price, equals(15.99));
      expect(billProvider.error, isNull);
      
      billProvider.dispose();
    });

    test('should mark payment as paid', () async {
      final billProvider = BillProvider();
      
      await billProvider.createManualBill('Test Bill');
      billProvider.addParticipant('John Doe');
      
      final participantId = billProvider.currentBill!.participants.first;
      billProvider.markPaymentAsPaid(participantId, PaymentMethod.card, 'Test payment');
      
      final payment = billProvider.currentBill!.payments
          .firstWhere((p) => p.participantId == participantId);
      expect(payment.isPaid, isTrue);
      expect(payment.method, equals(PaymentMethod.card));
      expect(payment.notes, equals('Test payment'));
      
      billProvider.dispose();
    });
  });
}
