import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/payment.dart';

/// Service for analyzing bill data and providing insights
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Calculate spending statistics for a list of bills
  static SpendingStats calculateSpendingStats(List<Bill> bills) {
    if (bills.isEmpty) {
      return SpendingStats.empty();
    }

    final totalSpent = bills.fold<double>(0.0, (sum, bill) => sum + bill.total);
    final averagePerBill = totalSpent / bills.length;
    
    final sortedTotals = bills.map((b) => b.total).toList()..sort();
    final medianSpent = _calculateMedian(sortedTotals);
    
    final maxBill = bills.reduce((a, b) => a.total > b.total ? a : b);
    final minBill = bills.reduce((a, b) => a.total < b.total ? a : b);

    // Calculate monthly spending
    final monthlySpending = <String, double>{};
    for (final bill in bills) {
      final monthKey = '${bill.createdAt.year}-${bill.createdAt.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0.0) + bill.total;
    }

    // Calculate category spending (by restaurant)
    final restaurantSpending = <String, double>{};
    for (final bill in bills) {
      final restaurant = bill.restaurantName ?? 'Unknown';
      restaurantSpending[restaurant] = (restaurantSpending[restaurant] ?? 0.0) + bill.total;
    }

    return SpendingStats(
      totalSpent: totalSpent,
      averagePerBill: averagePerBill,
      medianSpent: medianSpent,
      maxBill: maxBill,
      minBill: minBill,
      totalBills: bills.length,
      monthlySpending: monthlySpending,
      restaurantSpending: restaurantSpending,
    );
  }

  /// Calculate participant statistics
  static ParticipantStats calculateParticipantStats(List<Bill> bills) {
    final participantFrequency = <String, int>{};
    final participantSpending = <String, double>{};
    final participantPaymentMethods = <String, Map<PaymentMethod, int>>{};

    for (final bill in bills) {
      for (final payment in bill.payments) {
        final name = payment.participantName;
        
        // Frequency
        participantFrequency[name] = (participantFrequency[name] ?? 0) + 1;
        
        // Spending
        participantSpending[name] = (participantSpending[name] ?? 0.0) + payment.amount;
        
        // Payment methods
        if (payment.isPaid) {
          participantPaymentMethods[name] ??= {};
          final methods = participantPaymentMethods[name]!;
          methods[payment.method] = (methods[payment.method] ?? 0) + 1;
        }
      }
    }

    return ParticipantStats(
      participantFrequency: participantFrequency,
      participantSpending: participantSpending,
      participantPaymentMethods: participantPaymentMethods,
    );
  }

  /// Calculate payment completion rate
  static PaymentStats calculatePaymentStats(List<Bill> bills) {
    int totalPayments = 0;
    int completedPayments = 0;
    double totalAmount = 0.0;
    double paidAmount = 0.0;
    final paymentMethodCounts = <PaymentMethod, int>{};

    for (final bill in bills) {
      for (final payment in bill.payments) {
        totalPayments++;
        totalAmount += payment.amount;
        
        if (payment.isPaid) {
          completedPayments++;
          paidAmount += payment.amount;
          paymentMethodCounts[payment.method] = 
              (paymentMethodCounts[payment.method] ?? 0) + 1;
        }
      }
    }

    final completionRate = totalPayments > 0 ? completedPayments / totalPayments : 0.0;
    final amountCompletionRate = totalAmount > 0 ? paidAmount / totalAmount : 0.0;

    return PaymentStats(
      totalPayments: totalPayments,
      completedPayments: completedPayments,
      completionRate: completionRate,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      amountCompletionRate: amountCompletionRate,
      paymentMethodCounts: paymentMethodCounts,
    );
  }

  /// Get spending trends over time
  static List<SpendingTrend> getSpendingTrends(List<Bill> bills) {
    final monthlyData = <String, SpendingTrendData>{};

    for (final bill in bills) {
      final monthKey = '${bill.createdAt.year}-${bill.createdAt.month.toString().padLeft(2, '0')}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = SpendingTrendData(
          month: monthKey,
          totalSpent: 0.0,
          billCount: 0,
          averagePerBill: 0.0,
        );
      }
      
      final data = monthlyData[monthKey]!;
      data.totalSpent += bill.total;
      data.billCount++;
      data.averagePerBill = data.totalSpent / data.billCount;
    }

    final trends = monthlyData.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    return trends.map((data) => SpendingTrend(
      month: data.month,
      totalSpent: data.totalSpent,
      billCount: data.billCount,
      averagePerBill: data.averagePerBill,
    )).toList();
  }

  /// Get most frequent items across all bills
  static List<ItemFrequency> getMostFrequentItems(List<Bill> bills) {
    final itemCounts = <String, ItemFrequencyData>{};

    for (final bill in bills) {
      for (final item in bill.items) {
        if (!itemCounts.containsKey(item.name)) {
          itemCounts[item.name] = ItemFrequencyData(
            name: item.name,
            count: 0,
            totalSpent: 0.0,
            averagePrice: 0.0,
          );
        }
        
        final data = itemCounts[item.name]!;
        data.count += item.quantity;
        data.totalSpent += item.totalPrice;
        data.averagePrice = data.totalSpent / data.count;
      }
    }

    final frequencies = itemCounts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return frequencies.map((data) => ItemFrequency(
      name: data.name,
      count: data.count,
      totalSpent: data.totalSpent,
      averagePrice: data.averagePrice,
    )).toList();
  }

  static double _calculateMedian(List<double> sortedValues) {
    final length = sortedValues.length;
    if (length == 0) return 0.0;
    
    if (length % 2 == 1) {
      return sortedValues[length ~/ 2];
    } else {
      return (sortedValues[length ~/ 2 - 1] + sortedValues[length ~/ 2]) / 2;
    }
  }
}

