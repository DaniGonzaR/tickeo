import 'package:flutter/material.dart';
import 'package:tickeo/utils/app_colors.dart';

/// A custom form field widget with built-in validation optimized for mobile
class ValidatedFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String hintText;
  final String? helperText;
  final String? labelText;
  final TextInputType keyboardType;
  final bool autofocus;
  final int? maxLength;
  final int maxLines;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;

  const ValidatedFormField({
    super.key,
    required this.controller,
    required this.validator,
    required this.hintText,
    this.helperText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  State<ValidatedFormField> createState() => _ValidatedFormFieldState();
}

class _ValidatedFormFieldState extends State<ValidatedFormField> {
  String? _errorText;
  bool _hasBeenTouched = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasBeenTouched) {
      setState(() {
        _errorText = widget.validator(widget.controller.text);
      });
    }
  }

  void _onFieldTouched() {
    if (!_hasBeenTouched) {
      setState(() {
        _hasBeenTouched = true;
        _errorText = widget.validator(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final fontSize = isMobile ? 16.0 : 14.0; // 16px prevents zoom on iOS
        final contentPadding = EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 16,
          vertical: isMobile ? 18 : 16, // Larger touch target on mobile
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null) ...[
              Text(
                widget.labelText!,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              autofocus: widget.autofocus,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              style: TextStyle(fontSize: fontSize),
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                errorText: _hasBeenTouched ? _errorText : null,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                hintStyle: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.textSecondary,
                ),
                helperStyle: TextStyle(
                  fontSize: isMobile ? 12.0 : 11.0,
                ),
                errorStyle: TextStyle(
                  fontSize: isMobile ? 12.0 : 11.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                ),
                filled: true,
                fillColor: widget.enabled
                    ? AppColors.surface
                    : AppColors.surface.withOpacity(0.5),
                contentPadding: contentPadding,
              ),
              onChanged: (value) {
                _onFieldTouched();
                widget.onChanged?.call(value);
              },
              onFieldSubmitted: widget.onSubmitted,
              onTap: _onFieldTouched,
            ),
          ],
        );
      },
    );
  }
}

/// A specialized form field for price input
class PriceFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? labelText;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const PriceFormField({
    super.key,
    required this.controller,
    required this.validator,
    this.labelText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return ValidatedFormField(
          controller: controller,
          validator: validator,
          hintText: 'Ej: 15.50',
          labelText: labelText,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          prefixIcon: Icon(
            Icons.euro,
            color: AppColors.primary,
            size: isMobile ? 20 : 18,
          ),
        );
      },
    );
  }
}

/// A specialized form field for participant names
class ParticipantNameFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? labelText;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const ParticipantNameFormField({
    super.key,
    required this.controller,
    required this.validator,
    this.labelText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedFormField(
      controller: controller,
      validator: validator,
      hintText: 'Enter participant name',
      helperText: 'Name of the person joining the bill',
      labelText: labelText,
      keyboardType: TextInputType.name,
      autofocus: autofocus,
      prefixIcon: Icon(
        Icons.person_outline,
        color: AppColors.textSecondary,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
