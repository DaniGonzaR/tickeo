import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utility class for input validation across the app
class Validators {
  /// Validate bill name
  static String? validateBillName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bill name is required';
    }

    if (value.trim().length < 2) {
      return 'Bill name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Bill name must be less than 50 characters';
    }

    // Check for invalid characters
    final validNameRegex = RegExp(r'^[a-zA-Z0-9\s\-_.,!()]+$');
    if (!validNameRegex.hasMatch(value.trim())) {
      return 'Bill name contains invalid characters';
    }

    return null;
  }

  /// Validate item name
  static String? validateItemName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }

    if (value.trim().isEmpty) {
      return 'Item name cannot be empty';
    }

    if (value.trim().length > 100) {
      return 'Item name must be less than 100 characters';
    }

    return null;
  }

  /// Validate price input
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    // Remove currency symbols and whitespace
    final cleanValue = value.trim().replaceAll(RegExp(r'[€,\s]'), '');

    // Check if it's a valid number
    final double? price = double.tryParse(cleanValue);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price == 0) {
      return 'Price must be greater than zero';
    }

    if (price > 99999.99) {
      return 'Price is too high (max: €99,999.99)';
    }

    // Check decimal places
    final decimalPlaces =
        cleanValue.contains('.') ? cleanValue.split('.')[1].length : 0;
    if (decimalPlaces > 2) {
      return 'Price can have maximum 2 decimal places';
    }

    return null;
  }

  /// Validate participant name
  static String? validateParticipantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Participant name is required';
    }

    if (value.trim().isEmpty) {
      return 'Participant name cannot be empty';
    }

    if (value.trim().length > 30) {
      return 'Participant name must be less than 30 characters';
    }

    // Check for basic valid characters (letters, numbers, spaces, common punctuation)
    final validNameRegex = RegExp(r'^[a-zA-Z0-9\s\-_.]+$');
    if (!validNameRegex.hasMatch(value.trim())) {
      return 'Participant name contains invalid characters';
    }

    return null;
  }

  /// Validate share code format
  static String? validateShareCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Share code is required';
    }

    final cleanCode = value.trim().toUpperCase();

    if (cleanCode.length < 4) {
      return 'Share code must be at least 4 characters';
    }

    if (cleanCode.length > 10) {
      return 'Share code must be less than 10 characters';
    }

    // Check for valid characters (alphanumeric only)
    final validCodeRegex = RegExp(r'^[A-Z0-9]+$');
    if (!validCodeRegex.hasMatch(cleanCode)) {
      return 'Share code can only contain letters and numbers';
    }

    return null;
  }

  /// Validate restaurant name (optional field)
  static String? validateRestaurantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    if (value.trim().length > 100) {
      return 'Restaurant name must be less than 100 characters';
    }

    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength with modern security practices
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    // Minimum length: 12 characters
    if (value.length < 12) {
      return 'La contraseña debe tener al menos 12 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña debe tener menos de 128 caracteres';
    }

    // Check for common/leaked passwords
    if (_isCommonPassword(value)) {
      return 'Esta contraseña es muy común. Usa una más segura';
    }

    // Check for sequential patterns
    if (_hasSequentialPattern(value)) {
      return 'Evita patrones secuenciales como "123456" o "abcdef"';
    }

    return null;
  }

  /// Get password strength assessment
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(
        score: 0,
        label: 'Muy débil',
        color: const Color(0xFFE53E3E),
        suggestions: ['Ingresa una contraseña'],
      );
    }

    int score = 0;
    List<String> suggestions = [];

    // Length scoring
    if (password.length >= 12) score += 2;
    else if (password.length >= 8) score += 1;
    else suggestions.add('Usa al menos 12 caracteres');

    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    else suggestions.add('Incluye letras minúsculas');

    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    else suggestions.add('Incluye letras mayúsculas (recomendado)');

    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    else suggestions.add('Incluye números (recomendado)');

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    else suggestions.add('Incluye símbolos (recomendado)');

    // Bonus for length
    if (password.length >= 16) score += 1;
    if (password.length >= 20) score += 1;

    // Penalty for common patterns
    if (_isCommonPassword(password)) score = 0;
    if (_hasSequentialPattern(password)) score = math.max(0, score - 2);

    // Determine strength
    String label;
    Color color;
    
    if (score >= 7) {
      label = 'Muy fuerte';
      color = const Color(0xFF38A169);
    } else if (score >= 5) {
      label = 'Fuerte';
      color = const Color(0xFF68D391);
    } else if (score >= 3) {
      label = 'Moderada';
      color = const Color(0xFFED8936);
    } else if (score >= 1) {
      label = 'Débil';
      color = const Color(0xFFE53E3E);
    } else {
      label = 'Muy débil';
      color = const Color(0xFFE53E3E);
    }

    return PasswordStrength(
      score: score,
      label: label,
      color: color,
      suggestions: suggestions,
    );
  }

  /// Check if password is in common passwords list
  static bool _isCommonPassword(String password) {
    final commonPasswords = {
      // Top common passwords in Spanish and English
      'password', 'contraseña', '123456789', '12345678', '1234567890',
      'qwertyuiop', 'asdfghjkl', 'zxcvbnm', 'admin', 'administrador',
      'usuario', 'user', 'guest', 'invitado', 'root', 'toor',
      'password123', 'contraseña123', '123456', '1234567', '12345',
      'qwerty', 'abc123', 'password1', 'admin123', 'letmein',
      'welcome', 'bienvenido', 'monkey', 'dragon', 'master',
      'superman', 'batman', 'spiderman', 'pokemon', 'naruto',
      'iloveyou', 'teamo', 'familia', 'family', 'love',
      // Common Spanish names and words
      'maria', 'jose', 'antonio', 'francisco', 'manuel',
      'david', 'daniel', 'carlos', 'jesus', 'alejandro',
      // Common patterns
      '111111', '000000', 'aaaaaa', 'qqqqqq', '121212',
      'barcelona', 'madrid', 'valencia', 'sevilla', 'bilbao',
    };
    
    return commonPasswords.contains(password.toLowerCase());
  }

  /// Check for sequential patterns
  static bool _hasSequentialPattern(String password) {
    final lowerPassword = password.toLowerCase();
    
    // Check for sequential numbers
    final sequences = [
      '0123456789', '1234567890', '9876543210',
      'abcdefghijklmnopqrstuvwxyz', 'zyxwvutsrqponmlkjihgfedcba',
      'qwertyuiopasdfghjklzxcvbnm', 'mnbvcxzlkjhgfdsapoiuytrewq',
    ];
    
    for (final sequence in sequences) {
      for (int i = 0; i <= sequence.length - 4; i++) {
        final subseq = sequence.substring(i, i + 4);
        if (lowerPassword.contains(subseq)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Validate name (for user registration)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final validNameRegex = RegExp(r'^[a-zA-Z\s\-]+$');
    if (!validNameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces and hyphens';
    }

    return null;
  }

  /// Parse and clean price input
  static double parsePrice(String value) {
    final cleanValue = value.trim().replaceAll(RegExp(r'[€$£¥,\s]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Format price for display
  static String formatPrice(double price) {
    return '€${price.toStringAsFixed(2)}';
  }

  /// Validate that at least one participant is selected for an item
  static String? validateItemAssignment(List<String> selectedParticipants) {
    if (selectedParticipants.isEmpty) {
      return 'At least one participant must be selected for this item';
    }
    return null;
  }

  /// Validate that bill has items before saving
  static ValidationResult validateBillForSaving({
    required String billName,
    required List<dynamic> items,
    required List<String> participants,
  }) {
    final errors = <String>[];

    // Validate bill name
    final nameError = validateBillName(billName);
    if (nameError != null) {
      errors.add(nameError);
    }

    // Check if bill has items
    if (items.isEmpty) {
      errors.add('Bill must have at least one item');
    }

    // Check if bill has participants
    if (participants.isEmpty) {
      errors.add('Bill must have at least one participant');
    }

    // Check if items have assignments
    bool hasUnassignedItems = false;
    for (final item in items) {
      if (item is Map && (item['selectedBy'] as List?)?.isEmpty == true) {
        hasUnassignedItems = true;
        break;
      }
    }

    if (hasUnassignedItems) {
      errors.add('All items must be assigned to at least one participant');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Check if string is numeric
  static bool isNumeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  /// Sanitize input to prevent XSS (basic)
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;');
  }
}

/// Result class for complex validations
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  String get firstError => errors.isNotEmpty ? errors.first : '';
  String get allErrors => errors.join('\n');
}

/// Password strength assessment result
class PasswordStrength {
  final int score;
  final String label;
  final Color color;
  final List<String> suggestions;

  const PasswordStrength({
    required this.score,
    required this.label,
    required this.color,
    required this.suggestions,
  });

  bool get isWeak => score < 3;
  bool get isModerate => score >= 3 && score < 5;
  bool get isStrong => score >= 5 && score < 7;
  bool get isVeryStrong => score >= 7;
}
