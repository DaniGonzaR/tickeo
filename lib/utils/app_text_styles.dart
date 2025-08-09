import 'package:flutter/material.dart';
import 'package:tickeo/utils/app_colors.dart';

class AppTextStyles {
  // Usando fuentes del sistema en lugar de Poppins para evitar errores
  static const String _fontFamily = 'Roboto'; // Fuente del sistema

  // Headings
  static TextStyle get heading1 => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.2,
      );

  static TextStyle get heading2 => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.3,
      );

  static TextStyle get heading3 => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.3,
      );

  static TextStyle get heading4 => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  static TextStyle get heading5 => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  static TextStyle get heading6 => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  // Body text
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.5,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  // Button text
  static TextStyle get buttonLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.3,
      );

  // Caption and labels
  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        fontFamily: _fontFamily,
        height: 1.3,
      );

  static TextStyle get overline => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontFamily: _fontFamily,
        letterSpacing: 1.5,
        height: 1.6,
      );

  static TextStyle get label => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  // Price styles
  static TextStyle get priceMain => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontFamily: _fontFamily,
      );

  static TextStyle get priceSecondary => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        fontFamily: _fontFamily,
      );

  static TextStyle get priceMedium => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get priceLarge => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get priceSmall => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        fontFamily: _fontFamily,
      );

  // Status styles
  static TextStyle get statusPaid => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.success,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get statusPending => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.warning,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get statusOverdue => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.error,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );
}
