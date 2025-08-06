import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class BillHistoryCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;

  const BillHistoryCard({
    super.key,
    required this.bill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bill.name,
                      style: AppTextStyles.headingSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bill.isCompleted
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bill.isCompleted ? 'Completada' : 'Pendiente',
                      style: bill.isCompleted
                          ? AppTextStyles.statusPaid
                          : AppTextStyles.statusPending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (bill.restaurantName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bill.restaurantName!,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(bill.createdAt),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bill.participants.length} participantes',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    '€${bill.total.toStringAsFixed(2)}',
                    style: AppTextStyles.priceMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: bill.total > 0 ? _getTotalPaid(bill) / bill.total : 0,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isFullyPaid(bill) ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pagado: €${_getTotalPaid(bill).toStringAsFixed(2)} / €${bill.total.toStringAsFixed(2)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate total amount paid by all participants
  double _getTotalPaid(Bill bill) {
    return bill.payments
        .where((payment) => payment.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // Check if all payments are completed
  bool _isFullyPaid(Bill bill) {
    if (bill.payments.isEmpty) return false;
    return bill.payments.every((payment) => payment.isPaid);
  }
}
