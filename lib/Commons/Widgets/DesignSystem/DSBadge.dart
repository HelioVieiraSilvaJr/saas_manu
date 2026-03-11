import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSSpacing.dart';

/// Tipos de badge disponíveis.
enum DSBadgeType {
  success, // Verde (Ativo, Confirmado)
  warning, // Amarelo/Laranja (Pendente, Trial)
  error, // Vermelho (Cancelado, Inativo)
  info, // Azul (Manual, Info)
  primary, // Cor primária (WhatsApp Bot, Premium)
  neutral, // Cinza (Rascunho, Indefinido)
}

/// Tamanhos de badge.
enum DSBadgeSize { small, medium, large }

/// Design System v2.0 — Badge / Tag para status, labels USE3D.
class DSBadge extends StatelessWidget {
  final String label;
  final DSBadgeType type;
  final IconData? icon;
  final DSBadgeSize size;

  const DSBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.size = DSBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    final Color bgColor;
    final Color fgColor;

    switch (type) {
      case DSBadgeType.success:
        bgColor = colors.greenLight;
        fgColor = colors.green;
        break;
      case DSBadgeType.warning:
        bgColor = colors.yellowLight;
        fgColor = colors.orange;
        break;
      case DSBadgeType.error:
        bgColor = colors.redLight;
        fgColor = colors.red;
        break;
      case DSBadgeType.info:
        bgColor = colors.blueLight;
        fgColor = colors.blue;
        break;
      case DSBadgeType.primary:
        bgColor = colors.primarySurface;
        fgColor = colors.primaryColor;
        break;
      case DSBadgeType.neutral:
        bgColor = colors.greyLightest;
        fgColor = colors.grey;
        break;
    }

    final double fontSize;
    final double paddingH;
    final double paddingV;
    final double iconSize;

    switch (size) {
      case DSBadgeSize.small:
        fontSize = 10;
        paddingH = DSSpacing.sm;
        paddingV = DSSpacing.xs;
        iconSize = 10;
        break;
      case DSBadgeSize.medium:
        fontSize = 12;
        paddingH = DSSpacing.md;
        paddingV = DSSpacing.xs;
        iconSize = 12;
        break;
      case DSBadgeSize.large:
        fontSize = 14;
        paddingH = DSSpacing.base;
        paddingV = DSSpacing.sm;
        iconSize = 14;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DSSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fgColor),
            SizedBox(width: DSSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
