import 'package:flutter/material.dart';
import 'package:tickeo/utils/app_colors.dart';

class AppTextStyles {
  // Usando fuentes del sistema en lugar de Poppins para evitar errores
  static const String _fontFamily = 'Roboto'; // Fuente del sistema

  // Headings
  static TextStyle get heading1 => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.2,
      );

  static TextStyle get heading2 => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.3,
      );

  static TextStyle get heading3 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.3,
      );

  static TextStyle get heading4 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  static TextStyle get heading5 => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  static TextStyle get heading6 => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  static TextStyle get headingSmall => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get headingMedium => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  // Body text
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  // Button text
  static TextStyle get buttonLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnPrimary,
        fontFamily: _fontFamily,
        letterSpacing: 0.3,
      );

  // Caption and labels
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        fontFamily: _fontFamily,
        height: 1.3,
      );

  static TextStyle get overline => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontFamily: _fontFamily,
        letterSpacing: 1.5,
        height: 1.6,
      );

  static TextStyle get label => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _fontFamily,
        height: 1.4,
      );

  // Price styles
  static TextStyle get priceMain => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontFamily: _fontFamily,
      );

  static TextStyle get priceSecondary => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        fontFamily: _fontFamily,
      );

  static TextStyle get priceMedium => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get priceLarge => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get priceSmall => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        fontFamily: _fontFamily,
      );

  // Status styles
  static TextStyle get statusPaid => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.success,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get statusPending => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.warning,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );

  static TextStyle get statusOverdue => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.error,
        fontFamily: _fontFamily,
        letterSpacing: 0.5,
      );
}
