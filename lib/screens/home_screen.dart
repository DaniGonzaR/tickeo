import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/screens/bill_details_screen.dart';
import 'package:tickeo/screens/join_bill_screen.dart';
import 'package:tickeo/widgets/custom_button.dart';
import 'package:tickeo/widgets/bill_history_card.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _billNameController = TextEditingController();

  @override
  void dispose() {
    _billNameController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      await _showBillNameDialog((billName) async {
        final billProvider = Provider.of<BillProvider>(context, listen: false);
        await billProvider.createBillFromImage(
          File(image.path),
          billName,
        );

        if (billProvider.currentBill != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BillDetailsScreen(),
            ),
          );
        }
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      await _showBillNameDialog((billName) async {
        final billProvider = Provider.of<BillProvider>(context, listen: false);
        await billProvider.createBillFromImage(
          File(image.path),
          billName,
        );

        if (billProvider.currentBill != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BillDetailsScreen(),
            ),
          );
        }
      });
    }
  }

  Future<void> _createManualBill() async {
    await _showBillNameDialog((billName) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      billProvider.createManualBill(billName);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BillDetailsScreen(),
        ),
      );
    });
  }

  Future<void> _showBillNameDialog(Function(String) onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Nombre de la Cuenta',
            style: AppTextStyles.headingMedium,
          ),
          content: TextField(
            controller: _billNameController,
            decoration: const InputDecoration(
              hintText: 'Ej: Cena en restaurante',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                _billNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Crear'),
              onPressed: () {
                final billName = _billNameController.text.trim();
                if (billName.isNotEmpty) {
                  onConfirm(billName);
                  _billNameController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bill Splitter',
          style: AppTextStyles.headingLarge.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.secondary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: AppTextStyles.headingLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Divide cuentas fácilmente escaneando tickets o creando cuentas manuales.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Text(
                  'Crear Nueva Cuenta',
                  style: AppTextStyles.headingMedium,
                ),
                const SizedBox(height: 16),

                CustomButton(
                  text: 'Escanear Ticket',
                  icon: Icons.camera_alt,
                  onPressed: _scanReceipt,
                  backgroundColor: AppColors.primary,
                ),

                const SizedBox(height: 12),

                CustomButton(
                  text: 'Seleccionar de Galería',
                  icon: Icons.photo_library,
                  onPressed: _pickImageFromGallery,
                  backgroundColor: AppColors.secondary,
                ),

                const SizedBox(height: 12),

                CustomButton(
                  text: 'Crear Manualmente',
                  icon: Icons.edit,
                  onPressed: _createManualBill,
                  backgroundColor: AppColors.accent,
                ),

                const SizedBox(height: 12),

                CustomButton(
                  text: 'Unirse a Cuenta',
                  icon: Icons.group_add,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const JoinBillScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppColors.success,
                ),

                const SizedBox(height: 32),

                // Recent bills section
                if (billProvider.billHistory.isNotEmpty) ...[
                  Text(
                    'Cuentas Recientes',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: billProvider.billHistory.length > 5
                        ? 5
                        : billProvider.billHistory.length,
                    itemBuilder: (context, index) {
                      final bill = billProvider.billHistory[index];
                      return BillHistoryCard(
                        bill: bill,
                        onTap: () {
                          // Load bill and navigate to details
                          billProvider.loadBillFromShareCode(bill.shareCode);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BillDetailsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                // Loading indicator
                if (billProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Error message
                if (billProvider.error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            billProvider.error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
