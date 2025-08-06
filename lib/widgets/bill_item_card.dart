import 'package:flutter/material.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class BillItemCard extends StatelessWidget {
  final BillItem item;
  final List<String> participants;
  final BillProvider billProvider;
  final String Function(String) getParticipantName;

  const BillItemCard({
    super.key,
    required this.item,
    required this.participants,
    required this.billProvider,
    required this.getParticipantName,
  });

  @override
  Widget build(BuildContext context) {
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
            // Item header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.headingSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${item.price.toStringAsFixed(2)}',
                          style: AppTextStyles.priceMedium,
                        ),
                        if (item.quantity > 1)
                          Text(
                            'x${item.quantity}',
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ),
                    // Delete button - only show if no payments have been made
                    if (!billProvider.hasAnyPaymentBeenMade()) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () => _showDeleteConfirmation(context),
                        tooltip: 'Eliminar producto',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Selection info
            if (item.selectedBy.isNotEmpty) ...[
              Text(
                'Seleccionado por:',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item.selectedBy.map((participantId) {
                  return Chip(
                    label: Text(
                      getParticipantName(participantId),
                      style: AppTextStyles.bodySmall,
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      billProvider.toggleItemSelection(item.id, participantId);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (item.selectedBy.length > 1)
                Text(
                  'Precio por persona: \$${item.getPricePerPerson().toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No seleccionado por ningún participante',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Participants selection
            if (participants.isNotEmpty) ...[
              Text(
                'Seleccionar participantes:',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: participants.map((participantId) {
                  final isSelected = item.selectedBy.contains(participantId);
                  return FilterChip(
                    label: Text(
                      getParticipantName(participantId),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      billProvider.toggleItemSelection(item.id, participantId);
                    },
                    backgroundColor: AppColors.surfaceVariant,
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.textOnPrimary,
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agrega participantes para poder seleccionar quién consumió este producto',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
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
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Producto',
          style: AppTextStyles.headingMedium,
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${item.name}"?\n\nEsta acción no se puede deshacer.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              billProvider.removeItem(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
