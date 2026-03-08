import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';

/// Widget de ações rápidas do Dashboard.
///
/// 3 botões: Nova Venda, Novo Produto, Novo Cliente.
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onNewSale;
  final VoidCallback? onNewProduct;
  final VoidCallback? onNewCustomer;
  final bool isWeb;

  const QuickActionsWidget({
    super.key,
    this.onNewSale,
    this.onNewProduct,
    this.onNewCustomer,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ações Rápidas', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.base),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'Nova Venda',
                  color: colors.primaryColor,
                  onTap: onNewSale,
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: _ActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Novo Produto',
                  color: colors.secundaryColor,
                  onTap: onNewProduct,
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: _ActionButton(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Novo Cliente',
                  color: colors.green,
                  onTap: onNewCustomer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão individual de ação rápida.
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textStyles = DSTextStyle();
    final colors = DSColors();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: DSSpacing.base,
            horizontal: DSSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.08)
                : colors.scaffoldBackground,
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.3)
                  : colors.divider,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: DSSpacing.iconLg,
                ),
              ),
              const SizedBox(height: DSSpacing.sm),
              Text(
                widget.label,
                style: textStyles.labelMedium.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
