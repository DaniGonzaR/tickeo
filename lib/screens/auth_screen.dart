import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/auth_provider.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';
import 'package:tickeo/utils/validators.dart';
import 'package:tickeo/utils/error_handler.dart';
import 'package:tickeo/widgets/validated_form_field.dart';
import 'package:tickeo/widgets/custom_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  
  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  
  // Register controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithEmailAndPassword(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (success && mounted) {
      ErrorHandler.showSuccess(context, '¡Bienvenido de vuelta!');
      Navigator.of(context).pop();
    } else if (mounted && authProvider.error != null) {
      ErrorHandler.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.createUserWithEmailAndPassword(
      _registerEmailController.text.trim(),
      _registerPasswordController.text,
      _registerNameController.text.trim(),
    );

    if (success && mounted) {
      ErrorHandler.showSuccess(context, '¡Cuenta creada exitosamente!');
      Navigator.of(context).pop();
    } else if (mounted && authProvider.error != null) {
      ErrorHandler.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleAnonymousAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signInAnonymously();
    
    if (mounted) {
      ErrorHandler.showSuccess(context, 'Acceso como invitado activado');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Acceso a Tickeo',
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Registrarse'),
          ],
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildLoginTab(authProvider),
              _buildRegisterTab(authProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginTab(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Welcome message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Bienvenido de vuelta!',
                    style: AppTextStyles.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para sincronizar tus cuentas en todos tus dispositivos',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Email field
            ValidatedFormField(
              controller: _loginEmailController,
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmail,
            ),
            
            const SizedBox(height: 16),
            
            // Password field
            ValidatedFormField(
              controller: _loginPasswordController,
              labelText: 'Contraseña',
              hintText: 'Tu contraseña',
              obscureText: _obscureLoginPassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
              ),
              validator: (value) => Validators.validatePassword(value ?? ''),
            ),
            
            const SizedBox(height: 24),
            
            // Login button
            CustomButton(
              text: 'Iniciar Sesión',
              icon: Icons.login,
              onPressed: authProvider.isLoading ? null : _handleLogin,
              backgroundColor: AppColors.primary,
              isLoading: authProvider.isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Anonymous access button
            CustomButton(
              text: 'Continuar como Invitado',
              icon: Icons.person_outline,
              onPressed: authProvider.isLoading ? null : _handleAnonymousAccess,
              backgroundColor: AppColors.secondary,
              isLoading: authProvider.isLoading,
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Welcome message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Únete a Tickeo!',
                    style: AppTextStyles.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu cuenta para guardar y sincronizar tus cuentas',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Name field
            ValidatedFormField(
              controller: _registerNameController,
              labelText: 'Nombre completo',
              hintText: 'Tu nombre',
              prefixIcon: Icons.person_outline,
              validator: (value) => Validators.validateParticipantName(value ?? ''),
            ),
            
            const SizedBox(height: 16),
            
            // Email field
            ValidatedFormField(
              controller: _registerEmailController,
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmail,
            ),
            
            const SizedBox(height: 16),
            
            // Password field
            ValidatedFormField(
              controller: _registerPasswordController,
              labelText: 'Contraseña',
              hintText: 'Mínimo 6 caracteres',
              obscureText: _obscureRegisterPassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureRegisterPassword = !_obscureRegisterPassword;
                  });
                },
              ),
              validator: (value) => Validators.validatePassword(value ?? ''),
            ),
            
            const SizedBox(height: 16),
            
            // Confirm password field
            ValidatedFormField(
              controller: _confirmPasswordController,
              labelText: 'Confirmar contraseña',
              hintText: 'Repite tu contraseña',
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor confirma tu contraseña';
                }
                if (value != _registerPasswordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Register button
            CustomButton(
              text: 'Crear Cuenta',
              icon: Icons.person_add,
              onPressed: authProvider.isLoading ? null : _handleRegister,
              backgroundColor: AppColors.secondary,
              isLoading: authProvider.isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Anonymous access button
            CustomButton(
              text: 'Continuar como Invitado',
              icon: Icons.person_outline,
              onPressed: authProvider.isLoading ? null : _handleAnonymousAccess,
              backgroundColor: AppColors.primary,
              isLoading: authProvider.isLoading,
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
