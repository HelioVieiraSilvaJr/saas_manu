import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Design System - Botões padronizados.
///
/// NUNCA usar ElevatedButton/TextButton diretamente. Usar DSButton().
class DSButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final _DSButtonType _type;
  final bool isLoading;
  final bool isExpanded;
  final double? width;

  const DSButton._({
    required this.label,
    required _DSButtonType type,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
  }) : _type = type;

  /// Botão primário (preenchido com cor primária)
  factory DSButton.primary({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isExpanded = false,
    double? width,
  }) {
    return DSButton._(
      label: label,
      icon: icon,
      onTap: onTap,
      type: _DSButtonType.primary,
      isLoading: isLoading,
      isExpanded: isExpanded,
      width: width,
    );
  }

  /// Botão secundário (borda com cor primária)
  factory DSButton.secondary({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isExpanded = false,
    double? width,
  }) {
    return DSButton._(
      label: label,
      icon: icon,
      onTap: onTap,
      type: _DSButtonType.secondary,
      isLoading: isLoading,
      isExpanded: isExpanded,
      width: width,
    );
  }

  /// Botão de texto (sem fundo/borda)
  factory DSButton.text({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isExpanded = false,
  }) {
    return DSButton._(
      label: label,
      icon: icon,
      onTap: onTap,
      type: _DSButtonType.text,
      isLoading: isLoading,
      isExpanded: isExpanded,
    );
  }

  /// Botão de perigo (vermelho)
  factory DSButton.danger({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isExpanded = false,
  }) {
    return DSButton._(
      label: label,
      icon: icon,
      onTap: onTap,
      type: _DSButtonType.danger,
      isLoading: isLoading,
      isExpanded: isExpanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyle = DSTextStyle();

    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    switch (_type) {
      case _DSButtonType.primary:
        bgColor = colors.primaryColor;
        fgColor = colors.white;
        borderColor = colors.primaryColor;
        break;
      case _DSButtonType.secondary:
        bgColor = Colors.transparent;
        fgColor = colors.primaryColor;
        borderColor = colors.primaryColor;
        break;
      case _DSButtonType.text:
        bgColor = Colors.transparent;
        fgColor = colors.primaryColor;
        borderColor = Colors.transparent;
        break;
      case _DSButtonType.danger:
        bgColor = colors.red;
        fgColor = colors.white;
        borderColor = colors.red;
        break;
    }

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: DSSpacing.iconMd,
        height: DSSpacing.iconMd,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      final textWidget = Text(
        label,
        style: textStyle.button.copyWith(color: fgColor),
      );

      if (icon != null) {
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: DSSpacing.iconMd, color: fgColor),
            const SizedBox(width: DSSpacing.sm),
            textWidget,
          ],
        );
      } else {
        child = textWidget;
      }
    }

    final button = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        child: Container(
          width: width ?? (isExpanded ? double.infinity : null),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.base,
            vertical: DSSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
          ),
          child: Center(child: child),
        ),
      ),
    );

    return button;
  }
}

enum _DSButtonType { primary, secondary, text, danger }
