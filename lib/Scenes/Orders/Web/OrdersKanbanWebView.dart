import 'package:flutter/material.dart';
import '../../../Commons/Enums/OrderStatus.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/SaleModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../OrdersKanbanPresenter.dart';
import '../OrdersKanbanViewModel.dart';

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
                      'Gerencie o fluxo de processamento dos pedidos pagos arrastando os cards entre as colunas',
                      style: textStyles.bodyMedium.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              DSButton.secondary(
                label: 'Colunas',
                icon: Icons.view_column_rounded,
                onTap: () => _showBoardSettings(context, vm),
              ),
              const SizedBox(width: DSSpacing.base),
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
    OrdersKanbanViewModel vm,
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
    OrdersKanbanViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: vm.visibleStatuses.map<Widget>((status) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xs),
              child: _KanbanColumn(
                status: status,
                orders: vm.ordersByStatus(status),
                movingOrderId: vm.movingOrderId,
                colors: colors,
                textStyles: textStyles,
                onMoveToStatus: presenter.moveToStatus,
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

  Future<void> _showBoardSettings(
    BuildContext context,
    OrdersKanbanViewModel vm,
  ) async {
    final initial = vm.visibleStatuses.toSet();
    final draft = <OrderStatus>{...initial};

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Colunas visiveis'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: OrderStatus.configurableStatuses.map((status) {
                    final locked =
                        status == OrderStatus.awaiting_processing ||
                        status == OrderStatus.completed;
                    return CheckboxListTile(
                      value: draft.contains(status),
                      title: Text(status.label),
                      subtitle: locked
                          ? Text(
                              status == OrderStatus.awaiting_processing
                                  ? 'Sempre visivel para receber pedidos.'
                                  : 'Sempre visivel para acompanhar pedidos finalizados.',
                            )
                          : null,
                      onChanged: locked
                          ? null
                          : (value) {
                              setModalState(() {
                                if (value == true) {
                                  draft.add(status);
                                } else {
                                  draft.remove(status);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await presenter.saveVisibleStatuses(
                      draft.toList(),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(success);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Board de pedidos atualizado com sucesso.'),
        ),
      );
    }
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
  final Future<bool> Function(String saleId, OrderStatus status) onMoveToStatus;
  final void Function(String) onViewDetails;
  final VoidCallback? onViewHistory;

  const _KanbanColumn({
    required this.status,
    required this.orders,
    required this.movingOrderId,
    required this.colors,
    required this.textStyles,
    required this.onMoveToStatus,
    required this.onViewDetails,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DraggedOrderData>(
      onWillAcceptWithDetails: (details) =>
          details.data.originStatus != status && movingOrderId == null,
      onAcceptWithDetails: (details) {
        onMoveToStatus(details.data.order.uid, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isActiveDropTarget = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActiveDropTarget
                ? colors.primarySurface.withValues(alpha: 0.55)
                : colors.scaffoldBackground,
            borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
            border: Border.all(
              color: isActiveDropTarget ? colors.primaryColor : colors.divider,
              width: isActiveDropTarget ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumnHeader(),
              Divider(height: 1, color: colors.divider),
              Expanded(
                child: orders.isEmpty
                    ? _buildEmptyColumn(isActiveDropTarget: isActiveDropTarget)
                    : ListView.builder(
                        padding: const EdgeInsets.all(DSSpacing.sm),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: DSSpacing.sm),
                            child: _OrderCard(
                              order: order,
                              status: status,
                              isMoving: movingOrderId == order.uid,
                              colors: colors,
                              textStyles: textStyles,
                              onTap: () => onViewDetails(order.uid),
                            ),
                          );
                        },
                      ),
              ),
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
      },
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
      case OrderStatus.packing:
        headerColor = colors.orange;
        break;
      case OrderStatus.awaiting_pickup:
        headerColor = colors.secundaryColor;
        break;
      case OrderStatus.ready_for_shipping:
        headerColor = colors.blue;
        break;
      case OrderStatus.shipped:
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

  Widget _buildEmptyColumn({bool isActiveDropTarget = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActiveDropTarget
                  ? Icons.move_down_rounded
                  : Icons.inbox_rounded,
              size: 32,
              color: isActiveDropTarget
                  ? colors.primaryColor
                  : colors.greyLighter,
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              isActiveDropTarget ? 'Solte aqui' : 'Nenhum pedido',
              style: textStyles.bodySmall.copyWith(
                color: isActiveDropTarget
                    ? colors.primaryColor
                    : colors.textTertiary,
              ),
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
  final OrderStatus status;
  final bool isMoving;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onTap;

  const _OrderCard({
    required this.order,
    required this.status,
    required this.isMoving,
    required this.colors,
    required this.textStyles,
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
    final dragData = _DraggedOrderData(order: order, originStatus: widget.status);
    final cardContent = AnimatedContainer(
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
                      const SizedBox(height: DSSpacing.sm),
                      Text(
                        'Arraste para mover',
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      if (order.isAutomated) ...[
                        const SizedBox(height: DSSpacing.sm),
                        DSBadge(
                          label: 'WhatsApp Bot',
                          type: DSBadgeType.info,
                          size: DSBadgeSize.small,
                          icon: Icons.smart_toy_rounded,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Draggable<_DraggedOrderData>(
        data: dragData,
        maxSimultaneousDrags: widget.isMoving ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 280, child: cardContent),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
        child: cardContent,
      ),
    );
  }
}

class _DraggedOrderData {
  final SaleModel order;
  final OrderStatus originStatus;

  const _DraggedOrderData({
    required this.order,
    required this.originStatus,
  });
}
