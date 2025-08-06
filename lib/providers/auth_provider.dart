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
  final Uuid _uuid = const Uuid();
  
  TickeoUser? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  TickeoUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && !_user!.isAnonymous;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  String? get userDisplayName => _user?.displayName ?? _user?.email?.split('@').first;
  String? get userEmail => _user?.email;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _user = TickeoUser.fromJson(userData);
      }
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

  // Anonymous sign in
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
      
      // In a real app, this would authenticate with Firebase
      // For now, we'll create a user account locally
      _user = TickeoUser(
        uid: _uuid.v4(),
        email: email,
        displayName: email.split('@').first,
        isAnonymous: false,
      );
      await _saveUserToStorage();
    } catch (e) {
      _setError('Error al iniciar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create user with email/password (offline simulation)
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate account creation delay
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, this would create account with Firebase
      // For now, we'll create a user account locally
      _user = TickeoUser(
        uid: _uuid.v4(),
        email: email,
        displayName: displayName ?? email.split('@').first,
        isAnonymous: false,
      );
      await _saveUserToStorage();
    } catch (e) {
      _setError('Error al crear cuenta: $e');
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
      await _saveUserToStorage();
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
}
