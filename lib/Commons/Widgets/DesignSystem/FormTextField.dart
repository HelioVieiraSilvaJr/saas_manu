import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Design System v2.0 — Campo de texto de formulário USE3D.
class FormTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final String? hintText;
  final String? helperText;
  final Widget? helperWidget;
  final Widget? labelTrailing;
  final IconData? prefixIcon;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const FormTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.hintText,
    this.helperText,
    this.helperWidget,
    this.labelTrailing,
    this.prefixIcon,
    this.suffix,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            Expanded(child: Text(label, style: textStyles.textFieldLabel)),
            if (labelTrailing != null) ...[
              const SizedBox(width: DSSpacing.xs),
              labelTrailing!,
            ],
          ],
        ),
        const SizedBox(height: 6),

        // TextField
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          style: textStyles.textField,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: textStyles.textFieldHint,
            helperText: helperText,
            helperStyle: textStyles.caption,
            errorStyle: textStyles.textFieldError,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: colors.greyLight,
                    size: DSSpacing.iconMd,
                  )
                : null,
            suffix: suffix,
            filled: true,
            fillColor: readOnly
                ? colors.surfaceOverlay
                : colors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.md,
              vertical: DSSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              borderSide: BorderSide(color: colors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              borderSide: BorderSide(color: colors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              borderSide: BorderSide(
                color: colors.inputBorderFocused,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              borderSide: BorderSide(color: colors.inputError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              borderSide: BorderSide(color: colors.inputError, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              borderSide: BorderSide(color: colors.greyLightest),
            ),
          ),
        ),

        // Helper widget (custom content abaixo do campo)
        if (helperWidget != null) ...[
          const SizedBox(height: DSSpacing.xs),
          helperWidget!,
        ],
      ],
    );
  }
}
