/// Email service configuration EXAMPLE
/// 
/// INSTRUCTIONS:
/// 1. Copy this file to email_config.dart
/// 2. Replace the placeholder values with your real EmailJS credentials
/// 3. NEVER commit email_config.dart to git (it's in .gitignore)

class EmailConfig {
  // EmailJS Configuration
  // Get these from https://www.emailjs.com/
  static const String emailJsServiceId = 'YOUR_EMAILJS_SERVICE_ID';
  static const String emailJsTemplateId = 'YOUR_EMAILJS_TEMPLATE_ID';
  static const String emailJsPublicKey = 'YOUR_EMAILJS_PUBLIC_KEY';
  static const String emailJsPrivateKey = 'YOUR_EMAILJS_PRIVATE_KEY';

  // App Configuration
  static const String appName = 'Tickeo';
  static const String supportEmail = 'support@yourdomain.com';

  // Verification settings
  static const int codeExpirationMinutes = 10;
  static const int codeLength = 6;
}
