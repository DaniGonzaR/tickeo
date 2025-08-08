import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/screens/bill_details_screen.dart';
import 'package:tickeo/screens/camera_scanner_screen.dart';
import 'package:tickeo/services/notification_service.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/widgets/custom_button.dart';

class JoinBillScreen extends StatefulWidget {
  const JoinBillScreen({super.key});

  @override
  State<JoinBillScreen> createState() => _JoinBillScreenState();
}

class _JoinBillScreenState extends State<JoinBillScreen> {
  final TextEditingController _shareCodeController = TextEditingController();
  final TextEditingController _participantNameController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _shareCodeController.dispose();
    _participantNameController.dispose();
    super.dispose();
  }

  Future<void> _joinBill() async {
    final shareCode = _shareCodeController.text.trim().toUpperCase();
    final participantName = _participantNameController.text.trim();

    if (shareCode.isEmpty) {
      _showErrorDialog('Por favor ingresa el código de la cuenta');
      return;
    }

    if (participantName.isEmpty) {
      _showErrorDialog('Por favor ingresa tu nombre');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final billProvider = Provider.of<BillProvider>(context, listen: false);

      // Load the bill from share code
      await billProvider.loadBillFromShareCode(shareCode);

      if (billProvider.currentBill != null) {
        // Add the participant to the bill
        billProvider.addParticipant(participantName);

        // Navigate to bill details
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const BillDetailsScreen(),
            ),
          );
        }
      } else {
        _showErrorDialog('No se encontró una cuenta con ese código');
      }
    } catch (e) {
      _showErrorDialog('Error al unirse a la cuenta: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error', style: AppTextStyles.headingMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unirse a Cuenta'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header illustration
            Container(
              height: 200,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Únete a una cuenta!',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa el código que te compartieron para unirte a la división de la cuenta',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Share code input
            Text(
              'Código de la Cuenta',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _shareCodeController,
              decoration: InputDecoration(
                hintText: 'Ej: ABC12345',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanQRCode,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                // Auto format to uppercase
                final cursorPosition = _shareCodeController.selection.start;
                _shareCodeController.value =
                    _shareCodeController.value.copyWith(
                  text: value.toUpperCase(),
                  selection: TextSelection.collapsed(offset: cursorPosition),
                );
              },
            ),

            const SizedBox(height: 24),

            // Participant name input
            Text(
              'Tu Nombre',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _participantNameController,
              decoration: const InputDecoration(
                hintText: 'Ingresa tu nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 32),

            // Join button
            CustomButton(
              text: 'Unirse a la Cuenta',
              icon: Icons.group_add,
              onPressed: _isLoading ? null : _joinBill,
              isLoading: _isLoading,
              backgroundColor: AppColors.success,
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Instrucciones',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Pide a quien creó la cuenta que te comparta el código\n'
                    '2. Ingresa el código de 8 caracteres en el campo de arriba\n'
                    '3. Escribe tu nombre para identificarte\n'
                    '4. ¡Listo! Podrás ver y seleccionar los productos que consumiste',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Alternative options
            Text(
              'Otras opciones',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 16),

            CustomButton(
              text: 'Escanear Código QR',
              icon: Icons.qr_code_scanner,
              onPressed: _scanQRCode,
              backgroundColor: AppColors.secondary,
              isOutlined: true,
            ),

            const SizedBox(height: 12),

            CustomButton(
              text: 'Crear Nueva Cuenta',
              icon: Icons.add,
              onPressed: () {
                Navigator.of(context).pop();
              },
              backgroundColor: AppColors.primary,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  // Scan QR code using camera scanner
  Future<void> _scanQRCode() async {
    try {
      // Show camera scanner screen for QR scanning
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const CameraScannerScreen(scanType: 'qr'),
        ),
      );

      if (result != null && mounted) {
        // Extract QR code data
        final qrData = result['qrData'] as String?;
        if (qrData != null && qrData.isNotEmpty) {
          // Auto-fill the share code field
          _shareCodeController.text = qrData.toUpperCase();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código QR escaneado: $qrData'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          // Show error if no QR data found
          await NotificationService.showConfirmationDialog(
            context: context,
            title: 'Error de Escaneo',
            message: 'No se pudo leer el código QR. Intenta de nuevo.',
            confirmText: 'OK',
            cancelText: '',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await NotificationService.showConfirmationDialog(
          context: context,
          title: 'Error de Escaneo',
          message: 'No se pudo escanear el código QR. Intenta de nuevo.',
          confirmText: 'OK',
          cancelText: '',
        );
      }
    }
  }
}
