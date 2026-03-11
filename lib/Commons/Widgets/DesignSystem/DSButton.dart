import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Design System v2.0 — Botões padronizados USE3D.
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

  /// Botão accent (teal/secundário preenchido)
  factory DSButton.accent({
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
      type: _DSButtonType.accent,
      isLoading: isLoading,
      isExpanded: isExpanded,
      width: width,
    );
  }

  /// Botão ghost (sem fundo, sem borda, hover sutil)
  factory DSButton.ghost({
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
      type: _DSButtonType.ghost,
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
      case _DSButtonType.accent:
        bgColor = colors.secundaryColor;
        fgColor = colors.white;
        borderColor = colors.secundaryColor;
        break;
      case _DSButtonType.ghost:
        bgColor = Colors.transparent;
        fgColor = colors.textSecondary;
        borderColor = Colors.transparent;
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

    const radius = DSSpacing.radiusMd; // 12 → borderRadius modernizado

    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(radius),
        hoverColor: _type == _DSButtonType.ghost ? colors.primarySurface : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width ?? (isExpanded ? double.infinity : null),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: _type == _DSButtonType.ghost ? 0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(child: child),
        ),
      ),
    );

    return button;
  }
}

enum _DSButtonType { primary, secondary, text, danger, accent, ghost }
