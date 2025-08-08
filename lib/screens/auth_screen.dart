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
  
  // Password visibility
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
    await authProvider.signInWithEmailAndPassword(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (mounted) {
      if (authProvider.error == null) {
        ErrorHandler.showSuccess(context, '¡Bienvenido de vuelta!');
        Navigator.of(context).pop();
      } else {
        ErrorHandler.showError(context, authProvider.error!);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.createUserWithEmailAndPassword(
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
      displayName: _registerNameController.text.trim(),
    );

    if (mounted) {
      if (authProvider.error == null) {
        ErrorHandler.showSuccess(context, '¡Cuenta creada exitosamente!');
        Navigator.of(context).pop();
      } else {
        ErrorHandler.showError(context, authProvider.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Autenticación'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Registrarse'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(),
          _buildRegisterTab(),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.account_circle,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Bienvenido de vuelta!',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para sincronizar tus cuentas',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ValidatedFormField(
                  controller: _loginEmailController,
                  validator: Validators.validateEmail,
                  hintText: 'Ingresa tu email',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email),
                ),
                const SizedBox(height: 16),
                ValidatedFormField(
                  controller: _loginPasswordController,
                  validator: Validators.validatePassword,
                  hintText: 'Ingresa tu contraseña',
                  labelText: 'Contraseña',
                  obscureText: _obscureLoginPassword,
                  prefixIcon: const Icon(Icons.lock),
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
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Iniciar Sesión',
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  isLoading: authProvider.isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.person_add,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Crea tu cuenta!',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Registrate para sincronizar tus cuentas en todos tus dispositivos',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ValidatedFormField(
                  controller: _registerNameController,
                  validator: Validators.validateName,
                  hintText: 'Ingresa tu nombre',
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person),
                ),
                const SizedBox(height: 16),
                ValidatedFormField(
                  controller: _registerEmailController,
                  validator: Validators.validateEmail,
                  hintText: 'Ingresa tu email',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email),
                ),
                const SizedBox(height: 16),
                ValidatedFormField(
                  controller: _registerPasswordController,
                  validator: Validators.validatePassword,
                  hintText: 'Ingresa tu contraseña',
                  labelText: 'Contraseña',
                  obscureText: _obscureRegisterPassword,
                  prefixIcon: const Icon(Icons.lock),
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
                ),
                const SizedBox(height: 16),
                ValidatedFormField(
                  controller: _confirmPasswordController,
                  validator: (value) {
                    if (value != _registerPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return Validators.validatePassword(value);
                  },
                  hintText: 'Confirma tu contraseña',
                  labelText: 'Confirmar Contraseña',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
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
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Crear Cuenta',
                  onPressed: authProvider.isLoading ? null : _handleRegister,
                  isLoading: authProvider.isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
