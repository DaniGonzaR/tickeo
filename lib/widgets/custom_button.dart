import 'package:flutter/material.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
        final effectiveTextColor = textColor ?? AppColors.textOnPrimary;
        
        // Adaptive button dimensions
        final adaptiveHeight = isMobile ? 48.0 : height;
        final fontSize = isMobile ? 16.0 : 14.0;
        final iconSize = isMobile ? 20.0 : 18.0;
        final borderRadius = isMobile ? 8.0 : 12.0;
        final horizontalPadding = isMobile ? 20.0 : 16.0;

        return SizedBox(
          width: width ?? double.infinity,
          height: adaptiveHeight,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveBackgroundColor,
                        ),
                      ),
                    )
                  : (icon != null
                      ? Icon(icon, size: iconSize)
                      : const SizedBox.shrink()),
              label: Text(
                text,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: effectiveBackgroundColor,
                  fontSize: fontSize,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: effectiveBackgroundColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              ),
            )
          : ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveTextColor,
                        ),
                      ),
                    )
                  : (icon != null
                      ? Icon(icon, size: iconSize)
                      : const SizedBox.shrink()),
              label: Text(
                text,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: effectiveTextColor,
                  fontSize: fontSize,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBackgroundColor,
                foregroundColor: effectiveTextColor,
                elevation: 2,
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                textStyle: TextStyle(fontSize: fontSize),
              ),
            ),
        );
      },
    );
  }
}
