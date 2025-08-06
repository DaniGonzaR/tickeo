import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';

void main() {
  group('BillProvider Tests', () {
    late BillProvider billProvider;

    setUp(() {
      billProvider = BillProvider();
    });

    test('should initialize with empty state', () {
      expect(billProvider.currentBill, null);
      expect(billProvider.billHistory, []);
      expect(billProvider.isLoading, false);
      expect(billProvider.error, null);
    });

    test('should create manual bill correctly', () {
      const billName = 'Test Manual Bill';
      
      billProvider.createManualBill(billName);
      
      expect(billProvider.currentBill, isNotNull);
      expect(billProvider.currentBill!.name, billName);
      expect(billProvider.currentBill!.items, []);
      expect(billProvider.currentBill!.participants, []);
      expect(billProvider.currentBill!.total, 0.0);
      expect(billProvider.currentBill!.shareCode, isNotEmpty);
      expect(billProvider.isLoading, false);
      expect(billProvider.error, null);
    });

    test('should add item to current bill', () {
      billProvider.createManualBill('Test Bill');
      
      billProvider.addItem('Pizza', 15.99);
      
      expect(billProvider.currentBill!.items.length, 1);
      expect(billProvider.currentBill!.items.first.name, 'Pizza');
      expect(billProvider.currentBill!.items.first.price, 15.99);
      expect(billProvider.currentBill!.subtotal, 15.99);
      expect(billProvider.currentBill!.total, 15.99);
    });

    test('should not add item when no current bill', () {
      billProvider.addItem('Pizza', 15.99);
      
      expect(billProvider.currentBill, null);
    });

    test('should add multiple items and calculate totals correctly', () {
      billProvider.createManualBill('Test Bill');
      
      billProvider.addItem('Pizza', 15.99);
      billProvider.addItem('Drink', 2.50);
      billProvider.addItem('Dessert', 6.00);
      
      expect(billProvider.currentBill!.items.length, 3);
      expect(billProvider.currentBill!.subtotal, 24.49);
      expect(billProvider.currentBill!.total, 24.49);
    });

    test('should remove item from current bill', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addItem('Pizza', 15.99);
      billProvider.addItem('Drink', 2.50);
      
      final itemId = billProvider.currentBill!.items.first.id;
      billProvider.removeItem(itemId);
      
      expect(billProvider.currentBill!.items.length, 1);
      expect(billProvider.currentBill!.items.first.name, 'Drink');
      expect(billProvider.currentBill!.subtotal, 2.50);
      expect(billProvider.currentBill!.total, 2.50);
    });

    test('should not remove item when no current bill', () {
      billProvider.removeItem('fake-id');
      expect(billProvider.currentBill, null);
    });

    test('should add participant to current bill', () {
      billProvider.createManualBill('Test Bill');
      
      billProvider.addParticipant('John');
      
      expect(billProvider.currentBill!.participants.length, 1);
      expect(billProvider.currentBill!.participants.first, 'John');
    });

    test('should not add duplicate participant', () {
      billProvider.createManualBill('Test Bill');
      
      billProvider.addParticipant('John');
      billProvider.addParticipant('John');
      
      expect(billProvider.currentBill!.participants.length, 1);
    });

    test('should not add participant when no current bill', () {
      billProvider.addParticipant('John');
      expect(billProvider.currentBill, null);
    });

    test('should remove participant from current bill', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addParticipant('John');
      billProvider.addParticipant('Jane');
      
      billProvider.removeParticipant('John');
      
      expect(billProvider.currentBill!.participants.length, 1);
      expect(billProvider.currentBill!.participants.first, 'Jane');
    });

    test('should assign item to participant', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addItem('Pizza', 15.99);
      billProvider.addParticipant('John');
      
      final itemId = billProvider.currentBill!.items.first.id;
      billProvider.assignItemToParticipant(itemId, 'John');
      
      expect(billProvider.currentBill!.items.first.selectedBy, contains('John'));
    });

    test('should unassign item from participant', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addItem('Pizza', 15.99);
      billProvider.addParticipant('John');
      
      final itemId = billProvider.currentBill!.items.first.id;
      billProvider.assignItemToParticipant(itemId, 'John');
      billProvider.unassignItemFromParticipant(itemId, 'John');
      
      expect(billProvider.currentBill!.items.first.selectedBy, isEmpty);
    });

    test('should mark payment as paid', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addParticipant('John');
      
      billProvider.markPaymentAsPaid('John', 10.0, 'card');
      
      final payment = billProvider.currentBill!.payments
          .firstWhere((p) => p.participantId == 'John');
      expect(payment.isPaid, true);
      expect(payment.amount, 10.0);
      expect(payment.paymentMethod, 'card');
      expect(payment.paidAt, isNotNull);
    });

    test('should mark payment as unpaid', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addParticipant('John');
      billProvider.markPaymentAsPaid('John', 10.0, 'card');
      
      billProvider.markPaymentAsUnpaid('John');
      
      final payment = billProvider.currentBill!.payments
          .firstWhere((p) => p.participantId == 'John');
      expect(payment.isPaid, false);
      expect(payment.paidAt, null);
    });

    test('should save bill to history when completed', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addItem('Pizza', 15.99);
      billProvider.addParticipant('John');
      
      billProvider.saveBillToHistory();
      
      expect(billProvider.billHistory.length, 1);
      expect(billProvider.billHistory.first.name, 'Test Bill');
      expect(billProvider.currentBill, null);
    });

    test('should not save empty bill to history', () {
      billProvider.createManualBill('Empty Bill');
      
      billProvider.saveBillToHistory();
      
      expect(billProvider.billHistory, isEmpty);
      expect(billProvider.currentBill, isNotNull);
    });

    test('should clear current bill', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addItem('Pizza', 15.99);
      
      billProvider.clearCurrentBill();
      
      expect(billProvider.currentBill, null);
    });

    test('should load bill by share code', () {
      // Create and save a bill first
      billProvider.createManualBill('Shared Bill');
      billProvider.addItem('Pizza', 15.99);
      final shareCode = billProvider.currentBill!.shareCode;
      billProvider.saveBillToHistory();
      
      // Load by share code
      final success = billProvider.loadBillByShareCode(shareCode);
      
      expect(success, true);
      expect(billProvider.currentBill, isNotNull);
      expect(billProvider.currentBill!.name, 'Shared Bill');
    });

    test('should fail to load non-existent share code', () {
      final success = billProvider.loadBillByShareCode('INVALID');
      
      expect(success, false);
      expect(billProvider.currentBill, null);
    });

    test('should calculate participant amounts correctly', () {
      billProvider.createManualBill('Test Bill');
      billProvider.addItem('Pizza', 20.0);
      billProvider.addItem('Drink', 4.0);
      billProvider.addParticipant('John');
      billProvider.addParticipant('Jane');
      
      final pizzaId = billProvider.currentBill!.items
          .firstWhere((item) => item.name == 'Pizza').id;
      final drinkId = billProvider.currentBill!.items
          .firstWhere((item) => item.name == 'Drink').id;
      
      // John gets pizza (shared) and drink (solo)
      billProvider.assignItemToParticipant(pizzaId, 'John');
      billProvider.assignItemToParticipant(pizzaId, 'Jane');
      billProvider.assignItemToParticipant(drinkId, 'John');
      
      final johnAmount = billProvider.getParticipantAmount('John');
      final janeAmount = billProvider.getParticipantAmount('Jane');
      
      expect(johnAmount, 14.0); // 10.0 (pizza/2) + 4.0 (drink)
      expect(janeAmount, 10.0); // 10.0 (pizza/2)
    });

    test('should return 0 for non-existent participant', () {
      billProvider.createManualBill('Test Bill');
      
      final amount = billProvider.getParticipantAmount('NonExistent');
      
      expect(amount, 0.0);
    });
  });
}
