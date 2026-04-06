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

/// View Mobile do Kanban de pedidos.
///
/// TabBar horizontal com abas para cada etapa da esteira.
class OrdersKanbanMobileView extends StatefulWidget {
  final OrdersKanbanPresenter presenter;
  final void Function(String saleId) onViewDetails;
  final Future<void> Function() onRefresh;

  const OrdersKanbanMobileView({
    super.key,
    required this.presenter,
    required this.onViewDetails,
    required this.onRefresh,
  });

  @override
  State<OrdersKanbanMobileView> createState() => _OrdersKanbanMobileViewState();
}

class _OrdersKanbanMobileViewState extends State<OrdersKanbanMobileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<OrderStatus> get _visibleStatuses =>
      widget.presenter.viewModel.visibleStatuses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _visibleStatuses.length,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant OrdersKanbanMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tabController.length != _visibleStatuses.length) {
      final previousIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: _visibleStatuses.length,
        vsync: this,
      );
      _tabController.index = previousIndex.clamp(
        0,
        _visibleStatuses.length - 1,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando pedidos...');
    }

    if (vm.allOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            EmptyState(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Nenhum pedido',
              message: 'Pedidos aparecerão aqui após confirmação de pagamento.',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DSSpacing.base,
            DSSpacing.base,
            DSSpacing.base,
            0,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _showBoardSettings,
              icon: const Icon(Icons.view_column_rounded, size: 18),
              label: const Text('Colunas'),
            ),
          ),
        ),
        // Tabs
        Container(
          color: colors.surfaceColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: colors.primaryColor,
            unselectedLabelColor: colors.textTertiary,
            indicatorColor: colors.primaryColor,
            labelStyle: textStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: _visibleStatuses.map((status) {
              final count = vm.countByStatus(status);
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.emoji),
                    const SizedBox(width: DSSpacing.xxs),
                    Text('$count'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _visibleStatuses.map((status) {
              final orders = vm.ordersByStatus(status);
              if (orders.isEmpty) {
                return Center(
                  child: EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'Nenhum pedido',
                    message: status == OrderStatus.completed
                        ? 'Nenhum pedido concluído nos últimos 7 dias.'
                        : 'Nenhum pedido em "${status.shortLabel}".',
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(DSSpacing.base),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _MobileOrderCard(
                            order: order,
                            status: status,
                            isMoving: vm.movingOrderId == order.uid,
                            colors: colors,
                            textStyles: textStyles,
                            onMoveNext: status.next != null
                                ? () => widget.presenter.moveToNext(order.uid)
                                : null,
                            onMovePrevious: status.previous != null
                                ? () =>
                                      widget.presenter.moveToPrevious(order.uid)
                                : null,
                            onTap: () => widget.onViewDetails(order.uid),
                          );
                        },
                      ),
                    ),
                  ),
                  if (status == OrderStatus.completed)
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).pushReplacementNamed('/sales'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: DSSpacing.md,
                          horizontal: DSSpacing.base,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: colors.divider),
                          ),
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
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showBoardSettings() async {
    final draft = <OrderStatus>{...widget.presenter.viewModel.visibleStatuses};

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Colunas visiveis'),
              content: SingleChildScrollView(
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
                    final success = await widget.presenter.saveVisibleStatuses(
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

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Board de pedidos atualizado.')),
      );
    }
  }
}

// ══════════════════════════════════════════════
// MOBILE ORDER CARD
// ══════════════════════════════════════════════

class _MobileOrderCard extends StatelessWidget {
  final SaleModel order;
  final OrderStatus status;
  final bool isMoving;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onMoveNext;
  final VoidCallback? onMovePrevious;
  final VoidCallback? onTap;

  const _MobileOrderCard({
    required this.order,
    required this.status,
    required this.isMoving,
    required this.colors,
    required this.textStyles,
    this.onMoveNext,
    this.onMovePrevious,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: DSSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.base),
          child: isMoving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(DSSpacing.base),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
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
                    Text(
                      order.customerName,
                      style: textStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DSSpacing.xxs),

                    // Itens + origem
                    Row(
                      children: [
                        Text(
                          '${order.itemsCount} ${order.itemsCount == 1 ? 'item' : 'itens'}',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        if (order.isAutomated) ...[
                          const SizedBox(width: DSSpacing.sm),
                          DSBadge(
                            label: 'WhatsApp',
                            type: DSBadgeType.info,
                            size: DSBadgeSize.small,
                          ),
                        ],
                      ],
                    ),

                    // Botões
                    if (onMoveNext != null || onMovePrevious != null) ...[
                      const SizedBox(height: DSSpacing.md),
                      Row(
                        children: [
                          if (onMovePrevious != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onMovePrevious,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.textSecondary,
                                  side: BorderSide(color: colors.divider),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: const Text('← Voltar'),
                              ),
                            ),
                          if (onMovePrevious != null && onMoveNext != null)
                            const SizedBox(width: DSSpacing.sm),
                          if (onMoveNext != null)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onMoveNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == OrderStatus.shipped
                                      ? colors.green
                                      : colors.primaryColor,
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(
                                  _nextLabel(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  String _nextLabel() {
    switch (status) {
      case OrderStatus.awaiting_processing:
        return 'Preparar →';
      case OrderStatus.preparing:
        return 'Embalar →';
      case OrderStatus.packing:
        return 'Retirada →';
      case OrderStatus.awaiting_pickup:
        return 'Pronto →';
      case OrderStatus.ready_for_shipping:
        return 'Enviar →';
      case OrderStatus.shipped:
        return 'Concluir ✓';
      default:
        return 'Avançar →';
    }
  }
}
