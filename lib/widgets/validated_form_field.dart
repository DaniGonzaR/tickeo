import 'package:flutter/material.dart';
import 'package:tickeo/utils/app_colors.dart';

/// A custom form field widget with built-in validation
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: _errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: widget.enabled 
                ? AppColors.surface 
                : AppColors.surface.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: widget.enabled 
                ? AppColors.textPrimary 
                : AppColors.textSecondary,
          ),
          onChanged: (value) {
            _onFieldTouched();
            widget.onChanged?.call(value);
          },
          onSubmitted: widget.onSubmitted,
          onTap: _onFieldTouched,
        ),
      ],
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
    return ValidatedFormField(
      controller: controller,
      validator: validator,
      hintText: '0.00',
      helperText: 'Enter price in euros',
      labelText: labelText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: autofocus,
      prefixIcon: Icon(
        Icons.euro,
        color: AppColors.textSecondary,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
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