/// Data classes for analytics results
class SpendingStats {
  final double totalSpent;
  final double averagePerBill;
  final double medianSpent;
  final Bill maxBill;
  final Bill minBill;
  final int totalBills;
  final Map<String, double> monthlySpending;
  final Map<String, double> restaurantSpending;

  SpendingStats({
    required this.totalSpent,
    required this.averagePerBill,
    required this.medianSpent,
    required this.maxBill,
    required this.minBill,
    required this.totalBills,
    required this.monthlySpending,
    required this.restaurantSpending,
  });

  factory SpendingStats.empty() {
    return SpendingStats(
      totalSpent: 0.0,
      averagePerBill: 0.0,
      medianSpent: 0.0,
      maxBill: Bill.empty(),
      minBill: Bill.empty(),
      totalBills: 0,
      monthlySpending: {},
      restaurantSpending: {},
    );
  }
}

class ParticipantStats {
  final Map<String, int> participantFrequency;
  final Map<String, double> participantSpending;
  final Map<String, Map<PaymentMethod, int>> participantPaymentMethods;

  ParticipantStats({
    required this.participantFrequency,
    required this.participantSpending,
    required this.participantPaymentMethods,
  });
}

class PaymentStats {
  final int totalPayments;
  final int completedPayments;
  final double completionRate;
  final double totalAmount;
  final double paidAmount;
  final double amountCompletionRate;
  final Map<PaymentMethod, int> paymentMethodCounts;

  PaymentStats({
    required this.totalPayments,
    required this.completedPayments,
    required this.completionRate,
    required this.totalAmount,
    required this.paidAmount,
    required this.amountCompletionRate,
    required this.paymentMethodCounts,
  });
}

class SpendingTrend {
  final String month;
  final double totalSpent;
  final int billCount;
  final double averagePerBill;

  SpendingTrend({
    required this.month,
    required this.totalSpent,
    required this.billCount,
    required this.averagePerBill,
  });
}

class ItemFrequency {
  final String name;
  final int count;
  final double totalSpent;
  final double averagePrice;

  ItemFrequency({
    required this.name,
    required this.count,
    required this.totalSpent,
    required this.averagePrice,
  });
}

// Helper classes for internal calculations
class SpendingTrendData {
  final String month;
  double totalSpent;
  int billCount;
  double averagePerBill;

  SpendingTrendData({
    required this.month,
    required this.totalSpent,
    required this.billCount,
    required this.averagePerBill,
  });
}

class ItemFrequencyData {
  final String name;
  int count;
  double totalSpent;
  double averagePrice;

  ItemFrequencyData({
    required this.name,
    required this.count,
    required this.totalSpent,
    required this.averagePrice,
  });
}
