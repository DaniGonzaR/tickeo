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

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }

    return null;
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
