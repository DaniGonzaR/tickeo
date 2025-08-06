import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/models/bill_item.dart';
import 'package:tickeo/models/payment.dart';
import 'package:tickeo/widgets/custom_button.dart';
import 'package:tickeo/widgets/bill_item_card.dart';
import 'package:tickeo/widgets/participant_card.dart';
import 'package:tickeo/widgets/payment_summary_card.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class BillDetailsScreen extends StatefulWidget {
  const BillDetailsScreen({super.key});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _participantController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _participantController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _participantController.text.trim();
    if (name.isNotEmpty) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      billProvider.addParticipant(name);
      _participantController.clear();
      Navigator.of(context).pop();
    }
  }

  void _addManualItem() {
    final name = _itemNameController.text.trim();
    final priceText = _itemPriceController.text.trim();

    if (name.isNotEmpty && priceText.isNotEmpty) {
      final price = double.tryParse(priceText);
      if (price != null && price > 0) {
        final billProvider = Provider.of<BillProvider>(context, listen: false);
        final success = billProvider.addManualItem(name, price);
        if (!success && context.mounted) {
          // Error handling is done in the provider
          return;
        }
        _itemNameController.clear();
        _itemPriceController.clear();
        Navigator.of(context).pop();
      }
    }
  }

  void _updateTip() {
    final tipText = _tipController.text.trim();
    final tip = double.tryParse(tipText) ?? 0.0;

    final billProvider = Provider.of<BillProvider>(context, listen: false);
    billProvider.updateTip(tip);
    Navigator.of(context).pop();
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Participante', style: AppTextStyles.headingMedium),
        content: TextField(
          controller: _participantController,
          decoration: const InputDecoration(
            hintText: 'Nombre del participante',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _addParticipant,
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Producto', style: AppTextStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                hintText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _itemPriceController,
              decoration: const InputDecoration(
                hintText: 'Precio',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _addManualItem,
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showTipDialog() {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    _tipController.text = billProvider.currentBill?.tip.toString() ?? '0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Propina', style: AppTextStyles.headingMedium),
        content: TextField(
          controller: _tipController,
          decoration: const InputDecoration(
            hintText: 'Monto de propina',
            border: OutlineInputBorder(),
            prefixText: '\$',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _updateTip,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final bill = billProvider.currentBill;
    if (bill == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compartir Cuenta', style: AppTextStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Código de la cuenta:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bill.shareCode,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: bill.shareCode,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Share.share(
                'Únete a mi cuenta en Bill Splitter con el código: ${bill.shareCode}',
              );
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final bill = billProvider.currentBill;

        if (bill == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cuenta'),
            ),
            body: const Center(
              child: Text('No hay cuenta seleccionada'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(bill.name),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _showShareDialog,
              ),
              IconButton(
                icon: const Icon(Icons.cloud_upload),
                onPressed: billProvider.saveBillToCloud,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
              indicatorColor: AppColors.textOnPrimary,
              tabs: const [
                Tab(text: 'Productos', icon: Icon(Icons.receipt_long)),
                Tab(text: 'Participantes', icon: Icon(Icons.people)),
                Tab(text: 'Resumen', icon: Icon(Icons.account_balance_wallet)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Products Tab
              _buildProductsTab(bill, billProvider),
              // Participants Tab
              _buildParticipantsTab(bill, billProvider),
              // Summary Tab
              _buildSummaryTab(bill, billProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(Bill bill, BillProvider billProvider) {
    return Column(
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subtotal', style: AppTextStyles.bodyMedium),
                  Text('\$${bill.subtotal.toStringAsFixed(2)}',
                      style: AppTextStyles.priceMedium),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Impuestos', style: AppTextStyles.bodyMedium),
                  Text('\$${bill.tax.toStringAsFixed(2)}',
                      style: AppTextStyles.priceMedium),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Propina', style: AppTextStyles.bodyMedium),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: _showTipDialog,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Text('\$${bill.tip.toStringAsFixed(2)}',
                      style: AppTextStyles.priceMedium),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: AppTextStyles.bodyMedium),
                  Text('\$${bill.total.toStringAsFixed(2)}',
                      style: AppTextStyles.priceLarge),
                ],
              ),
            ],
          ),
        ),

        // Products list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bill.items.length,
            itemBuilder: (context, index) {
              final item = bill.items[index];
              return BillItemCard(
                item: item,
                participants: bill.participants,
                billProvider: billProvider,
                getParticipantName: billProvider.getParticipantName,
              );
            },
          ),
        ),

        // Add item button
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Agregar Producto',
            icon: Icons.add,
            onPressed: _showAddItemDialog,
            backgroundColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab(Bill bill, BillProvider billProvider) {
    return Column(
      children: [
        // Add participant button
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Agregar Participante',
            icon: Icons.person_add,
            onPressed: _showAddParticipantDialog,
            backgroundColor: AppColors.primary,
          ),
        ),

        // Participants list
        Expanded(
          child: bill.participants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay participantes',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega participantes para dividir la cuenta',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bill.participants.length,
                  itemBuilder: (context, index) {
                    final participantId = bill.participants[index];
                    return ParticipantCard(
                      participantId: participantId,
                      bill: bill,
                      billProvider: billProvider,
                    );
                  },
                ),
        ),

        // Split equally button
        if (bill.participants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'Dividir Equitativamente',
              icon: Icons.balance,
              onPressed: billProvider.splitBillEqually,
              backgroundColor: AppColors.accent,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryTab(Bill bill, BillProvider billProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentSummaryCard(
            bill: bill,
            billProvider: billProvider,
          ),
          const SizedBox(height: 16),
          if (bill.participants.isNotEmpty) ...[
            Text(
              'Detalle por Participante',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 16),
            ...bill.participants.map((participantId) {
              final payment = bill.payments.firstWhere(
                (p) => p.participantId == participantId,
                orElse: () => Payment(
                  id: '',
                  participantId: participantId,
                  participantName:
                      billProvider.getParticipantName(participantId),
                  amount: 0.0,
                  method: PaymentMethod.cash,
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        payment.isPaid ? AppColors.success : AppColors.warning,
                    child: Icon(
                      payment.isPaid ? Icons.check : Icons.schedule,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  title: Text(
                    payment.participantName,
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(
                    payment.isPaid
                        ? 'Pagado - ${payment.methodDisplayName}'
                        : 'Pendiente',
                    style: payment.isPaid
                        ? AppTextStyles.statusPaid
                        : AppTextStyles.statusPending,
                  ),
                  trailing: Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.priceMedium,
                  ),
                  onTap: () => _showPaymentDialog(payment, billProvider),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(Payment payment, BillProvider billProvider) {
    if (payment.isPaid) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar como Pagado', style: AppTextStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${payment.participantName} debe pagar \$${payment.amount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Método de pago:', style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              value: PaymentMethod.cash,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(_getPaymentMethodName(method)),
                );
              }).toList(),
              onChanged: (method) {
                if (method != null) {
                  billProvider.markPaymentAsPaid(
                    payment.participantId,
                    method,
                    null,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.digitalWallet:
        return 'Billetera Digital';
      case PaymentMethod.other:
        return 'Otro';
    }
  }
}
