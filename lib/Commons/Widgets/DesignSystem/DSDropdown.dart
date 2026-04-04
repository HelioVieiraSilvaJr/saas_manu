import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Design System v2.0 — Dropdown padronizado USE3D.
class DSDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final String? Function(T?)? validator;

  const DSDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textStyles.textFieldLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: textStyles.textField,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.greyLight,
          ),
          hint: hintText != null
              ? Text(hintText!, style: textStyles.textFieldHint)
              : null,
          dropdownColor: colors.surfaceColor,
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputBackground,
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
          ),
        ),
      ],
    );
  }
}
