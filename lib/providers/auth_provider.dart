import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tickeo/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && !_user!.isAnonymous;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in anonymously for users without account
  Future<void> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.signInAnonymously();
    } catch (e) {
      _setError('Error en autenticación: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      _setError('Error en inicio de sesión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create account with email and password
  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final userCredential =
          await _firebaseService.createUserWithEmailAndPassword(
        email,
        password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Save user profile
      await _firebaseService.saveUserProfile({
        'displayName': displayName,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Error creando cuenta: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Convert anonymous account to permanent account
  Future<bool> convertAnonymousAccount(
    String email,
    String password,
    String displayName,
  ) async {
    if (_user == null || !_user!.isAnonymous) {
      _setError('No hay cuenta anónima para convertir');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Create email credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link anonymous account with email credential
      await _user!.linkWithCredential(credential);

      // Update display name
      await _user!.updateDisplayName(displayName);

      // Save user profile
      await _firebaseService.saveUserProfile({
        'displayName': displayName,
        'email': email,
        'convertedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Error convirtiendo cuenta: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.signOut();
    } catch (e) {
      _setError('Error cerrando sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _setError('Error enviando email de recuperación: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      return await _firebaseService.getUserProfile();
    } catch (e) {
      _setError('Error obteniendo perfil: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.saveUserProfile(userData);
      return true;
    } catch (e) {
      _setError('Error actualizando perfil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  String get userDisplayName {
    if (_user?.displayName?.isNotEmpty == true) {
      return _user!.displayName!;
    }
    if (_user?.email?.isNotEmpty == true) {
      return _user!.email!.split('@').first;
    }
    return 'Usuario';
  }

  String get userEmail => _user?.email ?? '';
}
