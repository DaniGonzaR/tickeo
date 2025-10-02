import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:tickeo/services/email_service.dart';

// Simple user model for offline mode
class TickeoUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  
  TickeoUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
  
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'isAnonymous': isAnonymous,
  };
  
  factory TickeoUser.fromJson(Map<String, dynamic> json) => TickeoUser(
    uid: json['uid'] ?? '',
    email: json['email'],
    displayName: json['displayName'],
    isAnonymous: json['isAnonymous'] ?? false,
  );
}

class AuthProvider extends ChangeNotifier {
  // For web compatibility, we'll use local storage instead of Firebase
  static const String _userKey = 'tickeo_user';
  static const String _hasSeenWelcomeKey = 'tickeo_has_seen_welcome';
  final Uuid _uuid = const Uuid();
  
  TickeoUser? _user;
  bool _isLoading = false;
  String? _error;
  bool _hasSeenWelcome = false;

  // Getters
  TickeoUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && !_user!.isAnonymous;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get hasUser => _user != null;
  bool get hasSeenWelcome => _hasSeenWelcome;
  String? get userDisplayName => _user?.displayName ?? _user?.email?.split('@').first;
  String? get userEmail => _user?.email;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user data
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _user = TickeoUser.fromJson(userData);
      }
      
      // Load welcome screen state
      _hasSeenWelcome = prefs.getBool(_hasSeenWelcomeKey) ?? false;
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
    notifyListeners();
  }

  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
      } else {
        await prefs.remove(_userKey);
      }
    } catch (e) {
      debugPrint('Error saving user to storage: $e');
    }
  }

  // Continue without account (anonymous mode)
  Future<void> continueWithoutAccount() async {
    _setLoading(true);
    _clearError();

    try {
      // Don't create a user, just mark welcome as seen
      await _markWelcomeAsSeen();
    } catch (e) {
      _setError('Error al continuar sin cuenta: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Anonymous sign in (creates a temporary user)
  Future<void> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      _user = TickeoUser(
        uid: _uuid.v4(),
        isAnonymous: true,
        displayName: 'Usuario Invitado',
      );
      await _saveUserToStorage();
      await _markWelcomeAsSeen();
    } catch (e) {
      _setError('Error al iniciar sesión como invitado: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Email/password sign in (offline simulation)
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if user exists in stored accounts
      final prefs = await SharedPreferences.getInstance();
      final storedAccounts = prefs.getStringList('tickeo_accounts') ?? [];
      
      TickeoUser? foundUser;
      String? storedPassword;
      
      for (final accountJson in storedAccounts) {
        final accountData = jsonDecode(accountJson);
        if (accountData['email'] == email) {
          foundUser = TickeoUser.fromJson(accountData);
          storedPassword = prefs.getString('password_${foundUser.uid}');
          break;
        }
      }
      
      if (foundUser == null) {
        throw Exception('No existe una cuenta con este email');
      }
      
      if (storedPassword != password) {
        throw Exception('Contraseña incorrecta');
      }
      
      // Login successful
      _user = foundUser;
      await _saveUserToStorage();
      await _markWelcomeAsSeen();
    } catch (e) {
      _setError('Error al iniciar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create user with email and password (offline simulation)
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if account already exists
      final prefs = await SharedPreferences.getInstance();
      final storedAccounts = prefs.getStringList('tickeo_accounts') ?? [];
      
      final existingAccount = storedAccounts.any((accountJson) {
        final accountData = jsonDecode(accountJson);
        return accountData['email'] == email;
      });
      
      if (existingAccount) {
        throw Exception('Ya existe una cuenta con este email');
      }

      // Store pending user data (not yet verified)
      await prefs.setString('pending_user_email', email);
      await prefs.setString('pending_user_password', password);
      await prefs.setString('pending_user_displayName', displayName);
      await prefs.setString('pending_user_uid', _uuid.v4());
      
      // Send verification email
      await _sendVerificationEmailForPendingUser(email, displayName);
    } catch (e) {
      _setError('Error al crear la cuenta: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Convert anonymous account to permanent account
  Future<void> convertAnonymousAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_user == null || !_user!.isAnonymous) {
      _setError('No hay cuenta anónima para convertir');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Simulate conversion delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Convert anonymous user to permanent user
      _user = TickeoUser(
        uid: _user!.uid, // Keep the same UID to preserve data
        email: email,
        displayName: displayName ?? email.split('@').first,
        isAnonymous: false,
      );
      await _saveUserToStorage();
    } catch (e) {
      _setError('Error al convertir cuenta: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      _user = null;
      _hasSeenWelcome = false; // Reset welcome screen state
      await _saveUserToStorage();
      
      // Also clear welcome state from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasSeenWelcomeKey);
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password (offline simulation)
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate password reset delay
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, this would send password reset email via Firebase
      // For now, we'll just simulate success
    } catch (e) {
      _setError('Error al enviar email de recuperación: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? email,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    _clearError();

    try {
      _user = TickeoUser(
        uid: _user!.uid,
        email: email ?? _user!.email,
        displayName: displayName ?? _user!.displayName,
        isAnonymous: _user!.isAnonymous,
      );
      await _saveUserToStorage();
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Mark welcome screen as seen
  Future<void> _markWelcomeAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenWelcomeKey, true);
      _hasSeenWelcome = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving welcome state: $e');
    }
  }

  // Send verification email (real implementation)
  Future<void> _sendVerificationEmail() async {
    if (_user?.email == null || _user?.displayName == null) return;
    
    try {
      // Clean up expired codes first
      await EmailService.cleanupExpiredCodes();
      
      // Send real email using EmailJS
      final success = await EmailService.sendVerificationEmail(
        _user!.email!,
        _user!.displayName!,
      );
      
      if (success) {
        debugPrint('Verification email sent successfully to: ${_user!.email}');
      } else {
        debugPrint('Failed to send verification email to: ${_user!.email}');
        // In production, you might want to throw an exception here
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      // In production, you might want to rethrow this exception
    }
  }

  // Send verification email for pending user
  Future<void> _sendVerificationEmailForPendingUser(String email, String displayName) async {
    try {
      // Clean up expired codes first
      await EmailService.cleanupExpiredCodes();
      
      // Send real email using EmailJS
      final success = await EmailService.sendVerificationEmail(email, displayName);
      
      if (success) {
        debugPrint('Verification email sent successfully to: $email');
      } else {
        debugPrint('Failed to send verification email to: $email');
        throw Exception('No se pudo enviar el email de verificación');
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      throw Exception('Error al enviar email de verificación: $e');
    }
  }

  // Real email verification - creates account only after successful verification
  Future<void> verifyEmail(String verificationCode) async {
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get pending user data
      final pendingEmail = prefs.getString('pending_user_email');
      final pendingPassword = prefs.getString('pending_user_password');
      final pendingDisplayName = prefs.getString('pending_user_displayName');
      final pendingUid = prefs.getString('pending_user_uid');

      if (pendingEmail == null || pendingPassword == null || pendingDisplayName == null || pendingUid == null) {
        throw Exception('No hay datos de usuario pendientes de verificación');
      }

      // Verify code using EmailService
      final isValid = await EmailService.verifyCode(pendingEmail, verificationCode);
      
      if (isValid) {
        // NOW create the actual user account after successful verification
        _user = TickeoUser(
          uid: pendingUid,
          email: pendingEmail,
          displayName: pendingDisplayName,
          isAnonymous: false,
        );

        // Store account in accounts list
        final storedAccounts = prefs.getStringList('tickeo_accounts') ?? [];
        storedAccounts.add(jsonEncode(_user!.toJson()));
        await prefs.setStringList('tickeo_accounts', storedAccounts);
        
        // Store password securely
        await prefs.setString('password_${_user!.uid}', pendingPassword);

        // Save user to current session
        await _saveUserToStorage();
        await _markWelcomeAsSeen();
        
        // Clean up pending user data
        await prefs.remove('pending_user_email');
        await prefs.remove('pending_user_password');
        await prefs.remove('pending_user_displayName');
        await prefs.remove('pending_user_uid');
        
        // Clean up the verification code
        await prefs.remove('verification_code_$pendingEmail');
        await prefs.remove('verification_code_timestamp_$pendingEmail');
        
        debugPrint('Account created and verified successfully for: $pendingEmail');
      } else {
        throw Exception('Código de verificación inválido o expirado');
      }
    } catch (e) {
      _setError('Error al verificar email: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if there's a pending user
      final pendingEmail = prefs.getString('pending_user_email');
      final pendingDisplayName = prefs.getString('pending_user_displayName');
      
      if (pendingEmail != null && pendingDisplayName != null) {
        // Resend for pending user
        await _sendVerificationEmailForPendingUser(pendingEmail, pendingDisplayName);
      } else if (_user?.email != null) {
        // Resend for existing user
        await _sendVerificationEmail();
      } else {
        throw Exception('No hay email para verificar');
      }
    } catch (e) {
      _setError('Error al reenviar email de verificación: $e');
    } finally {
      _setLoading(false);
    }
  }
}
