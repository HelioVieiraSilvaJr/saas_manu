import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';
import 'DSButton.dart';

/// Design System - Modais de confirmação padronizados.
///
/// NUNCA usar AlertDialog nativo. Sempre usar DSAlertDialog.
class DSAlertDialog {
  DSAlertDialog._();

  // MARK: - Show Delete

  /// Modal de confirmação de exclusão (vermelho)
  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
    String confirmLabel = 'Excluir',
    String cancelLabel = 'Cancelar',
  }) {
    return _show(
      context: context,
      type: DSAlertType.delete,
      title: title,
      message: message,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
  }

  // MARK: - Show Warning

  /// Modal de aviso (amarelo/laranja)
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
  }) {
    return _show(
      context: context,
      type: DSAlertType.warning,
      title: title,
      message: message,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
  }

  // MARK: - Show Success

  /// Modal de sucesso (verde) - apenas botão OK
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
  }) {
    return _show(
      context: context,
      type: DSAlertType.success,
      title: title,
      message: message,
      content: content,
      confirmLabel: 'OK',
      showCancel: false,
    );
  }

  // MARK: - Show Info

  /// Modal informativo (azul) - apenas botão OK
  static Future<bool?> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
  }) {
    return _show(
      context: context,
      type: DSAlertType.info,
      title: title,
      message: message,
      content: content,
      confirmLabel: 'OK',
      showCancel: false,
    );
  }

  // MARK: - Show Confirm

  /// Modal de confirmação genérica (cor primária)
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
  }) {
    return _show(
      context: context,
      type: DSAlertType.confirm,
      title: title,
      message: message,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
  }

  // MARK: - Show Error

  /// Modal de erro (vermelho) - apenas botão OK
  static Future<bool?> showError({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
  }) {
    return _show(
      context: context,
      type: DSAlertType.delete,
      title: title,
      message: message,
      content: content,
      confirmLabel: 'OK',
      showCancel: false,
    );
  }

  // MARK: - Private Show

  static Future<bool?> _show({
    required BuildContext context,
    required DSAlertType type,
    required String title,
    required String message,
    Widget? content,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool showCancel = true,
  }) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    final Color iconColor;
    final IconData iconData;

    switch (type) {
      case DSAlertType.delete:
        iconColor = colors.red;
        iconData = Icons.delete_outline;
        break;
      case DSAlertType.warning:
        iconColor = colors.yellow;
        iconData = Icons.warning_amber_rounded;
        break;
      case DSAlertType.success:
        iconColor = colors.green;
        iconData = Icons.check_circle_outline;
        break;
      case DSAlertType.info:
        iconColor = colors.blue;
        iconData = Icons.info_outline;
        break;
      case DSAlertType.confirm:
        iconColor = colors.primaryColor;
        iconData = Icons.help_outline;
        break;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusXl),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon — square-rounded
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                  ),
                  child: Icon(iconData, color: iconColor, size: 28),
                ),
                const SizedBox(height: DSSpacing.base),

                // Title
                Text(
                  title,
                  style: textStyles.headline3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.sm),

                // Message
                Text(
                  message,
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Optional content
                if (content != null) ...[
                  const SizedBox(height: DSSpacing.base),
                  content,
                ],

                const SizedBox(height: DSSpacing.xl),

                // Actions
                Row(
                  children: [
                    if (showCancel) ...[
                      Expanded(
                        child: DSButton.ghost(
                          label: cancelLabel,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.md),
                    ],
                    Expanded(
                      child: type == DSAlertType.delete
                          ? DSButton.danger(
                              label: confirmLabel,
                              onTap: () => Navigator.pop(context, true),
                            )
                          : DSButton.primary(
                              label: confirmLabel,
                              onTap: () => Navigator.pop(context, true),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// MARK: - Alert Types

enum DSAlertType { delete, warning, success, info, confirm }

// MARK: - DSAlertContentCard

/// Card de preview usado dentro de DSAlertDialog.
class DSAlertContentCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const DSAlertContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final cardColor = color ?? colors.greyLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: cardColor, size: DSSpacing.iconLg),
            const SizedBox(width: DSSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textStyles.labelLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: DSSpacing.xxs),
                  Text(subtitle!, style: textStyles.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
