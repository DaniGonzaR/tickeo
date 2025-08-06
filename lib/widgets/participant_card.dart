import 'package:flutter/material.dart';
import 'package:tickeo/models/bill.dart';
import 'package:tickeo/models/payment.dart';
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
    
    // Get payment for this participant to ensure synchronization with "Dividir Equitativamente"
    final payment = bill.payments.firstWhere(
      (p) => p.participantId == participantId,
      orElse: () => Payment(
        id: '',
        participantId: participantId,
        participantName: participantName,
        amount: bill.getAmountForParticipant(participantId), // Fallback to calculated amount
        method: PaymentMethod.cash,
      ),
    );
    
    final amount = payment.amount;
    final isPaid = payment.isPaid;

    // Get selected items for this participant
    final selectedItems = bill.items
        .where((item) => item.selectedBy.contains(participantId))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final cardPadding = isMobile ? 12.0 : 16.0;
        final avatarRadius = isMobile ? 18.0 : 20.0;
        final itemSpacing = isMobile ? 8.0 : 12.0;
        
        return Card(
          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          elevation: 2,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Participant header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isPaid ? AppColors.success : AppColors.primary,
                            radius: avatarRadius,
                            child: Text(
                              participantName.isNotEmpty
                                  ? participantName[0].toUpperCase()
                                  : 'U',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(width: itemSpacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  participantName,
                                  style: isMobile 
                                    ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                                    : AppTextStyles.headingSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isMobile 
                                    ? '${selectedItems.length} items'
                                    : '${selectedItems.length} productos',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount and status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${amount.toStringAsFixed(2)}',
                          style: isMobile 
                            ? AppTextStyles.priceMedium.copyWith(fontSize: 16)
                            : AppTextStyles.priceLarge,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 8,
                            vertical: isMobile ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid 
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPaid ? 'Pagado' : 'Pendiente',
                            style: TextStyle(
                              color: isPaid ? AppColors.success : AppColors.warning,
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (selectedItems.isNotEmpty) ...[
                  SizedBox(height: itemSpacing),
                  // Selected items
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMobile ? 'Items:' : 'Productos seleccionados:',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 8),
                        if (isMobile && selectedItems.length > 3)
                          // Mobile: Show condensed view for many items
                          Column(
                            children: [
                              ...selectedItems.take(2).map((item) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: AppTextStyles.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '€${(item.price / item.selectedBy.length).toStringAsFixed(2)}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (selectedItems.length > 2)
                                Text(
                                  '... y ${selectedItems.length - 2} más',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          )
                        else
                          // Desktop/Tablet: Show all items
                          ...selectedItems.map((item) => 
                            Padding(
                              padding: EdgeInsets.only(bottom: isMobile ? 4 : 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '€${(item.price / item.selectedBy.length).toStringAsFixed(2)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: itemSpacing),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRemoveDialog(context),
                        icon: Icon(
                          Icons.person_remove,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          isMobile ? 'Quitar' : 'Quitar Participante',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 8 : 12,
                            horizontal: isMobile ? 8 : 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: itemSpacing),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(context, payment),
                        icon: Icon(
                          isPaid ? Icons.edit : Icons.payment,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          isPaid 
                            ? (isMobile ? 'Editar' : 'Editar Pago')
                            : (isMobile ? 'Pagar' : 'Marcar Pago'),
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaid ? AppColors.secondary : AppColors.success,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 8 : 12,
                            horizontal: isMobile ? 8 : 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Participante'),
        content: Text('¿Estás seguro de que quieres quitar a ${billProvider.getParticipantName(participantId)} de la cuenta?'),
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
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${payment.isPaid ? 'Editar' : 'Registrar'} Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Participante: ${payment.participantName}'),
            const SizedBox(height: 8),
            Text('Monto: €${payment.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            if (!payment.isPaid)
              const Text('¿Marcar como pagado?')
            else
              const Text('¿Marcar como pendiente?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              billProvider.togglePaymentStatus(payment.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: payment.isPaid ? AppColors.warning : AppColors.success,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text(payment.isPaid ? 'Marcar Pendiente' : 'Marcar Pagado'),
          ),
        ],
      ),
    );
  }
}
