import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/providers/auth_provider.dart';
import 'package:tickeo/screens/bill_details_screen.dart';
import 'package:tickeo/screens/camera_scanner_screen.dart';
import 'package:tickeo/screens/join_bill_screen.dart';
import 'package:tickeo/screens/analytics_screen.dart';
import 'package:tickeo/screens/profile_screen.dart';
import 'package:tickeo/screens/auth_screen.dart';
import 'package:tickeo/widgets/custom_button.dart';
import 'package:tickeo/widgets/bill_history_card.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/utils/validators.dart';
import 'package:tickeo/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _billNameController = TextEditingController();

  @override
  void dispose() {
    _billNameController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    try {
      // Show camera scanner screen for ticket scanning
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const CameraScannerScreen(scanType: 'ticket'),
        ),
      );

      if (result != null && mounted) {
        // Ask for bill name
        final billName = await _showBillNameDialog();
        if (billName != null && billName.isNotEmpty) {
          final billProvider = Provider.of<BillProvider>(context, listen: false);
          
          // Create bill from OCR result
          await billProvider.createBillFromOCRResult(billName, result);

          if (billProvider.currentBill != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BillDetailsScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        await NotificationService.showConfirmationDialog(
          context: context,
          title: 'Error de Escaneo',
          message: 'No se pudo escanear el ticket. Intenta de nuevo.',
          confirmText: 'OK',
          cancelText: '',
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    // Web-compatible version: simulate image picking
    final billName = await _showBillNameDialog();
    if (billName != null && billName.isNotEmpty) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      await billProvider.createBillFromMockOCR(billName);

      if (billProvider.currentBill != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BillDetailsScreen(),
          ),
        );
      }
    }
  }

  Future<void> _createManualBill() async {
    final billName = await _showBillNameDialog();
    if (billName != null && billName.isNotEmpty) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      await billProvider.createManualBill(billName);

      if (billProvider.currentBill != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BillDetailsScreen(),
          ),
        );
      }
    }
  }

  Future<String?> _showBillNameDialog() async {
    String? errorText;
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(
                    'Nombre de la Cuenta',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      TextField(
                        controller: _billNameController,
                        style: TextStyle(fontSize: isMobile ? 16 : 14),
                        decoration: InputDecoration(
                          hintText: 'ej: Cena en Restaurante',
                          hintStyle: TextStyle(
                            fontSize: isMobile ? 16 : 14,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: BorderSide(color: AppColors.error, width: 2),
                          ),
                          errorText: errorText,
                          helperText: 'Introduce un nombre para tu cuenta',
                          helperStyle: TextStyle(
                            fontSize: isMobile ? 12 : 11,
                          ),
                          errorStyle: TextStyle(
                            fontSize: isMobile ? 12 : 11,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 14 : 16,
                            vertical: isMobile ? 18 : 16,
                          ),
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            errorText = Validators.validateBillName(value);
                          });
                        },
                        onSubmitted: (value) {
                          if (errorText == null && value.trim().isNotEmpty) {
                            final billName = value.trim();
                            _billNameController.clear();
                            Navigator.of(context).pop(billName);
                          }
                        },
                      ),
                      ],
                    ),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 24,
                    isMobile ? 16 : 20,
                    isMobile ? 20 : 24,
                    isMobile ? 8 : 12,
                  ),
                  actionsPadding: EdgeInsets.fromLTRB(
                    isMobile ? 12 : 16,
                    0,
                    isMobile ? 12 : 16,
                    isMobile ? 12 : 16,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        _billNameController.clear();
                        Navigator.of(context).pop(null);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 12,
                          vertical: isMobile ? 12 : 8,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(fontSize: isMobile ? 16 : 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: errorText == null && _billNameController.text.trim().isNotEmpty
                          ? () {
                              final billName = _billNameController.text.trim();
                              _billNameController.clear();
                              Navigator.of(context).pop(billName);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size(isMobile ? 80 : 64, isMobile ? 44 : 36),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 12,
                          vertical: isMobile ? 12 : 8,
                        ),
                      ),
                      child: Text(
                        'Crear',
                        style: TextStyle(fontSize: isMobile ? 16 : 14),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tickeo',
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                      break;
                    case 'analytics':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                      break;
                    case 'auth':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                      break;
                    case 'tips':
                      NotificationService.showTipsDialog(context: context);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          authProvider.isAuthenticated 
                            ? Icons.account_circle 
                            : Icons.account_circle_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          authProvider.isAuthenticated 
                            ? 'Mi Perfil' 
                            : 'Perfil (Invitado)',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'analytics',
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined),
                        SizedBox(width: 8),
                        Text('Analytics'),
                      ],
                    ),
                  ),
                  if (!authProvider.isAuthenticated)
                    const PopupMenuItem<String>(
                      value: 'auth',
                      child: Row(
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 8),
                          Text('Iniciar Sesión'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'tips',
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline),
                        SizedBox(width: 8),
                        Text('Tips & Tricks'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isTablet = screenWidth > 600;
              final isMobile = screenWidth < 600;
              
              // Responsive padding and sizing
              final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 40.0);
              final verticalPadding = isMobile ? 16.0 : 24.0;
              final maxContentWidth = isTablet ? 800.0 : double.infinity;
              final buttonSpacing = isMobile ? 12.0 : 16.0;
              final sectionSpacing = isMobile ? 24.0 : 32.0;
              
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome section
                        Container(
                          padding: EdgeInsets.all(isMobile ? 20 : 24),
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
                                style: isMobile 
                                  ? AppTextStyles.headingMedium 
                                  : AppTextStyles.heading1,
                              ),
                              SizedBox(height: isMobile ? 6 : 8),
                              Text(
                                'Divide cuentas fácilmente escaneando tickets o creando cuentas manuales.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: sectionSpacing),

                        // Action buttons section
                        Text(
                          'Crear Nueva Cuenta',
                          style: isMobile 
                            ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                            : AppTextStyles.headingMedium,
                        ),
                        SizedBox(height: buttonSpacing),

                        // Responsive button layout
                        if (isMobile) ...[
                          // Mobile: Single column layout
                          CustomButton(
                            text: 'Escanear Ticket',
                            icon: Icons.camera_alt,
                            onPressed: _scanReceipt,
                            backgroundColor: AppColors.primary,
                            height: 52,
                          ),
                          SizedBox(height: buttonSpacing),
                          CustomButton(
                            text: 'Seleccionar de Galería',
                            icon: Icons.photo_library,
                            onPressed: _pickImageFromGallery,
                            backgroundColor: AppColors.secondary,
                            height: 52,
                          ),
                          SizedBox(height: buttonSpacing),
                          CustomButton(
                            text: 'Crear Manualmente',
                            icon: Icons.edit,
                            onPressed: _createManualBill,
                            backgroundColor: AppColors.accent,
                            height: 52,
                          ),
                          SizedBox(height: buttonSpacing),
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
                            height: 52,
                          ),
                        ] else ...[
                          // Tablet/Desktop: Two column layout
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Escanear Ticket',
                                  icon: Icons.camera_alt,
                                  onPressed: _scanReceipt,
                                  backgroundColor: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: buttonSpacing),
                              Expanded(
                                child: CustomButton(
                                  text: 'Seleccionar de Galería',
                                  icon: Icons.photo_library,
                                  onPressed: _pickImageFromGallery,
                                  backgroundColor: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: buttonSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Crear Manualmente',
                                  icon: Icons.edit,
                                  onPressed: _createManualBill,
                                  backgroundColor: AppColors.accent,
                                ),
                              ),
                              SizedBox(width: buttonSpacing),
                              Expanded(
                                child: CustomButton(
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
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: sectionSpacing),

                        // Recent bills section
                        if (billProvider.billHistory.isNotEmpty) ...[
                          Text(
                            'Cuentas Recientes',
                            style: isMobile 
                              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                              : AppTextStyles.headingMedium,
                          ),
                          SizedBox(height: buttonSpacing),
                          
                          // Responsive grid for bill history
                          if (isTablet && billProvider.billHistory.length > 2)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 3,
                              ),
                              itemCount: billProvider.billHistory.length > 6
                                  ? 6
                                  : billProvider.billHistory.length,
                              itemBuilder: (context, index) {
                                final bill = billProvider.billHistory[index];
                                return BillHistoryCard(
                                  bill: bill,
                                  onTap: () {
                                    billProvider.loadBillFromShareCode(bill.shareCode);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const BillDetailsScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: billProvider.billHistory.length > 5
                                  ? 5
                                  : billProvider.billHistory.length,
                              itemBuilder: (context, index) {
                                final bill = billProvider.billHistory[index];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: buttonSpacing),
                                  child: BillHistoryCard(
                                    bill: bill,
                                    onTap: () {
                                      billProvider.loadBillFromShareCode(bill.shareCode);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const BillDetailsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                        ],

                        // Loading indicator
                        if (billProvider.isLoading)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: const CircularProgressIndicator(),
                            ),
                          ),

                        // Error message
                        if (billProvider.error != null)
                          Container(
                            margin: EdgeInsets.only(top: buttonSpacing),
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                                  size: isMobile ? 20 : 24,
                                ),
                                SizedBox(width: isMobile ? 8 : 12),
                                Expanded(
                                  child: Text(
                                    billProvider.error!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.error,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Bottom padding for safe area
                        SizedBox(height: isMobile ? 16 : 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
