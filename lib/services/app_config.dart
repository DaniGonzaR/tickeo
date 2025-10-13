import 'package:flutter/foundation.dart';

/// Secure configuration service for API keys and sensitive data
/// Uses environment variables with secure fallbacks
class AppConfig {
  // EmailJS Configuration - NO default values for security
  static const String? emailJsServiceId = String.fromEnvironment('EMAILJS_SERVICE_ID');
  static const String? emailJsTemplateId = String.fromEnvironment('EMAILJS_TEMPLATE_ID');
  static const String? emailJsPublicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY');
  static const String? emailJsPrivateKey = String.fromEnvironment('EMAILJS_PRIVATE_KEY');

  // Firebase Configuration - NO default values for security
  static const String? firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String? firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String? firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String? firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  /// Check if EmailJS is properly configured
  static bool get isEmailJsConfigured {
    return emailJsServiceId != null &&
           emailJsTemplateId != null &&
           emailJsPublicKey != null &&
           emailJsPrivateKey != null &&
           emailJsServiceId!.isNotEmpty &&
           emailJsTemplateId!.isNotEmpty &&
           emailJsPublicKey!.isNotEmpty &&
           emailJsPrivateKey!.isNotEmpty;
  }

  /// Check if Firebase is properly configured
  static bool get isFirebaseConfigured {
    return firebaseApiKey != null &&
           firebaseAppId != null &&
           firebaseProjectId != null &&
           firebaseMessagingSenderId != null &&
           firebaseApiKey!.isNotEmpty &&
           firebaseAppId!.isNotEmpty &&
           firebaseProjectId!.isNotEmpty &&
           firebaseMessagingSenderId!.isNotEmpty;
  }

  /// Get EmailJS configuration with validation
  static Map<String, String> getEmailJsConfig() {
    if (!isEmailJsConfigured) {
      throw Exception(
        'EmailJS not configured. Please set environment variables:\n'
        'EMAILJS_SERVICE_ID, EMAILJS_TEMPLATE_ID, EMAILJS_PUBLIC_KEY, EMAILJS_PRIVATE_KEY\n'
        'See .env.example for details.'
      );
    }

    return {
      'serviceId': emailJsServiceId!,
      'templateId': emailJsTemplateId!,
      'publicKey': emailJsPublicKey!,
      'privateKey': emailJsPrivateKey!,
    };
  }

  /// Get Firebase configuration with validation
  static Map<String, String> getFirebaseConfig() {
    if (!isFirebaseConfigured) {
      throw Exception(
        'Firebase not configured. Please set environment variables:\n'
        'FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_PROJECT_ID, FIREBASE_MESSAGING_SENDER_ID\n'
        'See .env.example for details.'
      );
    }

    return {
      'apiKey': firebaseApiKey!,
      'appId': firebaseAppId!,
      'projectId': firebaseProjectId!,
      'messagingSenderId': firebaseMessagingSenderId!,
    };
  }

  /// Debug configuration status (only in debug mode)
  static void debugConfigStatus() {
    if (kDebugMode) {
      print('=== AppConfig Status ===');
      print('EmailJS configured: $isEmailJsConfigured');
      print('Firebase configured: $isFirebaseConfigured');
      
      if (!isEmailJsConfigured) {
        print('Missing EmailJS environment variables');
      }
      
      if (!isFirebaseConfigured) {
        print('Missing Firebase environment variables');
      }
      print('========================');
    }
  }
}
