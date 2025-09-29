import 'package:flutter/material.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/utils/validators.dart';
import 'package:tickeo/utils/error_handler.dart';

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

        final isCompleted = billProvider.currentBill?.isCompleted ?? false;

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
                            ? AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold)
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
                  isMobile
                      ? 'Seleccionado por:'
                      : 'Seleccionado por participantes:',
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
                      border:
                          Border.all(color: AppColors.warning.withOpacity(0.3)),
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
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isCompleted ? null : () => _showDeleteConfirmation(context),
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
                              side: const BorderSide(color: AppColors.error),
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
                            onPressed: isCompleted ? null : () =>
                                _showParticipantSelectionDialog(context),
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
                    SizedBox(height: itemSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (isCompleted || participants.isEmpty) 
                            ? null 
                            : () => billProvider.splitItemEqually(item.id),
                        icon: Icon(
                          Icons.balance,
                          size: isMobile ? 16 : 18,
                        ),
                        label: Text(
                          isMobile ? 'Dividir Equitativamente' : 'Dividir Equitativamente',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
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
                      side:
                          BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }),
                  Chip(
                    label: Text(
                      '+${item.selectedBy.length - 2} más',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    side:
                        BorderSide(color: AppColors.secondary.withOpacity(0.3)),
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
    final isCompleted = billProvider.currentBill?.isCompleted ?? false;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: item.selectedBy.map((participantId) {
        final name = getParticipantName(participantId);
        final isParticipantPaid = billProvider.currentBill?.isParticipantPaid(participantId) ?? false;
        
        return Chip(
          label: Text(name),
          backgroundColor: isParticipantPaid 
              ? AppColors.success.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          side: BorderSide(
            color: isParticipantPaid 
                ? AppColors.success.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.3)
          ),
          deleteIcon: isParticipantPaid 
              ? Icon(Icons.check_circle, size: 16, color: AppColors.success)
              : const Icon(Icons.close, size: 16),
          onDeleted: (isCompleted || isParticipantPaid)
              ? null
              : () => billProvider.toggleParticipantForItem(
                    item.id, participantId,
                  ),
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
            '¿Estás seguro de que quieres eliminar "${item.name}" de la cuenta?'),
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

  void _showParticipantSelectionDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          return AlertDialog(
            title: Text('Asignar "${item.name}"'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Selecciona los participantes que compartirán este producto:'),
                  const SizedBox(height: 16),
                  // Always use the latest participants and updated item selection from provider
                  ...((billProvider.currentBill?.participants ?? participants)).map((participantId) {
                    final name = getParticipantName(participantId);
                    final currentItem = billProvider.currentBill?.items.firstWhere(
                          (it) => it.id == item.id,
                          orElse: () => item,
                        ) ??
                        item;
                    final currentSelectedBy = currentItem.selectedBy;
                    final isSelected = currentSelectedBy.contains(participantId);
                    final isParticipantPaid = billProvider.currentBill?.isParticipantPaid(participantId) ?? false;
                    
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Text(name),
                          if (isParticipantPaid) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(Pagado)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        if (billProvider.currentBill?.isCompleted == true) {
                          showDialog(
                            context: dialogContext,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Acción no permitida'),
                              content: const Text(
                                  'No se pueden modificar las selecciones una vez que la cuenta está completada.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Entendido'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        
                        // Check if participant has paid and is trying to be deselected
                        if (isParticipantPaid && isSelected && value == false) {
                          showDialog(
                            context: dialogContext,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Acción no permitida'),
                              content: Text(
                                  'No se puede quitar a $name de este producto porque ya ha confirmado su pago.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Entendido'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        
                        billProvider.toggleParticipantForItem(item.id, participantId);
                        // Refresh just the dialog UI
                        setState(() {});
                      },
                      activeColor: isParticipantPaid ? AppColors.success : AppColors.primary,
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  // Open Add Participant on top of this dialog, and refresh when done
                  _showAddParticipantInline(
                    dialogContext,
                    parentContext,
                    () => setState(() {}),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Añadir Participante'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddParticipantInline(
    BuildContext selectionDialogContext,
    BuildContext scaffoldContext,
    VoidCallback onAdded,
  ) {
    final TextEditingController controller = TextEditingController();
    String? errorText;
    showDialog(
      context: selectionDialogContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (innerCtx, setState) {
          return AlertDialog(
            title: const Text('Añadir Participante'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nombre del participante',
                hintText: 'Ej: Dani',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  errorText = Validators.validateParticipantName(value);
                });
              },
              onSubmitted: (_) {
                _submitAddParticipant(dialogContext, scaffoldContext, controller, errorText);
                onAdded();
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: (errorText == null && controller.text.trim().isNotEmpty)
                    ? () {
                        _submitAddParticipant(dialogContext, scaffoldContext, controller, errorText);
                        onAdded();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                child: const Text('Añadir'),
              ),
            ],
          );
        });
      },
    );
  }

  void _submitAddParticipant(
    BuildContext dialogContext,
    BuildContext scaffoldContext,
    TextEditingController controller,
    String? errorText,
  ) {
    final name = controller.text.trim();
    final validation = Validators.validateParticipantName(name);
    if (validation != null) {
      // Keep dialog open and show error using scaffold context
      ErrorHandler.showError(scaffoldContext, validation);
      return;
    }
    final success = billProvider.addParticipant(name);
    if (success) {
      ErrorHandler.showSuccess(scaffoldContext, 'Participante creado correctamente');
      Navigator.of(dialogContext).pop();
    } else {
      // Show provider error (e.g., duplicate name)
      final msg = billProvider.error ?? 'No se pudo crear el participante';
      ErrorHandler.showError(scaffoldContext, msg);
    }
  }
}
