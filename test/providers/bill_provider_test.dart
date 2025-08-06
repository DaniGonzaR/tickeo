import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/models/payment.dart';

void main() {
  group('BillProvider Tests', () {
    late BillProvider billProvider;

    setUp(() {
      billProvider = BillProvider();
    });

    tearDown(() {
      billProvider.dispose();
    });

    test('should create a new manual bill successfully', () {
      const billName = 'Test Bill';
      
      final success = billProvider.createManualBill(billName);
      
      expect(success, isTrue);
      expect(billProvider.currentBill, isNotNull);
      expect(billProvider.currentBill!.name, equals(billName));
      expect(billProvider.currentBill!.items, isEmpty);
      expect(billProvider.currentBill!.participants, isEmpty);
      expect(billProvider.currentBill!.payments, isEmpty);
      expect(billProvider.error, isNull);
    });

    test('should fail to create bill with invalid name', () {
      const invalidBillName = '';
      
      final success = billProvider.createManualBill(invalidBillName);
      
      expect(success, isFalse);
      expect(billProvider.currentBill, isNull);
      expect(billProvider.error, isNotNull);
    });

    test('should add participant to bill successfully', () {
      const billName = 'Test Bill';
      const participantName = 'John Doe';
      
      billProvider.createManualBill(billName);
      final success = billProvider.addParticipant(participantName);
      
      expect(success, isTrue);
      expect(billProvider.currentBill!.participants, hasLength(1));
      expect(billProvider.currentBill!.payments, hasLength(1));
      expect(billProvider.currentBill!.payments.first.participantName, equals(participantName));
      expect(billProvider.error, isNull);
    });

    test('should fail to add participant with invalid name', () {
      const billName = 'Test Bill';
      const invalidParticipantName = '';
      
      billProvider.createManualBill(billName);
      final success = billProvider.addParticipant(invalidParticipantName);
      
      expect(success, isFalse);
      expect(billProvider.currentBill!.participants, isEmpty);
      expect(billProvider.error, isNotNull);
    });

    test('should add manual item to bill successfully', () {
      const billName = 'Test Bill';
      const itemName = 'Pizza';
      const itemPrice = 15.99;
      
      billProvider.createManualBill(billName);
      final success = billProvider.addManualItem(itemName, itemPrice);
      
      expect(success, isTrue);
      expect(billProvider.currentBill!.items, hasLength(1));
      expect(billProvider.currentBill!.items.first.name, equals(itemName));
      expect(billProvider.currentBill!.items.first.price, equals(itemPrice));
      expect(billProvider.error, isNull);
    });

    test('should fail to add item with invalid price', () {
      const billName = 'Test Bill';
      const itemName = 'Pizza';
      const invalidPrice = -5.0;
      
      billProvider.createManualBill(billName);
      final success = billProvider.addManualItem(itemName, invalidPrice);
      
      expect(success, isFalse);
      expect(billProvider.currentBill!.items, isEmpty);
      expect(billProvider.error, isNotNull);
    });

    test('should remove participant from bill', () {
      const billName = 'Test Bill';
      const participantName = 'John Doe';
      
      billProvider.createManualBill(billName);
      billProvider.addParticipant(participantName);
      
      final participantId = billProvider.currentBill!.participants.first;
      billProvider.removeParticipant(participantId);
      
      expect(billProvider.currentBill!.participants, isEmpty);
      expect(billProvider.currentBill!.payments, isEmpty);
    });

    test('should toggle item selection for participant', () {
      const billName = 'Test Bill';
      const participantName = 'John Doe';
      const itemName = 'Pizza';
      const itemPrice = 15.99;
      
      billProvider.createManualBill(billName);
      billProvider.addParticipant(participantName);
      billProvider.addManualItem(itemName, itemPrice);
      
      final participantId = billProvider.currentBill!.participants.first;
      final itemId = billProvider.currentBill!.items.first.id;
      
      // Toggle on
      billProvider.toggleItemSelection(itemId, participantId);
      expect(billProvider.currentBill!.items.first.selectedBy, contains(participantId));
      
      // Toggle off
      billProvider.toggleItemSelection(itemId, participantId);
      expect(billProvider.currentBill!.items.first.selectedBy, isEmpty);
    });

    test('should update tip and recalculate total', () {
      const billName = 'Test Bill';
      const tip = 5.0;
      
      billProvider.createManualBill(billName);
      billProvider.addManualItem('Pizza', 15.99);
      billProvider.updateTip(tip);
      
      expect(billProvider.currentBill!.tip, equals(tip));
      expect(billProvider.currentBill!.total, equals(20.99)); // 15.99 + 5.0
    });

    test('should split bill equally among participants', () {
      const billName = 'Test Bill';
      
      billProvider.createManualBill(billName);
      billProvider.addParticipant('Jane');
      billProvider.addManualItem('Pizza', 20.0);
      
      billProvider.splitBillEqually();
      
      expect(billProvider.currentBill!.payments, hasLength(2));
      for (final payment in billProvider.currentBill!.payments) {
        expect(payment.amount, equals(10.0)); // 20.0 / 2
      }
    });

    test('should mark payment as paid', () {
      const billName = 'Test Bill';
      
      billProvider.createManualBill(billName);
      billProvider.addParticipant('John');
      
      final participantId = billProvider.currentBill!.participants.first;
      billProvider.markPaymentAsPaid(participantId, PaymentMethod.card, 'Test payment');
      
      final payment = billProvider.currentBill!.payments
          .firstWhere((p) => p.participantId == participantId);
      expect(payment.isPaid, isTrue);
      expect(payment.method, equals(PaymentMethod.card));
      expect(payment.notes, equals('Test payment'));
    });

    test('should calculate total correctly with multiple items', () {
      const billName = 'Test Bill';
      
      billProvider.createManualBill(billName);
      billProvider.addManualItem('Pizza', 15.99);
      billProvider.addManualItem('Drink', 3.50);
      
      expect(billProvider.currentBill!.subtotal, equals(19.49));
      expect(billProvider.currentBill!.total, equals(19.49)); // No tax or tip
    });

    test('should handle loading states correctly', () async {
      expect(billProvider.isLoading, isFalse);
      
      // Loading state is internal, but we can test that operations complete
      await billProvider.createManualBill('Test Bill');
      
      expect(billProvider.isLoading, isFalse);
    });

    test('should get participant name correctly', () async {
      const billName = 'Test Bill';
      const participantName = 'John Doe';
      
      await billProvider.createManualBill(billName);
      billProvider.addParticipant(participantName);
      
      final participantId = billProvider.currentBill!.participants.first;
      final retrievedName = billProvider.getParticipantName(participantId);
      
      expect(retrievedName, equals(participantName));
    });

    test('should return unknown for invalid participant id', () {
      const invalidId = 'invalid-id';
      final retrievedName = billProvider.getParticipantName(invalidId);
      
      expect(retrievedName, equals('Unknown'));
    });

    test('should handle error states correctly', () async {
      // Test with invalid bill name
      final success = await billProvider.createManualBill('');
      
      expect(success, isFalse);
      expect(billProvider.error, isNotNull);
      expect(billProvider.currentBill, isNull);
    });
  });
}
