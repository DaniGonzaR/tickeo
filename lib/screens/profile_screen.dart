import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/auth_provider.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/screens/auth_screen.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/utils/error_handler.dart';
import 'package:tickeo/widgets/custom_button.dart';
import 'package:tickeo/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _syncEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User info section
                _buildUserInfoSection(authProvider),
                
                const SizedBox(height: 32),
                
                // Settings section
                _buildSettingsSection(),
                
                const SizedBox(height: 32),
                
                // Data management section
                _buildDataManagementSection(),
                
                const SizedBox(height: 32),
                
                // Account actions section
                _buildAccountActionsSection(authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Icon(
              authProvider.isAuthenticated ? Icons.person : Icons.person_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User name
          Text(
            authProvider.isAuthenticated 
              ? (authProvider.user?.displayName ?? 'Usuario')
              : 'Invitado',
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // User email or status
          Text(
            authProvider.isAuthenticated 
              ? (authProvider.user?.email ?? '')
              : 'Acceso temporal sin cuenta',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: authProvider.isAuthenticated 
                ? AppColors.success.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: authProvider.isAuthenticated 
                  ? AppColors.success
                  : AppColors.warning,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  authProvider.isAuthenticated ? Icons.verified_user : Icons.info_outline,
                  size: 16,
                  color: authProvider.isAuthenticated 
                    ? AppColors.success
                    : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  authProvider.isAuthenticated ? 'Cuenta Verificada' : 'Acceso Temporal',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: authProvider.isAuthenticated 
                      ? AppColors.success
                      : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: AppTextStyles.headingMedium,
        ),
        
        const SizedBox(height: 16),
        
        // Sync setting
        _buildSettingTile(
          icon: Icons.sync,
          title: 'Sincronización automática',
          subtitle: 'Sincronizar cuentas entre dispositivos',
          value: _syncEnabled,
          onChanged: (value) {
            setState(() {
              _syncEnabled = value;
            });
            ErrorHandler.showSuccess(
              context, 
              value ? 'Sincronización activada' : 'Sincronización desactivada'
            );
          },
        ),
        
        // Notifications setting
        _buildSettingTile(
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          subtitle: 'Recordatorios de pagos pendientes',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
            ErrorHandler.showSuccess(
              context, 
              value ? 'Notificaciones activadas' : 'Notificaciones desactivadas'
            );
          },
        ),
        
        // Dark mode setting
        _buildSettingTile(
          icon: Icons.dark_mode_outlined,
          title: 'Modo oscuro',
          subtitle: 'Tema oscuro para la aplicación',
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() {
              _darkModeEnabled = value;
            });
            ErrorHandler.showSuccess(
              context, 
              value ? 'Modo oscuro activado' : 'Modo claro activado'
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Datos',
          style: AppTextStyles.headingMedium,
        ),
        
        const SizedBox(height: 16),
        
        // Sync data button
        CustomButton(
          text: 'Sincronizar Datos',
          icon: Icons.cloud_sync,
          onPressed: _handleSyncData,
          backgroundColor: AppColors.primary,
        ),
        
        const SizedBox(height: 12),
        
        // Export data button
        CustomButton(
          text: 'Exportar Datos',
          icon: Icons.download,
          onPressed: _handleExportData,
          backgroundColor: AppColors.secondary,
        ),
        
        const SizedBox(height: 12),
        
        // Clear local data button
        CustomButton(
          text: 'Limpiar Datos Locales',
          icon: Icons.delete_outline,
          onPressed: _handleClearLocalData,
          backgroundColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuenta',
          style: AppTextStyles.headingMedium,
        ),
        
        const SizedBox(height: 16),
        
        if (!authProvider.isAuthenticated) ...[
          // Login/Register button for anonymous users
          CustomButton(
            text: 'Crear Cuenta / Iniciar Sesión',
            icon: Icons.person_add,
            onPressed: () => _navigateToAuth(),
            backgroundColor: AppColors.primary,
          ),
          
          const SizedBox(height: 12),
          
          // Convert account button
          CustomButton(
            text: 'Convertir a Cuenta Permanente',
            icon: Icons.upgrade,
            onPressed: () => _handleConvertAccount(authProvider),
            backgroundColor: AppColors.secondary,
          ),
        ] else ...[
          // Logout button for authenticated users
          CustomButton(
            text: 'Cerrar Sesión',
            icon: Icons.logout,
            onPressed: () => _handleSignOut(authProvider),
            backgroundColor: AppColors.error,
          ),
        ],
        
        const SizedBox(height: 20),
        
        // App info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                'Tickeo v1.0.0',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'División inteligente de cuentas',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );
  }

  Future<void> _handleSyncData() async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    
    try {
      // Simulate sync process
      await Future.delayed(const Duration(seconds: 2));
      await billProvider.syncBillsWithCloud();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Datos sincronizados correctamente');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Error al sincronizar: $e');
      }
    }
  }

  Future<void> _handleExportData() async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    
    try {
      await billProvider.downloadBillsFromCloud();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Datos exportados correctamente');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Error al exportar: $e');
      }
    }
  }

  Future<void> _handleClearLocalData() async {
    final confirmed = await NotificationService.showConfirmationDialog(
      context: context,
      title: '¿Limpiar datos locales?',
      message: 'Esta acción eliminará todas las cuentas guardadas localmente. Los datos en la nube no se verán afectados.',
      confirmText: 'Limpiar',
      cancelText: 'Cancelar',
    );

    if (confirmed == true) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      await billProvider.clearLocalData();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Datos locales limpiados');
      }
    }
  }

  Future<void> _handleConvertAccount(AuthProvider authProvider) async {
    final confirmed = await NotificationService.showConfirmationDialog(
      context: context,
      title: '¿Convertir a cuenta permanente?',
      message: 'Esto te permitirá acceder a tus datos desde cualquier dispositivo y mantener tu historial de cuentas.',
      confirmText: 'Convertir',
      cancelText: 'Más tarde',
    );

    if (confirmed == true) {
      _navigateToAuth();
    }
  }

  Future<void> _handleSignOut(AuthProvider authProvider) async {
    final confirmed = await NotificationService.showConfirmationDialog(
      context: context,
      title: '¿Cerrar sesión?',
      message: 'Tus datos locales se mantendrán, pero necesitarás iniciar sesión nuevamente para sincronizar.',
      confirmText: 'Cerrar Sesión',
      cancelText: 'Cancelar',
    );

    if (confirmed == true) {
      await authProvider.signOut();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Sesión cerrada correctamente');
        Navigator.of(context).pop();
      }
    }
  }
}
