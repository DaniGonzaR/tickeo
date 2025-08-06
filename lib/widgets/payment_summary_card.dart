import 'package:flutter/material.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class PaymentSummaryCard extends StatelessWidget {
  final Bill bill;
  final BillProvider billProvider;

  const PaymentSummaryCard({
    super.key,
    required this.bill,
    required this.billProvider,
  });

  @override
  Widget build(BuildContext context) {
    final totalPaid = bill.getTotalPaid();
    final remainingAmount = bill.getRemainingAmount();
    final progressValue = bill.total > 0 ? totalPaid / bill.total : 0.0;
    final paidParticipants = bill.payments.where((p) => p.isPaid).length;
    final totalParticipants = bill.participants.length;

    return Card(
      elevation: 4,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de Pagos',
                  style: AppTextStyles.headingMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bill.isCompleted
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bill.isCompleted ? 'Completado' : 'En Progreso',
                    style: bill.isCompleted
                        ? AppTextStyles.statusPaid
                        : AppTextStyles.statusPending,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso de Pagos',
                      style: AppTextStyles.label,
                    ),
                    Text(
                      '$paidParticipants de $totalParticipants pagaron',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    bill.isCompleted ? AppColors.success : AppColors.primary,
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progressValue * 100).toStringAsFixed(1)}% completado',
                  style: AppTextStyles.caption,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Amount breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildAmountRow('Total de la cuenta:', bill.total,
                      isTotal: true),
                  const SizedBox(height: 8),
                  _buildAmountRow('Monto pagado:', totalPaid,
                      color: AppColors.success),
                  const SizedBox(height: 8),
                  _buildAmountRow('Monto pendiente:', remainingAmount,
                      color: remainingAmount > 0
                          ? AppColors.warning
                          : AppColors.success),
                  if (bill.participants.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildAmountRow(
                      'Promedio por persona:',
                      bill.total / bill.participants.length,
                      color: AppColors.info,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Productos',
                    bill.items.length.toString(),
                    Icons.receipt_long,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Participantes',
                    bill.participants.length.toString(),
                    Icons.people,
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pagados',
                    paidParticipants.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),

            if (bill.restaurantName != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bill.restaurantName!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Share code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Código para compartir: ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    bill.shareCode,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount,
      {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium,
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: isTotal
              ? AppTextStyles.priceLarge
              : AppTextStyles.priceMedium.copyWith(
                  color: color ?? AppColors.textPrimary,
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
