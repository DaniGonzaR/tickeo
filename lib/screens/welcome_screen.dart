import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/auth_provider.dart';
import 'package:tickeo/screens/auth_screen.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 48,
                    vertical: isMobile ? 32 : 48,
                  ),
                  child: Column(
                    children: [
                      // Logo and title section
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App logo/icon
                            Container(
                              width: isMobile ? 120 : 150,
                              height: isMobile ? 120 : 150,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                size: isMobile ? 60 : 75,
                                color: Colors.white,
                              ),
                            ),
                            
                            SizedBox(height: isMobile ? 24 : 32),
                            
                            // App name
                            Text(
                              'Tickeo',
                              style: isMobile 
                                ? AppTextStyles.heading1.copyWith(fontSize: 48)
                                : AppTextStyles.heading1.copyWith(fontSize: 64),
                            ),
                            
                            SizedBox(height: isMobile ? 12 : 16),
                            
                            // App description
                            Text(
                              'Divide cuentas fácilmente',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: isMobile ? 18 : 22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: isMobile ? 8 : 12),
                            
                            Text(
                              'Escanea tickets, agrega participantes y calcula automáticamente cuánto debe pagar cada persona.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: isMobile ? 14 : 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons section
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Continue without account button
                            CustomButton(
                              text: 'Usar sin cuenta',
                              icon: Icons.person_outline,
                              onPressed: authProvider.isLoading 
                                ? null 
                                : () async {
                                    await authProvider.continueWithoutAccount();
                                  },
                              backgroundColor: AppColors.primary,
                              height: isMobile ? 56 : 48,
                              isLoading: authProvider.isLoading,
                            ),
                            
                            SizedBox(height: isMobile ? 16 : 12),
                            
                            // Register/Login button
                            CustomButton(
                              text: 'Crear cuenta / Iniciar sesión',
                              icon: Icons.account_circle,
                              onPressed: authProvider.isLoading 
                                ? null 
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const AuthScreen(),
                                      ),
                                    );
                                  },
                              backgroundColor: AppColors.accent,
                              height: isMobile ? 56 : 48,
                            ),
                            
                            SizedBox(height: isMobile ? 32 : 24),
                            
                            // Benefits comparison
                            Container(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¿Qué opción elegir?',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 16 : 18,
                                    ),
                                  ),
                                  
                                  SizedBox(height: isMobile ? 12 : 16),
                                  
                                  // Without account benefits
                                  _buildBenefitRow(
                                    icon: Icons.flash_on,
                                    title: 'Sin cuenta',
                                    description: 'Uso inmediato, solo datos locales',
                                    isMobile: isMobile,
                                  ),
                                  
                                  SizedBox(height: isMobile ? 8 : 12),
                                  
                                  // With account benefits
                                  _buildBenefitRow(
                                    icon: Icons.cloud_sync,
                                    title: 'Con cuenta',
                                    description: 'Sincronización, historial, colaboración',
                                    isMobile: isMobile,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? 20 : 24,
          color: AppColors.primary,
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
