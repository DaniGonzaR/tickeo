import 'package:flutter/material.dart';
import 'package:tickeo/utils/app_colors.dart';
import 'package:tickeo/utils/validators.dart';

/// A password field with real-time strength assessment and suggestions
class PasswordStrengthField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final bool autofocus;
  final void Function(String)? onChanged;

  const PasswordStrengthField({
    super.key,
    required this.controller,
    required this.validator,
    required this.hintText,
    required this.labelText,
    this.obscureText = true,
    this.onToggleVisibility,
    this.autofocus = false,
    this.onChanged,
  });

  @override
  State<PasswordStrengthField> createState() => _PasswordStrengthFieldState();
}

class _PasswordStrengthFieldState extends State<PasswordStrengthField> {
  String? _errorText;
  bool _hasBeenTouched = false;
  PasswordStrength? _strength;

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
    final password = widget.controller.text;
    
    setState(() {
      _strength = Validators.getPasswordStrength(password);
      
      if (_hasBeenTouched) {
        _errorText = widget.validator(password);
      }
    });
    
    widget.onChanged?.call(password);
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
        final isMobile = constraints.maxWidth < 600;
        final fontSize = isMobile ? 16.0 : 14.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              widget.labelText,
              style: TextStyle(
                fontSize: isMobile ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Password field
            TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              autofocus: widget.autofocus,
              style: TextStyle(fontSize: fontSize),
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: widget.hintText,
                errorText: _hasBeenTouched ? _errorText : null,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: widget.onToggleVisibility != null
                    ? IconButton(
                        icon: Icon(
                          widget.obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: widget.onToggleVisibility,
                      )
                    : null,
                hintStyle: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.textSecondary,
                ),
                errorStyle: TextStyle(
                  fontSize: isMobile ? 12.0 : 11.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 16,
                  vertical: isMobile ? 18 : 16,
                ),
              ),
              onChanged: (value) {
                _onFieldTouched();
              },
              onTap: _onFieldTouched,
            ),
            
            // Password strength indicator
            if (_strength != null && widget.controller.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildStrengthIndicator(isMobile),
              
              // Suggestions
              if (_strength!.suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSuggestions(isMobile),
              ],
            ],
            
            // Help text
            const SizedBox(height: 8),
            Text(
              'Usa al menos 12 caracteres. Las frases largas son más seguras.',
              style: TextStyle(
                fontSize: isMobile ? 12 : 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStrengthIndicator(bool isMobile) {
    final strength = _strength!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.border,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (strength.score / 8).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: strength.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strength.label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: strength.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestions(bool isMobile) {
    final suggestions = _strength!.suggestions.take(3).toList(); // Show max 3 suggestions
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: isMobile ? 16 : 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Sugerencias para mejorar:',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
