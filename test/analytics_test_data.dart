import 'package:flutter_test/flutter_test.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';
import 'package:tickeo/services/analytics_service.dart';

void main() {
  group('Analytics Service Tests with Real Data', () {
    late AnalyticsService analyticsService;
    late List<Bill> testBills;

    setUp(() {
      analyticsService = AnalyticsService();
      testBills = _createTestBills();
    });

    test('should calculate spending stats correctly', () {
      final stats = analyticsService.calculateSpendingStats(testBills);
      
      print('=== SPENDING STATS ===');
      print('Total Bills: ${stats.totalBills}');
      print('Total Amount: €${stats.totalAmount.toStringAsFixed(2)}');
      print('Average Bill: €${stats.averageBill.toStringAsFixed(2)}');
      print('Median Bill: €${stats.medianBill.toStringAsFixed(2)}');
      
      expect(stats.totalBills, equals(4));
      expect(stats.totalAmount, greaterThan(0));
      expect(stats.averageBill, greaterThan(0));
      expect(stats.medianBill, greaterThan(0));
    });

    test('should calculate participant stats correctly', () {
      final stats = analyticsService.calculateParticipantStats(testBills);
      
      print('\n=== PARTICIPANT STATS ===');
      print('Total Participants: ${stats.totalParticipants}');
      print('Average per Bill: ${stats.averageParticipantsPerBill.toStringAsFixed(1)}');
      print('Most Active: ${stats.mostActiveParticipant}');
      print('Total Spending by ${stats.mostActiveParticipant}: €${stats.totalSpentByMostActive.toStringAsFixed(2)}');
      
      expect(stats.totalParticipants, greaterThan(0));
      expect(stats.averageParticipantsPerBill, greaterThan(0));
      expect(stats.mostActiveParticipant, isNotEmpty);
      expect(stats.totalSpentByMostActive, greaterThan(0));
    });

    test('should calculate payment stats correctly', () {
      final stats = analyticsService.calculatePaymentStats(testBills);
      
      print('\n=== PAYMENT STATS ===');
      print('Total Payments: ${stats.totalPayments}');
      print('Paid Payments: ${stats.paidPayments}');
      print('Completion Rate: ${(stats.completionRate * 100).toStringAsFixed(1)}%');
      print('Most Used Method: ${_getPaymentMethodName(stats.mostUsedMethod)}');
      
      expect(stats.totalPayments, greaterThan(0));
      expect(stats.completionRate, greaterThanOrEqualTo(0));
      expect(stats.completionRate, lessThanOrEqualTo(1));
    });

    test('should calculate spending trends correctly', () {
      final trends = analyticsService.getSpendingTrends(testBills);
      
      print('\n=== SPENDING TRENDS ===');
      for (final trend in trends) {
        print('${trend.month}: €${trend.amount.toStringAsFixed(2)} (${trend.billCount} bills)');
      }
      
      expect(trends, isNotEmpty);
      expect(trends.every((trend) => trend.amount >= 0), isTrue);
      expect(trends.every((trend) => trend.billCount >= 0), isTrue);
    });

    test('should calculate item frequency correctly', () {
      final items = analyticsService.getMostFrequentItems(testBills);
      
      print('\n=== MOST ORDERED ITEMS ===');
      for (final item in items.take(10)) {
        print('${item.name}: ${item.frequency} times, Avg: €${item.averagePrice.toStringAsFixed(2)}');
      }
      
      expect(items, isNotEmpty);
      expect(items.every((item) => item.frequency > 0), isTrue);
      expect(items.every((item) => item.averagePrice >= 0), isTrue);
    });

    test('should calculate restaurant breakdown correctly', () {
      final stats = analyticsService.calculateSpendingStats(testBills);
      
      print('\n=== RESTAURANT BREAKDOWN ===');
      for (final entry in stats.restaurantSpending.entries) {
        print('${entry.key}: €${entry.value.toStringAsFixed(2)}');
      }
      
      expect(stats.restaurantSpending, isNotEmpty);
      expect(stats.restaurantSpending.values.every((amount) => amount >= 0), isTrue);
    });
  });
}

