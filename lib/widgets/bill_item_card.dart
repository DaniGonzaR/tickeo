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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final cardPadding = isMobile ? 12.0 : 16.0;
        final itemSpacing = isMobile ? 8.0 : 12.0;
        final chipSpacing = isMobile ? 4.0 : 6.0;
        
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
                // Item header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: isMobile 
                          ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                          : AppTextStyles.headingSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: itemSpacing),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${item.price.toStringAsFixed(2)}',
                          style: isMobile 
                            ? AppTextStyles.priceMedium.copyWith(fontSize: 16)
                            : AppTextStyles.priceLarge,
                        ),
                        if (item.selectedBy.isNotEmpty)
                          Text(
                            isMobile 
                              ? 'Por persona: €${(item.price / item.selectedBy.length).toStringAsFixed(2)}'
                              : 'Precio por persona: €${(item.price / item.selectedBy.length).toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isMobile ? 11 : 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: itemSpacing),

                // Participants selection
                Text(
                  isMobile ? 'Seleccionado por:' : 'Seleccionado por participantes:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                
                SizedBox(height: chipSpacing),

                if (item.selectedBy.isEmpty)
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: AppColors.warning,
                          size: isMobile ? 16 : 18,
                        ),
                        SizedBox(width: chipSpacing),
                        Expanded(
                          child: Text(
                            isMobile 
                              ? 'Ningún participante seleccionado'
                              : 'Ningún participante ha seleccionado este producto',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontSize: isMobile ? 11 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Responsive participant chips layout
                  isMobile 
                    ? _buildMobileParticipantChips(chipSpacing)
                    : _buildDesktopParticipantChips(chipSpacing),

                SizedBox(height: itemSpacing),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: Icon(
                          Icons.delete_outline,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          isMobile ? 'Eliminar' : 'Eliminar Producto',
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
                        onPressed: () => _showParticipantSelectionDialog(context),
                        icon: Icon(
                          Icons.people,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          isMobile ? 'Asignar' : 'Asignar Participantes',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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

  Widget _buildMobileParticipantChips(double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.selectedBy.length <= 3)
          // Show all chips if 3 or fewer
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: item.selectedBy.map((participantId) {
              final name = getParticipantName(participantId);
              return Chip(
                label: Text(
                  name,
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          )
        else
          // Show first 2 and count for mobile
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  ...item.selectedBy.take(2).map((participantId) {
                    final name = getParticipantName(participantId);
                    return Chip(
                      label: Text(
                        name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }),
                  Chip(
                    label: Text(
                      '+${item.selectedBy.length - 2} más',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    side: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDesktopParticipantChips(double spacing) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: item.selectedBy.map((participantId) {
        final name = getParticipantName(participantId);
        return Chip(
          label: Text(name),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => billProvider.toggleParticipantForItem(item.id, participantId),
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${item.name}" de la cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              billProvider.removeItem(item.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showParticipantSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar "${item.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona los participantes que compartirán este producto:'),
              const SizedBox(height: 16),
              ...participants.map((participantId) {
                final name = getParticipantName(participantId);
                final isSelected = item.selectedBy.contains(participantId);
                return CheckboxListTile(
                  title: Text(name),
                  value: isSelected,
                  onChanged: (bool? value) {
                    billProvider.toggleParticipantForItem(item.id, participantId);
                    Navigator.of(context).pop();
                    // Reopen dialog to show updated state
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _showParticipantSelectionDialog(context);
                    });
                  },
                  activeColor: AppColors.primary,
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
