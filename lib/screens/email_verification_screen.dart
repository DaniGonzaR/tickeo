import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/auth_provider.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/utils/error_handler.dart';
import 'package:tickeo/widgets/custom_button.dart';
import 'package:tickeo/widgets/validated_form_field.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _verificationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isResending = false;

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.verifyEmail(_verificationCodeController.text.trim());

    if (mounted) {
      if (authProvider.error == null) {
        ErrorHandler.showSuccess(context, '¡Cuenta creada y verificada exitosamente!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ErrorHandler.showError(context, authProvider.error!);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendVerificationEmail();

    if (mounted) {
      setState(() => _isResending = false);
      
      if (authProvider.error == null) {
        ErrorHandler.showSuccess(context, 'Email de verificación reenviado');
      } else {
        ErrorHandler.showError(context, authProvider.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verificar Email'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final horizontalPadding = isMobile ? 24.0 : 48.0;
              
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email verification icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            'Verifica tu Email',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Description
                          Text(
                            'Hemos enviado un código de verificación de 6 dígitos a tu email. Tu cuenta se creará solo después de verificar el código:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Email display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              widget.email,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Verification code input
                          ValidatedFormField(
                            controller: _verificationCodeController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el código de verificación';
                              }
                              if (value.length != 6) {
                                return 'El código debe tener 6 dígitos';
                              }
                              if (!RegExp(r'^\d+$').hasMatch(value)) {
                                return 'El código solo debe contener números';
                              }
                              return null;
                            },
                            hintText: '123456',
                            labelText: 'Código de Verificación',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            prefixIcon: const Icon(Icons.security),
                            autofocus: true,
                          ),
                          const SizedBox(height: 24),
                          
                          // Verify button
                          CustomButton(
                            text: 'Verificar y Crear Cuenta',
                            onPressed: authProvider.isLoading ? null : _verifyEmail,
                            isLoading: authProvider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Resend email section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '¿No recibiste el código?',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _isResending ? null : _resendVerificationEmail,
                                  child: _isResending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Reenviar Código',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Skip verification (for demo)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            child: Text(
                              'Verificar más tarde',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          
                          // Info about verification
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Para esta demo, usa cualquier código de 6 dígitos (ej: 123456)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
