import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Design System v2.0 — Campo de busca padronizado USE3D.
class DSSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const DSSearchField({
    super.key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: textStyles.textField,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: textStyles.textFieldHint,
        prefixIcon: Icon(
          Icons.search,
          color: colors.greyLight,
          size: DSSpacing.iconMd,
        ),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color: colors.greyLight,
                  size: DSSpacing.iconMd,
                ),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: colors.surfaceOverlay,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.md,
          vertical: DSSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          borderSide: BorderSide(
            color: colors.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
