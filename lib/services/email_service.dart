import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tickeo/config/email_config.dart';

class EmailService {
  // EmailJS Configuration from EmailConfig
  static const String _serviceId = EmailConfig.emailJsServiceId;
  static const String _templateId = EmailConfig.emailJsTemplateId;
  static const String _publicKey = EmailConfig.emailJsPublicKey;
  static const String _privateKey = EmailConfig.emailJsPrivateKey;

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
            'app_name': EmailConfig.appName,
            'from_name': EmailConfig.appName,
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