List<Bill> _createTestBills() {
  final now = DateTime.now();
  
  return [
    // Bill 1: Pizza Restaurant
    Bill(
      id: '1',
      name: 'Pizza Night',
      createdAt: now.subtract(const Duration(days: 5)),
      restaurantName: 'Mario\'s Pizza',
      items: [
        BillItem(
          id: 'item1',
          name: 'Margherita Pizza',
          price: 12.50,
          selectedBy: ['user1', 'user2'],
        ),
        BillItem(
          id: 'item2',
          name: 'Pepperoni Pizza',
          price: 14.00,
          selectedBy: ['user3'],
        ),
        BillItem(
          id: 'item3',
          name: 'Coca Cola',
          price: 2.50,
          selectedBy: ['user1', 'user2', 'user3'],
        ),
      ],
      participants: ['user1', 'user2', 'user3'],
      payments: [
        Payment(
          participantId: 'user1',
          participantName: 'Alice',
          amount: 10.00,
          isPaid: true,
          method: PaymentMethod.card,
        ),
        Payment(
          participantId: 'user2',
          participantName: 'Bob',
          amount: 10.00,
          isPaid: true,
          method: PaymentMethod.cash,
        ),
        Payment(
          participantId: 'user3',
          participantName: 'Charlie',
          amount: 9.00,
          isPaid: false,
          method: PaymentMethod.transfer,
        ),
      ],
      subtotal: 29.00,
      tax: 0.0,
      tip: 0.0,
      total: 29.00,
      shareCode: 'PIZZA123',
    ),
    
    // Bill 2: Sushi Restaurant
    Bill(
      id: '2',
      name: 'Sushi Dinner',
      createdAt: now.subtract(const Duration(days: 15)),
      restaurantName: 'Sakura Sushi',
      items: [
        BillItem(
          id: 'item4',
          name: 'Salmon Roll',
          price: 8.50,
          selectedBy: ['user1', 'user4'],
        ),
        BillItem(
          id: 'item5',
          name: 'Tuna Sashimi',
          price: 12.00,
          selectedBy: ['user2'],
        ),
        BillItem(
          id: 'item6',
          name: 'Miso Soup',
          price: 3.50,
          selectedBy: ['user1', 'user2', 'user4'],
        ),
      ],
      participants: ['user1', 'user2', 'user4'],
      payments: [
        Payment(
          participantId: 'user1',
          participantName: 'Alice',
          amount: 8.00,
          isPaid: true,
          method: PaymentMethod.card,
        ),
        Payment(
          participantId: 'user2',
          participantName: 'Bob',
          amount: 8.00,
          isPaid: true,
          method: PaymentMethod.digitalWallet,
        ),
        Payment(
          participantId: 'user4',
          participantName: 'Diana',
          amount: 8.00,
          isPaid: true,
          method: PaymentMethod.card,
        ),
      ],
      subtotal: 24.00,
      tax: 0.0,
      tip: 0.0,
      total: 24.00,
      shareCode: 'SUSHI456',
    ),
    
    // Bill 3: Coffee Shop
    Bill(
      id: '3',
      name: 'Morning Coffee',
      createdAt: now.subtract(const Duration(days: 2)),
      restaurantName: 'Central Perk',
      items: [
        BillItem(
          id: 'item7',
          name: 'Cappuccino',
          price: 4.50,
          selectedBy: ['user1'],
        ),
        BillItem(
          id: 'item8',
          name: 'Latte',
          price: 4.00,
          selectedBy: ['user2'],
        ),
        BillItem(
          id: 'item9',
          name: 'Croissant',
          price: 3.50,
          selectedBy: ['user1', 'user2'],
        ),
      ],
      participants: ['user1', 'user2'],
      payments: [
        Payment(
          participantId: 'user1',
          participantName: 'Alice',
          amount: 6.25,
          isPaid: true,
          method: PaymentMethod.cash,
        ),
        Payment(
          participantId: 'user2',
          participantName: 'Bob',
          amount: 5.75,
          isPaid: false,
          method: PaymentMethod.transfer,
        ),
      ],
      subtotal: 12.00,
      tax: 0.0,
      tip: 0.0,
      total: 12.00,
      shareCode: 'COFFEE789',
    ),
    
    // Bill 4: Mexican Restaurant
    Bill(
      id: '4',
      name: 'Taco Tuesday',
      createdAt: now.subtract(const Duration(days: 30)),
      restaurantName: 'El Mariachi',
      items: [
        BillItem(
          id: 'item10',
          name: 'Beef Tacos',
          price: 9.50,
          selectedBy: ['user1', 'user3'],
        ),
        BillItem(
          id: 'item11',
          name: 'Chicken Quesadilla',
          price: 11.00,
          selectedBy: ['user2'],
        ),
        BillItem(
          id: 'item12',
          name: 'Guacamole',
          price: 5.50,
          selectedBy: ['user1', 'user2', 'user3'],
        ),
        BillItem(
          id: 'item13',
          name: 'Margarita',
          price: 8.00,
          selectedBy: ['user1', 'user2'],
        ),
      ],
      participants: ['user1', 'user2', 'user3'],
      payments: [
        Payment(
          participantId: 'user1',
          participantName: 'Alice',
          amount: 12.33,
          isPaid: true,
          method: PaymentMethod.card,
        ),
        Payment(
          participantId: 'user2',
          participantName: 'Bob',
          amount: 11.33,
          isPaid: true,
          method: PaymentMethod.card,
        ),
        Payment(
          participantId: 'user3',
          participantName: 'Charlie',
          amount: 10.34,
          isPaid: true,
          method: PaymentMethod.cash,
        ),
      ],
      subtotal: 34.00,
      tax: 0.0,
      tip: 0.0,
      total: 34.00,
      shareCode: 'TACO101',
    ),
  ];
}

String _getPaymentMethodName(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.transfer:
      return 'Transfer';
    case PaymentMethod.digitalWallet:
      return 'Digital Wallet';
    case PaymentMethod.other:
      return 'Other';
  }
}
