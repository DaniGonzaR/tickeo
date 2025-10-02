import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmailService {
  // EmailJS Configuration - use environment variables for production
  static const String _serviceId = String.fromEnvironment('EMAILJS_SERVICE_ID', defaultValue: 'service_8yszrio');
  static const String _templateId = String.fromEnvironment('EMAILJS_TEMPLATE_ID', defaultValue: 'template_3y6t142');
  static const String _publicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY', defaultValue: 'aHizuvd5moHSyrDuP');
  static const String _privateKey = String.fromEnvironment('EMAILJS_PRIVATE_KEY', defaultValue: 'aQ8RbGG0HBtnG94TzOWuv');

  /// Generate a 6-digit verification code
  static String generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Store verification code temporarily
  static Future<void> _storeVerificationCode(String email, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('verification_code_$email', code);
    await prefs.setInt('verification_code_timestamp_$email', DateTime.now().millisecondsSinceEpoch);
  }

  /// Verify if the provided code matches the stored one
  static Future<bool> verifyCode(String email, String providedCode) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString('verification_code_$email');
    final timestamp = prefs.getInt('verification_code_timestamp_$email') ?? 0;
    
    // Check if code exists and is not expired (10 minutes)
    final now = DateTime.now().millisecondsSinceEpoch;
    final isExpired = (now - timestamp) > (10 * 60 * 1000); // 10 minutes
    
    if (storedCode == null || isExpired) {
      return false;
    }
    
    return storedCode == providedCode;
  }

  /// Send verification email using EmailJS
  static Future<bool> sendVerificationEmail(String email, String userName) async {
    try {
      final verificationCode = generateVerificationCode();
      await _storeVerificationCode(email, verificationCode);

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': {
            'to_email': email,
            'to_name': userName,
            'verification_code': verificationCode,
            'app_name': 'Tickeo',
            'from_name': 'Tickeo',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Verification email sent successfully to: $email');
        return true;
      } else {
        debugPrint('Failed to send email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return false;
    }
  }


  /// Clean up expired verification codes
  static Future<void> cleanupExpiredCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('verification_code_timestamp_')).toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final key in keys) {
      if (key.startsWith('verification_code_timestamp_')) {
        final timestamp = prefs.getInt(key) ?? 0;
        final isExpired = (now - timestamp) > (10 * 60 * 1000); // 10 minutes
        
        if (isExpired) {
          final email = key.replaceFirst('verification_code_timestamp_', '');
          await prefs.remove('verification_code_$email');
          await prefs.remove(key);
        }
      }
    }
  }
}
