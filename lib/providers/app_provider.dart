import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemTheme = true; // Nueva opción para seguir el tema del sistema
  String _selectedLanguage = 'es';
  bool _isFirstLaunch = true;
  bool _showOnboarding = true;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;
  String get selectedLanguage => _selectedLanguage;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get showOnboarding => _showOnboarding;

  AppProvider() {
    _loadPreferences();
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'es';
      _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
      _showOnboarding = prefs.getBool('showOnboarding') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    _useSystemTheme = false; // Al cambiar manualmente, desactivar tema del sistema
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('useSystemTheme', _useSystemTheme);
    } catch (e) {
      debugPrint('Error saving dark mode preference: $e');
    }
  }

  // Set dark mode
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    
    _isDarkMode = value;
    _useSystemTheme = false; // Al establecer manualmente, desactivar tema del sistema
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('useSystemTheme', _useSystemTheme);
    } catch (e) {
      debugPrint('Error saving dark mode preference: $e');
    }
  }

  // Set system theme preference
  Future<void> setUseSystemTheme(bool value) async {
    if (_useSystemTheme == value) return;
    
    _useSystemTheme = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useSystemTheme', _useSystemTheme);
    } catch (e) {
      debugPrint('Error saving system theme preference: $e');
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    if (_selectedLanguage == languageCode) return;
    
    _selectedLanguage = languageCode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', _selectedLanguage);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  // Mark first launch as completed
  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
    } catch (e) {
      debugPrint('Error saving first launch preference: $e');
    }
  }

  // Hide onboarding
  Future<void> hideOnboarding() async {
    _showOnboarding = false;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showOnboarding', false);
    } catch (e) {
      debugPrint('Error saving onboarding preference: $e');
    }
  }

  // Reset all preferences (for testing or user request)
  Future<void> resetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _isDarkMode = false;
      _useSystemTheme = true;
      _selectedLanguage = 'es';
      _isFirstLaunch = true;
      _showOnboarding = true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting preferences: $e');
    }
  }

  // Get theme mode based on preference
  ThemeMode get themeMode {
    if (_useSystemTheme) {
      return ThemeMode.system; // Seguir el tema del sistema
    }
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Language options
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
  };

  String get currentLanguageName {
    return supportedLanguages[_selectedLanguage] ?? 'Español';
  }
}
