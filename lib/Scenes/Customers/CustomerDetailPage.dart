import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Extensions/String+Extensions.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'CustomersCoordinator.dart';
import 'CustomersListPresenter.dart';
import 'CustomersRepository.dart';

/// Página de detalhes do cliente.
///
/// Exibe contatos, observações, estatísticas de compras e histórico.
class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  CustomerModel? _customer;
  late final CustomersListPresenter _presenter;
  final CustomersRepository _repository = CustomersRepository();
  List<Map<String, dynamic>> _recentSales = [];
  bool _loadingSales = true;

  @override
  void initState() {
    super.initState();
    _presenter = CustomersListPresenter(onViewModelUpdated: (_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenter.context = context;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CustomerModel && _customer == null) {
      _customer = args;
      _loadRecentSales();
    }
  }

  Future<void> _loadRecentSales() async {
    if (_customer == null) return;
    final sales = await _repository.getRecentSales(_customer!.uid);
    if (mounted) {
      setState(() {
        _recentSales = sales;
        _loadingSales = false;
      });
    }
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_customer == null) {
      return const Scaffold(
        body: Center(child: Text('Cliente não encontrado.')),
      );
    }

    return AppShell(
      currentRoute: '/customers',
      child: ScreenResponsive(
        web: _buildWebLayout(),
        mobile: _buildMobileLayout(),
      ),
    );
  }

  // MARK: - Web Layout

  Widget _buildWebLayout() {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final customer = _customer!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
        vertical: DSSpacing.pagePaddingVerticalWeb,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => CustomersCoordinator.navigateBack(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: DSSpacing.sm),
              Expanded(
                child: Text('Detalhes do Cliente', style: textStyles.headline1),
              ),
              Tooltip(
                message: 'Editar',
                child: IconButton(
                  onPressed: () =>
                      CustomersCoordinator.navigateToEdit(context, customer),
                  icon: Icon(Icons.edit_outlined, color: colors.primaryColor),
                ),
              ),
              const SizedBox(width: DSSpacing.xs),
              Tooltip(
                message: 'Excluir',
                child: IconButton(
                  onPressed: () => _handleDelete(customer),
                  icon: Icon(Icons.delete_outline, color: colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildProfileCard(colors, textStyles, customer),
                  const SizedBox(height: DSSpacing.lg),
                  _buildStatsCards(colors),
                  const SizedBox(height: DSSpacing.lg),
                  _buildPurchaseHistory(colors, textStyles),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Mobile Layout

  Widget _buildMobileLayout() {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final customer = _customer!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes', style: textStyles.headline3),
        leading: IconButton(
          onPressed: () => CustomersCoordinator.navigateBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        backgroundColor: colors.cardBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () =>
                CustomersCoordinator.navigateToEdit(context, customer),
            icon: Icon(Icons.edit_outlined, color: colors.primaryColor),
          ),
          IconButton(
            onPressed: () => _handleDelete(customer),
            icon: Icon(Icons.delete_outline, color: colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.md),
        child: Column(
          children: [
            _buildProfileCard(colors, textStyles, customer),
            const SizedBox(height: DSSpacing.lg),
            _buildStatsCards(colors),
            const SizedBox(height: DSSpacing.lg),
            _buildPurchaseHistory(colors, textStyles),
          ],
        ),
      ),
    );
  }

  // MARK: - Components

  Widget _buildProfileCard(
    DSColors colors,
    DSTextStyle textStyles,
    CustomerModel customer,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          // Avatar grande
          DSAvatar(name: customer.name, size: 80, fontSize: 28),
          const SizedBox(height: DSSpacing.md),

          // Nome
          Text(customer.name, style: textStyles.headline2),
          const SizedBox(height: DSSpacing.xs),

          // Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DSBadge(
                label: customer.isActive
                    ? (customer.hasPurchases ? 'Cliente Ativo' : 'Novo')
                    : 'Inativo',
                type: customer.isActive
                    ? DSBadgeType.success
                    : DSBadgeType.error,
              ),
              if (customer.agentOff) ...[
                const SizedBox(width: DSSpacing.xs),
                DSBadge(label: 'Agente IA Pausado', type: DSBadgeType.warning),
              ],
            ],
          ),
          const SizedBox(height: DSSpacing.md),

          // Toggle Agente IA
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.base,
              vertical: DSSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: customer.agentOff
                  ? colors.orange.withValues(alpha: 0.08)
                  : colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy_rounded,
                  size: 18,
                  color: customer.agentOff ? colors.orange : colors.green,
                ),
                const SizedBox(width: DSSpacing.sm),
                Text(
                  'Agente IA',
                  style: textStyles.bodySmall.copyWith(
                    color: customer.agentOff ? colors.orange : colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: DSSpacing.xs),
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: !customer.agentOff,
                    activeColor: colors.green,
                    onChanged: (value) => _handleToggleAgent(!value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.md),

          Divider(color: colors.divider),
          const SizedBox(height: DSSpacing.md),

          // WhatsApp
          _buildContactRow(
            colors,
            textStyles,
            icon: Icons.phone_android_rounded,
            label: 'WhatsApp',
            value: customer.whatsapp.formatWhatsApp(),
            actionIcon: Icons.chat_rounded,
            actionColor: const Color(0xFF25D366),
            actionTooltip: 'Abrir WhatsApp',
            onAction: () => _openWhatsApp(customer.whatsapp),
          ),
          const SizedBox(height: DSSpacing.md),

          // Email
          if (customer.email != null && customer.email!.isNotEmpty) ...[
            _buildContactRow(
              colors,
              textStyles,
              icon: Icons.email_outlined,
              label: 'Email',
              value: customer.email!,
              actionIcon: Icons.send_rounded,
              actionColor: colors.primaryColor,
              actionTooltip: 'Enviar Email',
              onAction: () => _openEmail(customer.email!),
            ),
            const SizedBox(height: DSSpacing.md),
          ],

          // Observações
          if (customer.notes != null && customer.notes!.isNotEmpty) ...[
            Divider(color: colors.divider),
            const SizedBox(height: DSSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Observações', style: textStyles.labelLarge),
            ),
            const SizedBox(height: DSSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                customer.notes!,
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(
    DSColors colors,
    DSTextStyle textStyles, {
    required IconData icon,
    required String label,
    required String value,
    required IconData actionIcon,
    required Color actionColor,
    required String actionTooltip,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Icon(icon, size: DSSpacing.iconMd, color: colors.textTertiary),
        const SizedBox(width: DSSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textStyles.caption.copyWith(color: colors.textTertiary),
              ),
              const SizedBox(height: DSSpacing.xxs),
              Text(value, style: textStyles.bodyLarge),
            ],
          ),
        ),
        Tooltip(
          message: actionTooltip,
          child: InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(DSSpacing.sm),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: Icon(actionIcon, color: actionColor, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(DSColors colors) {
    final customer = _customer!;
    final totalCompras = customer.purchaseCount ?? 0;
    final totalGasto = customer.totalSpent ?? 0.0;
    final ticketMedio = totalCompras > 0 ? totalGasto / totalCompras : 0.0;
    final diasDesde = customer.diasDesdeCadastro;

    return Wrap(
      spacing: DSSpacing.md,
      runSpacing: DSSpacing.md,
      children: [
        SizedBox(
          width: 180,
          child: DSMetricCard(
            title: 'Total Compras',
            value: totalCompras.toString(),
            icon: Icons.shopping_cart_rounded,
          ),
        ),
        SizedBox(
          width: 180,
          child: DSMetricCard(
            title: 'Total Gasto',
            value: totalGasto.formatToBRL(),
            icon: Icons.attach_money_rounded,
          ),
        ),
        SizedBox(
          width: 180,
          child: DSMetricCard(
            title: 'Ticket Médio',
            value: ticketMedio.formatToBRL(),
            icon: Icons.receipt_long_rounded,
          ),
        ),
        SizedBox(
          width: 180,
          child: DSMetricCard(
            title: 'Cliente Desde',
            value: '$diasDesde dias',
            icon: Icons.calendar_today_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseHistory(DSColors colors, DSTextStyle textStyles) {
    final customer = _customer!;

    return Container(
      padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Compras (${customer.purchaseCount ?? 0})',
            style: textStyles.labelLarge,
          ),
          const SizedBox(height: DSSpacing.md),

          if (_loadingSales)
            const Center(child: CircularProgressIndicator())
          else if (_recentSales.isEmpty)
            Text(
              'Nenhuma compra registrada.',
              style: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
            )
          else ...[
            ..._recentSales.map(
              (sale) => _buildSaleItem(colors, textStyles, sale),
            ),
            if ((customer.purchaseCount ?? 0) > 5) ...[
              const SizedBox(height: DSSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/sales',
                      arguments: {'customerName': _customer!.name},
                    );
                  },
                  child: Text(
                    'Ver Todas as Compras →',
                    style: textStyles.bodyMedium.copyWith(
                      color: colors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSaleItem(
    DSColors colors,
    DSTextStyle textStyles,
    Map<String, dynamic> sale,
  ) {
    final total = (sale['total'] as num?)?.toDouble() ?? 0.0;
    final status = sale['status'] as String? ?? 'pending';
    final source = sale['source'] as String? ?? 'manual';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${(sale['uid'] as String? ?? '').substring(0, 5).toUpperCase()}',
                  style: textStyles.labelLarge,
                ),
                const SizedBox(height: DSSpacing.xxs),
                Text(
                  total.formatToBRL(),
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              DSBadge(
                label: source == 'whatsapp_automation' ? 'WhatsApp' : 'Manual',
                type: source == 'whatsapp_automation'
                    ? DSBadgeType.primary
                    : DSBadgeType.info,
                size: DSBadgeSize.small,
              ),
              const SizedBox(width: DSSpacing.xs),
              DSBadge(
                label: _statusLabel(status),
                type: _statusBadgeType(status),
                size: DSBadgeSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  DSBadgeType _statusBadgeType(String status) {
    switch (status) {
      case 'confirmed':
        return DSBadgeType.success;
      case 'cancelled':
        return DSBadgeType.error;
      default:
        return DSBadgeType.warning;
    }
  }

  // MARK: - Actions

  void _openWhatsApp(String whatsapp) {
    final url = 'https://wa.me/55$whatsapp';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openEmail(String email) {
    launchUrl(Uri.parse('mailto:$email'));
  }

  Future<void> _handleToggleAgent(bool agentOff) async {
    final updated = _customer!.copyWith(agentOff: agentOff);
    final success = await _repository.update(updated);
    if (success && mounted) {
      setState(() => _customer = updated);
    }
  }

  Future<void> _handleDelete(CustomerModel customer) async {
    await _presenter.deleteCustomer(customer);
    if (mounted) {
      CustomersCoordinator.navigateBack(context, result: true);
    }
  }
}
