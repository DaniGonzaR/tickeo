import 'package:flutter/material.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class ParticipantCard extends StatelessWidget {
  final String participantId;
  final Bill bill;
  final BillProvider billProvider;

  const ParticipantCard({
    super.key,
    required this.participantId,
    required this.bill,
    required this.billProvider,
  });

  @override
  Widget build(BuildContext context) {
    final participantName = billProvider.getParticipantName(participantId);
    final amount = bill.getAmountForParticipant(participantId);
    final isPaid = bill.isParticipantPaid(participantId);

    // Get selected items for this participant
    final selectedItems = bill.items
        .where((item) => item.selectedBy.contains(participantId))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Participant header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          isPaid ? AppColors.success : AppColors.primary,
                      radius: 20,
                      child: Text(
                        participantName.isNotEmpty
                            ? participantName[0].toUpperCase()
                            : 'U',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participantName,
                          style: AppTextStyles.headingSmall,
                        ),
                        Text(
                          '${selectedItems.length} productos',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: AppTextStyles.priceMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Pagado' : 'Pendiente',
                        style: isPaid
                            ? AppTextStyles.statusPaid
                            : AppTextStyles.statusPending,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (selectedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              Text(
                'Productos seleccionados:',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),

              ...selectedItems.map((item) {
                final shareCount = item.selectedBy.length;
                final itemPrice = shareCount > 1
                    ? item.totalPrice / shareCount
                    : item.totalPrice;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shareCount > 1
                              ? '${item.name} (compartido con ${shareCount - 1} más)'
                              : item.name,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${itemPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal productos:', style: AppTextStyles.bodySmall),
                  Text(
                    '\$${_getSubtotalForParticipant().toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),

              if (bill.tax > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Impuestos:', style: AppTextStyles.bodySmall),
                    Text(
                      '\$${_getTaxForParticipant().toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],

              if (bill.tip > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Propina:', style: AppTextStyles.bodySmall),
                    Text(
                      '\$${_getTipForParticipant().toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRemoveDialog(context),
                    icon: const Icon(Icons.person_remove, size: 16),
                    label: const Text('Remover'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedItems.isEmpty
                        ? null
                        : () => _showPaymentDialog(context),
                    icon: Icon(
                      isPaid ? Icons.check_circle : Icons.payment,
                      size: 16,
                    ),
                    label: Text(isPaid ? 'Pagado' : 'Marcar Pagado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPaid ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getSubtotalForParticipant() {
    double subtotal = 0.0;
    for (var item in bill.items) {
      if (item.selectedBy.contains(participantId)) {
        subtotal += item.totalPrice / item.selectedBy.length;
      }
    }
    return subtotal;
  }

  double _getTaxForParticipant() {
    if (bill.subtotal <= 0) return 0.0;
    final proportion = _getSubtotalForParticipant() / bill.subtotal;
    return bill.tax * proportion;
  }

  double _getTipForParticipant() {
    if (bill.subtotal <= 0) return 0.0;
    final proportion = _getSubtotalForParticipant() / bill.subtotal;
    return bill.tip * proportion;
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover Participante', style: AppTextStyles.headingMedium),
        content: Text(
          '¿Estás seguro de que quieres remover a ${billProvider.getParticipantName(participantId)}? '
          'Esto también lo quitará de todos los productos seleccionados.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              billProvider.removeParticipant(participantId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final payment = bill.payments.firstWhere(
      (p) => p.participantId == participantId,
    );

    if (payment.isPaid) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Pago', style: AppTextStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${payment.participantName} debe pagar:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: AppTextStyles.priceLarge,
            ),
            const SizedBox(height: 16),
            Text('Método de pago:', style: AppTextStyles.label),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              billProvider.markPaymentAsPaid(
                participantId,
                payment.method,
                null,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }
}
