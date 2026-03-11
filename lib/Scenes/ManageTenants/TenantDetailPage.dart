import 'package:flutter/material.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Models/MembershipModel.dart';
import '../../Commons/Enums/UserRole.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Extensions/String+Extensions.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSListTile.dart';
import '../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'TenantsRepository.dart';

/// Página de detalhes de um Tenant — Módulo 7.
///
/// Exibe informações, estatísticas, membros e ações.
class TenantDetailPage extends StatefulWidget {
  const TenantDetailPage({super.key});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  final TenantsRepository _repository = TenantsRepository();

  TenantModel? _tenant;
  Map<String, int> _stats = {};
  List<MembershipModel> _members = [];
  double _revenue = 0;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _tenant == null) {
      final tenantId = ModalRoute.of(context)?.settings.arguments as String?;
      if (tenantId != null) {
        _loadTenantDetails(tenantId);
      }
    }
  }

  Future<void> _loadTenantDetails(String tenantId) async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _repository.getById(tenantId),
        _repository.getTenantStats(tenantId),
        _repository.getTenantMembers(tenantId),
        _repository.getTenantRevenue(tenantId),
      ]);

      setState(() {
        _tenant = results[0] as TenantModel?;
        _stats = results[1] as Map<String, int>;
        _members = results[2] as List<MembershipModel>;
        _revenue = results[3] as double;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar detalhes do tenant', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/admin/tenants',
      child: _isLoading
          ? const LoadingIndicator(message: 'Carregando tenant...')
          : _tenant == null
          ? const Center(child: Text('Tenant não encontrado.'))
          : ScreenResponsive(
              web: _buildWebLayout(),
              mobile: _buildMobileLayout(),
            ),
    );
  }

  // MARK: - Web Layout

  Widget _buildWebLayout() {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
        vertical: DSSpacing.pagePaddingVerticalWeb,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildInfoSection(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildStatsSection(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildMembersSection(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildActionsSection(colors, textStyles),
          const SizedBox(height: DSSpacing.xxl),
        ],
      ),
    );
  }

  // MARK: - Mobile Layout

  Widget _buildMobileLayout() {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_tenant!.name, style: textStyles.headline2),
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(colors, textStyles),
            const SizedBox(height: DSSpacing.lg),
            _buildStatsSection(colors, textStyles),
            const SizedBox(height: DSSpacing.lg),
            _buildMembersSection(colors, textStyles),
            const SizedBox(height: DSSpacing.lg),
            _buildActionsSection(colors, textStyles),
            const SizedBox(height: DSSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // MARK: - Header (Web only)

  Widget _buildHeader(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: DSSpacing.sm),
        CircleAvatar(
          radius: 24,
          backgroundColor: _planColor.withValues(alpha: 0.15),
          child: Text(
            _tenant!.name[0].toUpperCase(),
            style: textStyles.headline2.copyWith(color: _planColor),
          ),
        ),
        const SizedBox(width: DSSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tenant!.name, style: textStyles.headline1),
              Row(
                children: [
                  DSBadge(label: _planLabel, type: _planBadgeType),
                  const SizedBox(width: DSSpacing.xs),
                  DSBadge(
                    label: _tenant!.isActive ? 'Ativo' : 'Inativo',
                    type: _tenant!.isActive
                        ? DSBadgeType.success
                        : DSBadgeType.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        DSButton.primary(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onTap: _navigateToEdit,
        ),
      ],
    );
  }

  // MARK: - Info Section

  Widget _buildInfoSection(DSColors colors, DSTextStyle textStyles) {
    return _buildCard(
      colors: colors,
      title: 'Informações',
      icon: Icons.info_outline,
      textStyles: textStyles,
      child: Column(
        children: [
          _buildInfoRow(
            'E-mail',
            _tenant!.contactEmail,
            Icons.email_outlined,
            colors,
            textStyles,
          ),
          _buildInfoRow(
            'Telefone',
            _tenant!.contactPhone.isNotEmpty
                ? _tenant!.contactPhone.formatWhatsApp()
                : '—',
            Icons.phone_outlined,
            colors,
            textStyles,
          ),
          _buildInfoRow(
            'Plano',
            _planLabel,
            Icons.workspace_premium_outlined,
            colors,
            textStyles,
          ),
          _buildInfoRow(
            'Criado em',
            _tenant!.createdAt.formatDateTime(),
            Icons.calendar_today_outlined,
            colors,
            textStyles,
          ),
          if (_tenant!.isTrial && _tenant!.trialEndDate != null)
            _buildInfoRow(
              'Trial expira em',
              '${_tenant!.trialDaysRemaining} dias (${_tenant!.trialEndDate!.formatShort()})',
              Icons.hourglass_top_rounded,
              colors,
              textStyles,
            ),
          if (_tenant!.nextPaymentDate != null)
            _buildInfoRow(
              'Próx. pagamento',
              _tenant!.nextPaymentDate!.formatShort(),
              Icons.payment_outlined,
              colors,
              textStyles,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textTertiary),
          const SizedBox(width: DSSpacing.sm),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ),
          Expanded(child: Text(value, style: textStyles.bodyMedium)),
        ],
      ),
    );
  }

  // MARK: - Stats Section

  Widget _buildStatsSection(DSColors colors, DSTextStyle textStyles) {
    final statsProducts = _stats['products'] ?? 0;
    final statsCustomers = _stats['customers'] ?? 0;
    final statsSales = _stats['sales'] ?? 0;
    final avgTicket = statsSales > 0 ? _revenue / statsSales : 0.0;

    return _buildCard(
      colors: colors,
      title: 'Estatísticas',
      icon: Icons.bar_chart_rounded,
      textStyles: textStyles,
      child: Wrap(
        spacing: DSSpacing.md,
        runSpacing: DSSpacing.md,
        children: [
          SizedBox(
            width: 160,
            child: DSMetricCard(
              title: 'Usuários',
              value: '${_members.length}',
              icon: Icons.people_outline,
              color: colors.blue,
            ),
          ),
          SizedBox(
            width: 160,
            child: DSMetricCard(
              title: 'Produtos',
              value: '$statsProducts',
              icon: Icons.inventory_2_outlined,
              color: colors.primaryColor,
            ),
          ),
          SizedBox(
            width: 160,
            child: DSMetricCard(
              title: 'Clientes',
              value: '$statsCustomers',
              icon: Icons.person_outline,
              color: colors.green,
            ),
          ),
          SizedBox(
            width: 160,
            child: DSMetricCard(
              title: 'Vendas',
              value: '$statsSales',
              icon: Icons.shopping_cart_outlined,
              color: colors.yellow,
            ),
          ),
          SizedBox(
            width: 160,
            child: DSMetricCard(
              title: 'Receita',
              value: _revenue.formatToBRL(),
              icon: Icons.attach_money_rounded,
              color: colors.green,
            ),
          ),
          SizedBox(
            width: 160,
            child: DSMetricCard(
              title: 'Ticket Médio',
              value: avgTicket.formatToBRL(),
              icon: Icons.receipt_long_outlined,
              color: colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Members Section

  Widget _buildMembersSection(DSColors colors, DSTextStyle textStyles) {
    return _buildCard(
      colors: colors,
      title: 'Membros (${_members.length})',
      icon: Icons.group_outlined,
      textStyles: textStyles,
      child: _members.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(DSSpacing.md),
              child: Text(
                'Nenhum membro encontrado.',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            )
          : Column(
              children: _members
                  .map(
                    (m) => DSListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (m.userName ?? '').isNotEmpty
                              ? m.userName![0].toUpperCase()
                              : 'U',
                          style: textStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primaryColor,
                          ),
                        ),
                      ),
                      title: m.userName ?? 'Sem nome',
                      subtitle: m.userEmail ?? '',
                      badges: [
                        DSBadge(
                          label: m.role.label,
                          type: m.role == UserRole.tenantAdmin
                              ? DSBadgeType.primary
                              : DSBadgeType.info,
                          size: DSBadgeSize.small,
                        ),
                        DSBadge(
                          label: m.isActive ? 'Ativo' : 'Inativo',
                          type: m.isActive
                              ? DSBadgeType.success
                              : DSBadgeType.error,
                          size: DSBadgeSize.small,
                        ),
                      ],
                      metadata: 'Desde ${m.createdAt.formatShort()}',
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // MARK: - Actions Section

  Widget _buildActionsSection(DSColors colors, DSTextStyle textStyles) {
    return _buildCard(
      colors: colors,
      title: 'Ações',
      icon: Icons.settings_outlined,
      textStyles: textStyles,
      child: Wrap(
        spacing: DSSpacing.md,
        runSpacing: DSSpacing.md,
        children: [
          // Estender Trial
          if (_tenant!.isTrial)
            DSButton.secondary(
              label: 'Estender Trial +7 dias',
              icon: Icons.add_circle_outline,
              onTap: _extendTrial,
            ),

          // Alterar Plano
          DSButton.secondary(
            label: 'Alterar Plano',
            icon: Icons.workspace_premium_outlined,
            onTap: _changePlan,
          ),

          // Ativar / Inativar
          DSButton.secondary(
            label: _tenant!.isActive ? 'Inativar Tenant' : 'Ativar Tenant',
            icon: _tenant!.isActive
                ? Icons.block_rounded
                : Icons.check_circle_outline,
            onTap: _toggleActive,
          ),

          // Impersonar
          DSButton.secondary(
            label: 'Impersonar',
            icon: Icons.login_rounded,
            onTap: _impersonate,
          ),

          // Excluir
          DSButton.danger(
            label: 'Excluir Tenant',
            icon: Icons.delete_forever_rounded,
            onTap: _deleteTenant,
          ),
        ],
      ),
    );
  }

  // MARK: - Action Handlers

  Future<void> _extendTrial() async {
    final confirmed = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Estender Trial',
      message: 'Deseja adicionar mais 7 dias ao trial de "${_tenant!.name}"?',
    );
    if (confirmed == true && mounted) {
      final success = await _repository.extendTrial(_tenant!.uid, 7);
      if (success && mounted) {
        DSAlertDialog.showSuccess(
          context: context,
          title: 'Trial estendido',
          message: 'Mais 7 dias foram adicionados.',
        );
        _loadTenantDetails(_tenant!.uid);
      }
    }
  }

  void _changePlan() {
    String newPlan = _tenant!.plan;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Alterar Plano'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Trial'),
                value: 'trial',
                groupValue: newPlan,
                onChanged: (v) => setDialogState(() => newPlan = v!),
              ),
              RadioListTile<String>(
                title: const Text('Basic'),
                value: 'basic',
                groupValue: newPlan,
                onChanged: (v) => setDialogState(() => newPlan = v!),
              ),
              RadioListTile<String>(
                title: const Text('Full'),
                value: 'full',
                groupValue: newPlan,
                onChanged: (v) => setDialogState(() => newPlan = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (newPlan != _tenant!.plan) {
                  final success = await _repository.changePlan(
                    _tenant!.uid,
                    newPlan,
                  );
                  if (success && mounted) {
                    DSAlertDialog.showSuccess(
                      context: context,
                      title: 'Plano alterado',
                      message:
                          'O plano foi alterado para ${newPlan.toUpperCase()}.',
                    );
                    _loadTenantDetails(_tenant!.uid);
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive() async {
    final toggleTo = !_tenant!.isActive;
    final action = toggleTo ? 'ativar' : 'inativar';

    final confirmed = await DSAlertDialog.showConfirm(
      context: context,
      title: '${toggleTo ? 'Ativar' : 'Inativar'} Tenant',
      message: 'Deseja $action "${_tenant!.name}"?',
    );
    if (confirmed == true && mounted) {
      final success = await _repository.toggleActive(_tenant!.uid, toggleTo);
      if (success && mounted) {
        DSAlertDialog.showSuccess(
          context: context,
          title: 'Tenant ${toggleTo ? 'ativado' : 'inativado'}',
          message:
              '"${_tenant!.name}" foi ${toggleTo ? 'ativado' : 'inativado'} com sucesso.',
        );
        _loadTenantDetails(_tenant!.uid);
      }
    }
  }

  void _impersonate() {
    DSAlertDialog.showWarning(
      context: context,
      title: 'Impersonar Tenant',
      message:
          'Você será redirecionado ao dashboard como "${_tenant!.name}". '
          'Essa ação será registrada em log.',
    );

    // TODO: Implementar lógica de impersonação
    // 1. SessionManager.switchTenant(_tenant!)
    // 2. AppLogger.info('SuperAdmin impersonou tenant: ${_tenant!.uid}')
    // 3. Navigator.pushNamedAndRemoveUntil('/dashboard', (_) => false)
    AppLogger.info(
      'SuperAdmin impersonou tenant: ${_tenant!.uid} - ${_tenant!.name}',
    );
  }

  Future<void> _deleteTenant() async {
    final confirmed = await DSAlertDialog.showDelete(
      context: context,
      title: 'Excluir Tenant',
      message:
          'Tem certeza que deseja excluir "${_tenant!.name}"? '
          'Todos os dados serão removidos permanentemente.',
    );
    if (confirmed == true && mounted) {
      _showDeleteNameConfirmation();
    }
  }

  void _showDeleteNameConfirmation() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digite o nome do tenant para confirmar:'),
            const SizedBox(height: 8),
            Text(
              _tenant!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nome do tenant',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim() == _tenant!.name) {
                Navigator.pop(ctx);
                final success = await _repository.deleteTenant(_tenant!.uid);
                if (mounted && success) {
                  DSAlertDialog.showSuccess(
                    context: context,
                    title: 'Tenant excluído',
                    message: '"${_tenant!.name}" foi removido com sucesso.',
                  );
                  Navigator.pop(context); // back to list
                }
              }
            },
            child: Text('Excluir', style: TextStyle(color: DSColors().red)),
          ),
        ],
      ),
    );
  }

  // MARK: - Navigation

  void _navigateToEdit() {
    Navigator.pushNamed(
      context,
      '/admin/tenants/edit',
      arguments: _tenant!.uid,
    ).then((_) {
      if (_tenant != null) _loadTenantDetails(_tenant!.uid);
    });
  }

  // MARK: - Helpers

  Widget _buildCard({
    required DSColors colors,
    required String title,
    required IconData icon,
    required DSTextStyle textStyles,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.textTertiary),
              const SizedBox(width: DSSpacing.sm),
              Text(title, style: textStyles.headline3),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          child,
        ],
      ),
    );
  }

  String get _planLabel {
    switch (_tenant!.plan) {
      case 'trial':
        return 'Trial';
      case 'basic':
        return 'Basic';
      case 'full':
        return 'Full';
      default:
        return _tenant!.plan;
    }
  }

  DSBadgeType get _planBadgeType {
    switch (_tenant!.plan) {
      case 'trial':
        return DSBadgeType.warning;
      case 'basic':
        return DSBadgeType.info;
      case 'full':
        return DSBadgeType.success;
      default:
        return DSBadgeType.info;
    }
  }

  Color get _planColor {
    final colors = DSColors();
    switch (_tenant!.plan) {
      case 'trial':
        return colors.yellow;
      case 'basic':
        return colors.blue;
      case 'full':
        return colors.green;
      default:
        return colors.blue;
    }
  }
}
