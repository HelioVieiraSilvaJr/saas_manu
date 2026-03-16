import 'package:flutter/material.dart';
import '../../../Commons/Enums/OrderStatus.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/SaleModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../OrdersKanbanPresenter.dart';

/// View Web do Kanban de pedidos.
///
/// Board horizontal com colunas para cada etapa da esteira.
class OrdersKanbanWebView extends StatelessWidget {
  final OrdersKanbanPresenter presenter;
  final void Function(String saleId) onViewDetails;

  const OrdersKanbanWebView({
    super.key,
    required this.presenter,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final vm = presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DSSpacing.pagePaddingHorizontalWeb,
            DSSpacing.pagePaddingVerticalWeb,
            DSSpacing.pagePaddingHorizontalWeb,
            DSSpacing.base,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Esteira de Pedidos', style: textStyles.headline1),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      'Gerencie o fluxo de processamento dos pedidos pagos',
                      style: textStyles.bodyMedium.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Resumo rápido
              _buildSummaryChips(vm, colors, textStyles),
            ],
          ),
        ),

        // Kanban Board
        Expanded(
          child: vm.isLoading
              ? const LoadingIndicator(message: 'Carregando pedidos...')
              : vm.allOrders.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.assignment_turned_in_rounded,
                    title: 'Nenhum pedido na esteira',
                    message:
                        'Quando uma venda tiver o pagamento confirmado, o pedido aparecerá aqui automaticamente.',
                  ),
                )
              : _buildKanbanBoard(context, vm, colors, textStyles),
        ),
      ],
    );
  }

  // ──────────────────── Summary Chips ────────────────────

  Widget _buildSummaryChips(
    dynamic vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        _buildChip(
          '${vm.activeOrdersCount} ativos',
          colors.blue,
          colors.blueLight,
          textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),
        _buildChip(
          '${vm.completedCount} concluídos (7 dias)',
          colors.green,
          colors.greenLight,
          textStyles,
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    Color color,
    Color bgColor,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DSSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: textStyles.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ──────────────────── Kanban Board ────────────────────

  Widget _buildKanbanBoard(
    BuildContext context,
    dynamic vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: OrderStatus.values.map((status) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xs),
              child: _KanbanColumn(
                status: status,
                orders: vm.ordersByStatus(status),
                movingOrderId: vm.movingOrderId,
                colors: colors,
                textStyles: textStyles,
                onMoveNext: (id) => presenter.moveToNext(id),
                onMovePrevious: (id) => presenter.moveToPrevious(id),
                onViewDetails: onViewDetails,
                onViewHistory: status == OrderStatus.completed
                    ? () => Navigator.of(context).pushReplacementNamed('/sales')
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// KANBAN COLUMN
// ══════════════════════════════════════════════

class _KanbanColumn extends StatelessWidget {
  final OrderStatus status;
  final List<SaleModel> orders;
  final String? movingOrderId;
  final DSColors colors;
  final DSTextStyle textStyles;
  final Future<bool> Function(String) onMoveNext;
  final Future<bool> Function(String) onMovePrevious;
  final void Function(String) onViewDetails;
  final VoidCallback? onViewHistory;

  const _KanbanColumn({
    required this.status,
    required this.orders,
    required this.movingOrderId,
    required this.colors,
    required this.textStyles,
    required this.onMoveNext,
    required this.onMovePrevious,
    required this.onViewDetails,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          _buildColumnHeader(),
          Divider(height: 1, color: colors.divider),

          // Cards
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyColumn()
                : ListView.builder(
                    padding: const EdgeInsets.all(DSSpacing.sm),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: DSSpacing.sm),
                        child: _OrderCard(
                          order: order,
                          isMoving: movingOrderId == order.uid,
                          colors: colors,
                          textStyles: textStyles,
                          onMoveNext: status.next != null
                              ? () => onMoveNext(order.uid)
                              : null,
                          onMovePrevious: status.previous != null
                              ? () => onMovePrevious(order.uid)
                              : null,
                          onTap: () => onViewDetails(order.uid),
                        ),
                      );
                    },
                  ),
          ),

          // Link para histórico completo (apenas na coluna Concluídos)
          if (onViewHistory != null) ...[
            Divider(height: 1, color: colors.divider),
            InkWell(
              onTap: onViewHistory,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: DSSpacing.md,
                  horizontal: DSSpacing.base,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: colors.primaryColor,
                    ),
                    const SizedBox(width: DSSpacing.xs),
                    Text(
                      'Ver histórico completo',
                      style: textStyles.labelMedium.copyWith(
                        color: colors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnHeader() {
    final Color headerColor;
    switch (status) {
      case OrderStatus.awaiting_processing:
        headerColor = colors.orange;
        break;
      case OrderStatus.preparing:
        headerColor = colors.blue;
        break;
      case OrderStatus.ready_for_pickup:
        headerColor = colors.secundaryColor;
        break;
      case OrderStatus.completed:
        headerColor = colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DSSpacing.radiusLg),
          topRight: Radius.circular(DSSpacing.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Text(status.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.shortLabel,
                  style: textStyles.labelLarge.copyWith(color: headerColor),
                ),
                if (status == OrderStatus.completed)
                  Text(
                    'últimos 7 dias',
                    style: textStyles.bodySmall.copyWith(
                      color: headerColor.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.sm,
              vertical: DSSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DSSpacing.radiusFull),
            ),
            child: Text(
              '${orders.length}',
              style: textStyles.labelMedium.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 32, color: colors.greyLighter),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Nenhum pedido',
              style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ORDER CARD
// ══════════════════════════════════════════════

class _OrderCard extends StatefulWidget {
  final SaleModel order;
  final bool isMoving;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onMoveNext;
  final VoidCallback? onMovePrevious;
  final VoidCallback? onTap;

  const _OrderCard({
    required this.order,
    required this.isMoving,
    required this.colors,
    required this.textStyles,
    this.onMoveNext,
    this.onMovePrevious,
    this.onTap,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final textStyles = widget.textStyles;
    final order = widget.order;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          border: Border.all(
            color: _isHovered ? colors.primaryLight : colors.divider,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: colors.shadowMedium,
                blurRadius: DSSpacing.elevationMdBlur,
                offset: const Offset(0, DSSpacing.elevationMdOffset),
              )
            else
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: DSSpacing.elevationSmBlur,
                offset: const Offset(0, DSSpacing.elevationSmOffset),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(DSSpacing.md),
              child: widget.isMoving
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: número + valor
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${order.number}',
                              style: textStyles.labelLarge.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              order.total.formatToBRL(),
                              style: textStyles.labelLarge.copyWith(
                                color: colors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DSSpacing.sm),

                        // Cliente
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: DSSpacing.xxs),
                            Expanded(
                              child: Text(
                                order.customerName,
                                style: textStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DSSpacing.xxs),

                        // Itens
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              size: 14,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: DSSpacing.xxs),
                            Text(
                              '${order.itemsCount} ${order.itemsCount == 1 ? 'item' : 'itens'}',
                              style: textStyles.bodySmall.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),

                        // Origem badge
                        if (order.isAutomated) ...[
                          const SizedBox(height: DSSpacing.sm),
                          DSBadge(
                            label: 'WhatsApp Bot',
                            type: DSBadgeType.info,
                            size: DSBadgeSize.small,
                            icon: Icons.smart_toy_rounded,
                          ),
                        ],

                        // Botões de movimentação
                        if (widget.onMoveNext != null ||
                            widget.onMovePrevious != null) ...[
                          const SizedBox(height: DSSpacing.md),
                          Divider(height: 1, color: colors.divider),
                          const SizedBox(height: DSSpacing.sm),
                          Row(
                            children: [
                              if (widget.onMovePrevious != null)
                                Expanded(
                                  child: _MoveButton(
                                    label: '← Voltar',
                                    color: colors.textTertiary,
                                    bgColor: colors.scaffoldBackground,
                                    onTap: widget.onMovePrevious!,
                                  ),
                                ),
                              if (widget.onMovePrevious != null &&
                                  widget.onMoveNext != null)
                                const SizedBox(width: DSSpacing.xs),
                              if (widget.onMoveNext != null)
                                Expanded(
                                  child: _MoveButton(
                                    label: _nextButtonLabel(order.orderStatus),
                                    color: _nextButtonColor(
                                      order.orderStatus,
                                      colors,
                                    ),
                                    bgColor: _nextButtonBgColor(
                                      order.orderStatus,
                                      colors,
                                    ),
                                    onTap: widget.onMoveNext!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _nextButtonLabel(OrderStatus? status) {
    switch (status) {
      case OrderStatus.awaiting_processing:
        return 'Preparar →';
      case OrderStatus.preparing:
        return 'Pronto →';
      case OrderStatus.ready_for_pickup:
        return 'Concluir ✓';
      default:
        return 'Avançar →';
    }
  }

  Color _nextButtonColor(OrderStatus? status, DSColors colors) {
    switch (status) {
      case OrderStatus.ready_for_pickup:
        return colors.green;
      default:
        return colors.primaryColor;
    }
  }

  Color _nextButtonBgColor(OrderStatus? status, DSColors colors) {
    switch (status) {
      case OrderStatus.ready_for_pickup:
        return colors.greenLight;
      default:
        return colors.primarySurface;
    }
  }
}

// ══════════════════════════════════════════════
// MOVE BUTTON
// ══════════════════════════════════════════════

class _MoveButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _MoveButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_MoveButton> createState() => _MoveButtonState();
}

class _MoveButtonState extends State<_MoveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.sm,
            vertical: DSSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : widget.bgColor,
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            border: Border.all(
              color: _hovered
                  ? widget.color
                  : widget.color.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
