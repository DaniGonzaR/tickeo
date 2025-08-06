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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final cardPadding = isMobile ? 16.0 : 20.0;
        final itemSpacing = isMobile ? 12.0 : 16.0;
        final borderRadius = isMobile ? 12.0 : 16.0;
        
        return Card(
          elevation: 4,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resumen de Pagos',
                      style: isMobile 
                        ? AppTextStyles.headingSmall
                        : AppTextStyles.headingMedium,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: progressValue >= 1.0 
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        progressValue >= 1.0 ? 'Completado' : 'Pendiente',
                        style: TextStyle(
                          color: progressValue >= 1.0 ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: itemSpacing),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso de Pagos',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        Text(
                          '${(progressValue * 100).toInt()}%',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressValue >= 1.0 ? AppColors.success : AppColors.primary,
                      ),
                      minHeight: isMobile ? 6 : 8,
                    ),
                  ],
                ),

                SizedBox(height: itemSpacing),

                // Amount breakdown
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  ),
                  child: Column(
                    children: [
                      _buildAmountRow(
                        'Total de la Cuenta',
                        '€${bill.total.toStringAsFixed(2)}',
                        AppTextStyles.bodyMedium,
                        isMobile,
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      _buildAmountRow(
                        'Total Pagado',
                        '€${totalPaid.toStringAsFixed(2)}',
                        AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
                        isMobile,
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      _buildAmountRow(
                        'Pendiente',
                        '€${remainingAmount.toStringAsFixed(2)}',
                        AppTextStyles.bodyMedium.copyWith(
                          color: remainingAmount > 0 ? AppColors.warning : AppColors.success,
                        ),
                        isMobile,
                      ),
                      if (remainingAmount <= 0) ...[
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 8 : 12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: isMobile ? 16 : 20,
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              Expanded(
                                child: Text(
                                  '¡Todos los pagos completados!',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: itemSpacing),

                // Statistics
                if (isMobile)
                  // Mobile: Vertical layout
                  Column(
                    children: [
                      _buildStatCard(
                        'Participantes que Pagaron',
                        '$paidParticipants de $totalParticipants',
                        Icons.people,
                        AppColors.primary,
                        isMobile,
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      _buildStatCard(
                        'Productos en la Cuenta',
                        '${bill.items.length}',
                        Icons.receipt_long,
                        AppColors.secondary,
                        isMobile,
                      ),
                    ],
                  )
                else
                  // Desktop/Tablet: Horizontal layout
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Participantes que Pagaron',
                          '$paidParticipants de $totalParticipants',
                          Icons.people,
                          AppColors.primary,
                          isMobile,
                        ),
                      ),
                      SizedBox(width: itemSpacing),
                      Expanded(
                        child: _buildStatCard(
                          'Productos en la Cuenta',
                          '${bill.items.length}',
                          Icons.receipt_long,
                          AppColors.secondary,
                          isMobile,
                        ),
                      ),
                    ],
                  ),

                if (bill.payments.isNotEmpty) ...[
                  SizedBox(height: itemSpacing),
                  
                  // Payment details
                  Text(
                    'Detalles de Pagos',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: isMobile ? 150 : 200,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: bill.payments.length,
                      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 4 : 6),
                      itemBuilder: (context, index) {
                        final payment = bill.payments[index];
                        return Container(
                          padding: EdgeInsets.all(isMobile ? 8 : 12),
                          decoration: BoxDecoration(
                            color: payment.isPaid 
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: payment.isPaid 
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                payment.isPaid ? Icons.check_circle : Icons.schedule,
                                color: payment.isPaid ? AppColors.success : AppColors.warning,
                                size: isMobile ? 16 : 18,
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              Expanded(
                                child: Text(
                                  payment.participantName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '€${payment.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: payment.isPaid ? AppColors.success : AppColors.warning,
                                  fontSize: isMobile ? 12 : 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountRow(String label, String amount, TextStyle style, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style.copyWith(fontSize: isMobile ? 13 : 14),
        ),
        Text(
          amount,
          style: style.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isMobile
        ? Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.headingSmall.copyWith(
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: AppTextStyles.headingSmall.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
