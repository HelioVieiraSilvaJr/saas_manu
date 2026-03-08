import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Commons/Enums/SaleSource.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Extensions/String+Extensions.dart';
import '../../Commons/Models/SaleModel.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../Products/ProductsRepository.dart';
import '../Customers/CustomersRepository.dart';
import 'SalesRepository.dart';

/// Página de detalhes de uma venda.
class SaleDetailPage extends StatefulWidget {
  const SaleDetailPage({super.key});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  final _salesRepository = SalesRepository();
  final _productsRepository = ProductsRepository();
  final _customersRepository = CustomersRepository();
  SaleModel? _sale;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sale == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is SaleModel) {
        _sale = args;
        _isLoading = false;
      } else if (args is String) {
        _loadSale(args);
      }
    }
  }

  Future<void> _loadSale(String saleId) async {
    final sale = await _salesRepository.getById(saleId);
    if (mounted) {
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(SaleStatus newStatus) async {
    if (_sale == null) return;

    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Alterar Status',
      message: 'Confirma alteração para "${newStatus.label}"?',
    );

    if (confirm != true || !mounted) return;

    final success = await _salesRepository.updateStatus(_sale!.uid, newStatus);

    if (success) {
      // Se cancelar: devolver estoque
      if (newStatus == SaleStatus.cancelled &&
          _sale!.status != SaleStatus.cancelled) {
        for (var item in _sale!.items) {
          await _productsRepository.incrementStock(
            item.productId,
            item.quantity,
          );
        }
      }

      setState(() {
        _sale = _sale!.copyWith(status: newStatus, updatedAt: DateTime.now());
      });

      if (mounted) {
        await DSAlertDialog.showSuccess(
          context: context,
          title: 'Status Alterado',
          message: 'Venda atualizada para "${newStatus.label}".',
        );
      }
    }
  }

  Future<void> _deleteSale() async {
    if (_sale == null) return;

    final confirm = await DSAlertDialog.showDelete(
      context: context,
      title: 'Confirmar Exclusão',
      message: 'Tem certeza que deseja excluir esta venda?',
    );

    if (confirm != true || !mounted) return;

    // 1. Devolver estoque
    for (var item in _sale!.items) {
      await _productsRepository.incrementStock(item.productId, item.quantity);
    }

    // 2. Atualizar stats do cliente
    await _customersRepository.decrementPurchaseStats(
      _sale!.customerId,
      _sale!.total,
    );

    // 3. Deletar venda
    await _salesRepository.delete(_sale!.uid);

    if (mounted) {
      await DSAlertDialog.showSuccess(
        context: context,
        title: 'Venda Excluída',
        message: 'Venda excluída e estoque atualizado.',
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _openWhatsApp() {
    if (_sale == null) return;
    final url = 'https://wa.me/55${_sale!.customerWhatsapp}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/sales',
      child: ScreenResponsive(
        web: _buildContent(isWeb: true),
        mobile: _buildContent(isWeb: false),
      ),
    );
  }

  Widget _buildContent({required bool isWeb}) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sale == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: DSSpacing.base),
            const Text('Venda não encontrada'),
            const SizedBox(height: DSSpacing.base),
            DSButton.secondary(
              label: 'Voltar',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    final sale = _sale!;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 700 : double.infinity),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? DSSpacing.xl : DSSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Delete
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete, color: colors.red),
                      tooltip: 'Deletar venda',
                      onPressed: _deleteSale,
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.base),

                // Header
                Text('Venda #${sale.number}', style: textStyles.headline2),
                const SizedBox(height: DSSpacing.xs),
                Text(
                  sale.createdAt.formatDateTime(),
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: DSSpacing.sm),

                // Badges
                Wrap(
                  spacing: DSSpacing.sm,
                  children: [
                    DSBadge(
                      label: sale.source.label,
                      type: sale.source == SaleSource.manual
                          ? DSBadgeType.info
                          : DSBadgeType.primary,
                    ),
                    DSBadge(
                      label: sale.status.label,
                      type: _statusBadgeType(sale.status),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.xl),

                // Status change
                _buildStatusSection(sale, colors, textStyles),
                const SizedBox(height: DSSpacing.xl),

                // Cliente
                _buildClientSection(sale, colors, textStyles),
                const SizedBox(height: DSSpacing.xl),

                // Produtos
                _buildProductsSection(sale, colors, textStyles),
                const SizedBox(height: DSSpacing.xl),

                // Resumo
                _buildSummarySection(sale, colors, textStyles),

                // Observações
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: DSSpacing.xl),
                  _buildNotesSection(sale, colors, textStyles),
                ],

                const SizedBox(height: DSSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    SaleModel sale,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Text('Alterar Status:', style: textStyles.labelMedium),
          const SizedBox(width: DSSpacing.base),
          Expanded(
            child: DropdownButtonFormField<SaleStatus>(
              value: sale.status,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.sm,
                  vertical: DSSpacing.sm,
                ),
              ),
              items: SaleStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (newStatus) {
                if (newStatus != null && newStatus != sale.status) {
                  _changeStatus(newStatus);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(
    SaleModel sale,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cliente', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.sm),
          Row(
            children: [
              DSAvatar(name: sale.customerName, size: 48),
              const SizedBox(width: DSSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.customerName, style: textStyles.labelLarge),
                    Text(
                      sale.customerWhatsapp.formatWhatsApp(),
                      style: textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                tooltip: 'WhatsApp',
                onPressed: _openWhatsApp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(
    SaleModel sale,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produtos (${sale.itemsCount} ${sale.itemsCount == 1 ? 'item' : 'itens'})',
            style: textStyles.headline3,
          ),
          const SizedBox(height: DSSpacing.sm),
          ...sale.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• ${item.productName}',
                      style: textStyles.bodyMedium,
                    ),
                  ),
                  Text('x${item.quantity}', style: textStyles.bodyMedium),
                  const SizedBox(width: DSSpacing.base),
                  Text(
                    item.subtotal.formatToBRL(),
                    style: textStyles.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    SaleModel sale,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: textStyles.bodyMedium),
              Text(sale.total.formatToBRL(), style: textStyles.bodyMedium),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: textStyles.headline3),
              Text(
                sale.total.formatToBRL(),
                style: textStyles.headline3.copyWith(
                  color: colors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(
    SaleModel sale,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Observações', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.sm),
          Text(sale.notes!, style: textStyles.bodyMedium),
        ],
      ),
    );
  }

  DSBadgeType _statusBadgeType(SaleStatus status) {
    switch (status) {
      case SaleStatus.confirmed:
        return DSBadgeType.success;
      case SaleStatus.pending:
        return DSBadgeType.warning;
      case SaleStatus.cancelled:
        return DSBadgeType.error;
    }
  }
}
