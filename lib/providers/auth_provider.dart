import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

      // Create new user
      _user = TickeoUser(
        uid: _uuid.v4(),
        email: email,
        displayName: displayName,
        isAnonymous: false,
      );

      // Store account in accounts list
      final prefs = await SharedPreferences.getInstance();
      final storedAccounts = prefs.getStringList('tickeo_accounts') ?? [];
      
      // Check if account already exists
      final existingAccount = storedAccounts.any((accountJson) {
        final accountData = jsonDecode(accountJson);
        return accountData['email'] == email;
      });
      
      if (existingAccount) {
        throw Exception('Ya existe una cuenta con este email');
      }
      
      // Add new account to list
      storedAccounts.add(jsonEncode(_user!.toJson()));
      await prefs.setStringList('tickeo_accounts', storedAccounts);
      
      // Store password securely (in real app, this would be hashed)
      await prefs.setString('password_${_user!.uid}', password);

      await _saveUserToStorage();
      await _markWelcomeAsSeen();
      
      // Send verification email (simulated)
      await _sendVerificationEmail();
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

  // Send verification email (simulated)
  Future<void> _sendVerificationEmail() async {
    if (_user?.email == null) return;
    
    try {
      // Simulate email sending delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In a real app, this would use Firebase Auth or email service
      debugPrint('Verification email sent to: ${_user!.email}');
      
      // For demo purposes, we'll show a success message
      // In production, this would actually send an email
    } catch (e) {
      debugPrint('Error sending verification email: $e');
    }
  }

  // Simulate email verification (for demo)
  Future<void> verifyEmail(String verificationCode) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo, accept any 6-digit code
      if (verificationCode.length == 6 && RegExp(r'^\d+$').hasMatch(verificationCode)) {
        // Update user as verified
        if (_user != null) {
          // In a real app, this would update the user's email verification status
          debugPrint('Email verified successfully for: ${_user!.email}');
        }
      } else {
        throw Exception('Código de verificación inválido');
      }
    } catch (e) {
      _setError('Error al verificar email: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    if (_user?.email == null) {
      _setError('No hay email para verificar');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _sendVerificationEmail();
    } catch (e) {
      _setError('Error al reenviar email de verificación: $e');
    } finally {
      _setLoading(false);
    }
  }
}
