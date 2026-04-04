import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Commons/Enums/PlanPeriod.dart';
import '../../Commons/Enums/PlanTier.dart';
import '../../Commons/Models/PlanCatalogModel.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../../Sources/BackendApi.dart';
import '../ManageTenants/TenantsRepository.dart';
import '../SuperAdminPlans/PlanCatalogRepository.dart';

/// Tela de upgrade de plano com pagamento via PIX.
///
/// Fluxo:
/// 1. Selecionar plano (período + tier)
/// 2. Gerar PIX via API intermediária (n8n → EFI)
/// 3. Exibir QR Code + código copia-e-cola
/// 4. Listener no Firestore detecta pagamento via webhook
/// 5. Confirmar e atualizar UI
class UpgradePlanPage extends StatefulWidget {
  const UpgradePlanPage({super.key});

  @override
  State<UpgradePlanPage> createState() => _UpgradePlanPageState();
}

class _UpgradePlanPageState extends State<UpgradePlanPage> {
  final TenantsRepository _repository = TenantsRepository();
  final PlanCatalogRepository _planRepository = PlanCatalogRepository();

  // Seleção do plano
  String _selectedPeriod = 'monthly';
  String _selectedTier = 'standard';
  List<PlanCatalogModel> _availablePlans = const [];
  bool _isLoadingPlans = true;

  // Estado do pagamento
  bool _isGeneratingPix = false;
  bool _paymentConfirmed = false;
  String? _pixCode;
  String? _qrCodeBase64;
  String? _paymentId;
  String? _errorMessage;

  // Listener no documento do tenant
  StreamSubscription? _tenantListener;

  TenantModel? get _tenant => SessionManager.instance.currentTenant;

  @override
  void initState() {
    super.initState();
    // Se o tenant já tem um plano pago, pré-selecionar
    if (_tenant != null && _tenant!.isPaidPlan) {
      _selectedPeriod = _tenant!.plan;
      _selectedTier = _tenant!.planTier;
    }
    _loadPlans();
  }

  @override
  void dispose() {
    _tenantListener?.cancel();
    super.dispose();
  }

  PlanCatalogModel get _selectedPlan {
    return _availablePlans.firstWhere(
      (plan) => plan.period == _selectedPeriod && plan.tier == _selectedTier,
      orElse: () => PlanCatalogModel.defaultFor(_selectedPeriod, _selectedTier),
    );
  }

  double get _selectedPrice => _selectedPlan.price;

  int get _selectedDays => _selectedPlan.durationDays;

  String get _selectedPlanLabel => _selectedPlan.displayName;

  List<PlanCatalogModel> get _periodPlans {
    final plans = _availablePlans
        .where((plan) => plan.period == _selectedPeriod && plan.isActive)
        .toList();
    plans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return plans;
  }

  Future<void> _loadPlans() async {
    final plans = await _planRepository.getAll();
    if (!mounted) return;
    setState(() {
      _availablePlans = plans.where((plan) => plan.period != 'trial').toList();
      _isLoadingPlans = false;
      final hasSelectedPlan = _availablePlans.any(
        (plan) => plan.period == _selectedPeriod && plan.tier == _selectedTier,
      );
      if (!hasSelectedPlan && _availablePlans.isNotEmpty) {
        _selectedPeriod = _availablePlans.first.period;
        _selectedTier = _availablePlans.first.tier;
      }
    });
  }

  // MARK: - Gerar PIX

  Future<void> _generatePix() async {
    if (_tenant == null) return;

    setState(() {
      _isGeneratingPix = true;
      _errorMessage = null;
    });

    try {
      final checkout = await BackendApi.instance.postAuthenticated(
        functionName: 'createPixCheckout',
        body: {
          'tenantId': _tenant!.uid,
          'plan': _selectedPeriod,
          'planTier': _selectedTier,
          'amount': _selectedPrice,
          'expirationDays': _selectedDays,
        },
      );

      setState(() {
        _paymentId = checkout['paymentId'] as String?;
        _pixCode = checkout['pixCode'] as String?;
        _qrCodeBase64 = checkout['qrCodeBase64'] as String?;
        _isGeneratingPix = false;
      });

      if (_paymentId == null || _pixCode == null || _pixCode!.isEmpty) {
        setState(() {
          _errorMessage =
              'Checkout criado, mas o provedor de pagamento ainda não foi configurado no backend.';
        });
        return;
      }

      _startPaymentListener();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isGeneratingPix = false;
      });
    }
  }

  void _startPaymentListener() {
    if (_tenant == null) return;

    _tenantListener?.cancel();
    _tenantListener = _repository.listenTenant(_tenant!.uid).listen((tenant) {
      if (tenant == null) return;

      // Detectar se o lastPaymentId mudou (webhook atualizou)
      if (tenant.lastPaymentId == _paymentId &&
          !tenant.isExpiredDynamic &&
          !_paymentConfirmed) {
        setState(() {
          _paymentConfirmed = true;
        });

        // Atualizar sessão
        SessionManager.instance.updateTenant(tenant);

        _tenantListener?.cancel();
      }
    });
  }

  void _copyPixCode() {
    if (_pixCode != null) {
      Clipboard.setData(ClipboardData(text: _pixCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código PIX copiado!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final isWeb = MediaQuery.of(context).size.width >= 1000;

    return AppShell(
      currentRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text('Upgrade de Plano', style: textStyles.headline2),
          backgroundColor: colors.cardBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? DSSpacing.xxxl : DSSpacing.md,
            vertical: DSSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _paymentConfirmed
                  ? _buildSuccessView(colors, textStyles)
                  : _pixCode != null
                  ? _buildPixView(colors, textStyles)
                  : _buildPlanSelection(colors, textStyles),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Plan Selection View

  Widget _buildPlanSelection(DSColors colors, DSTextStyle textStyles) {
    if (_isLoadingPlans) {
      return const LoadingIndicator(message: 'Carregando planos...');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current plan info
        if (_tenant != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DSSpacing.md),
            decoration: BoxDecoration(
              color: colors.blueLight,
              borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
              border: Border.all(color: colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.blue),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: Text(
                    'Plano atual: ${_tenant!.planLabel}${_tenant!.expirationDate != null ? ' • Expira em ${_tenant!.daysUntilExpiration} dias' : ''}',
                    style: textStyles.bodyMedium.copyWith(color: colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.xl),
        ],

        Text('Escolha seu plano', style: textStyles.headline2),
        const SizedBox(height: DSSpacing.xs),
        Text(
          'Selecione o período e nível que melhor se adapta ao seu negócio.',
          style: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.lg),

        // Period selection
        Text(
          'Período',
          style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: DSSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildPeriodCard(
                period: 'monthly',
                title: 'Mensal',
                subtitle:
                    '${PlanCatalogModel.defaultFor('monthly', 'standard').durationDays} dias',
                colors: colors,
                textStyles: textStyles,
              ),
            ),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: _buildPeriodCard(
                period: 'quarterly',
                title: 'Trimestral',
                subtitle:
                    '${PlanCatalogModel.defaultFor('quarterly', 'standard').durationDays} dias',
                badge: 'Economia',
                colors: colors,
                textStyles: textStyles,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.lg),

        // Tier selection
        Text(
          'Nível',
          style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: DSSpacing.sm),
        ..._periodPlans.asMap().entries.map((entry) {
          final plan = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _periodPlans.length - 1 ? 0 : DSSpacing.sm,
            ),
            child: _buildTierCard(
              plan: plan,
              colors: colors,
              textStyles: textStyles,
            ),
          );
        }),
        const SizedBox(height: DSSpacing.xl),

        // Price summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              Text(_selectedPlanLabel, style: textStyles.headline3),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'R\$ ${_selectedPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                style: textStyles.headline1.copyWith(
                  color: colors.primaryColor,
                  fontSize: 36,
                ),
              ),
              Text(
                'por $_selectedDays dias',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.lg),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(DSSpacing.sm),
            decoration: BoxDecoration(
              color: colors.redLight,
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colors.red, size: 20),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: textStyles.bodySmall.copyWith(color: colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.md),
        ],

        // Generate PIX button
        SizedBox(
          width: double.infinity,
          child: DSButton.primary(
            label:
                'Gerar PIX • R\$ ${_selectedPrice.toStringAsFixed(2).replaceAll('.', ',')}',
            icon: Icons.pix_rounded,
            isLoading: _isGeneratingPix,
            onTap: _generatePix,
          ),
        ),
        const SizedBox(height: DSSpacing.xxl),
      ],
    );
  }

  Widget _buildPeriodCard({
    required String period,
    required String title,
    required String subtitle,
    String? badge,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = _selectedPeriod == period;
    final periodPlans = _availablePlans
        .where((plan) => plan.period == period && plan.isActive)
        .toList();
    final minDays = periodPlans.isEmpty
        ? PlanPeriod.fromString(period).durationDays
        : periodPlans.first.durationDays;

    return InkWell(
      onTap: () => setState(() {
        _selectedPeriod = period;
        final firstActiveTier = _availablePlans.firstWhere(
          (plan) => plan.period == period && plan.isActive,
          orElse: () => PlanCatalogModel.defaultFor(period, 'standard'),
        );
        _selectedTier = firstActiveTier.tier;
      }),
      borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colors.primaryColor : colors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.05)
              : colors.cardBackground,
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.green,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Text(
                  badge,
                  style: textStyles.labelSmall.copyWith(color: colors.white),
                ),
              ),
            if (badge != null) const SizedBox(height: DSSpacing.xs),
            Text(
              title,
              style: textStyles.headline3.copyWith(
                color: isSelected ? colors.primaryColor : colors.textPrimary,
              ),
            ),
            Text(
              subtitle.replaceFirst(RegExp(r'^\d+'), minDays.toString()),
              style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required PlanCatalogModel plan,
    String? badge,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = _selectedTier == plan.tier;
    final tierLabel = PlanTier.fromString(plan.tier).label;

    return InkWell(
      onTap: () => setState(() => _selectedTier = plan.tier),
      borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colors.primaryColor : colors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.05)
              : colors.cardBackground,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: plan.tier,
              groupValue: _selectedTier,
              onChanged: (v) {
                if (v != null) setState(() => _selectedTier = v);
              },
              activeColor: colors.primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tierLabel,
                        style: textStyles.headline3.copyWith(
                          color: isSelected
                              ? colors.primaryColor
                              : colors.textPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: DSSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DSSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryColor,
                            borderRadius: BorderRadius.circular(
                              DSSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: textStyles.labelSmall.copyWith(
                              color: colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DSSpacing.xs),
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            f,
                            style: textStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
              style: textStyles.headline3.copyWith(
                color: isSelected ? colors.primaryColor : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - PIX View

  Widget _buildPixView(DSColors colors, DSTextStyle textStyles) {
    return Column(
      children: [
        const SizedBox(height: DSSpacing.xl),
        Icon(Icons.pix_rounded, size: 48, color: colors.secundaryColor),
        const SizedBox(height: DSSpacing.md),
        Text('Pague via PIX', style: textStyles.headline2),
        const SizedBox(height: DSSpacing.xs),
        Text(
          '$_selectedPlanLabel • R\$ ${_selectedPrice.toStringAsFixed(2).replaceAll('.', ',')}',
          style: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.xl),

        // QR Code
        if (_qrCodeBase64 != null)
          Container(
            padding: const EdgeInsets.all(DSSpacing.lg),
            decoration: BoxDecoration(
              color: colors.white,
              borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
              border: Border.all(color: colors.divider),
            ),
            child: Image.memory(
              base64Decode(_qrCodeBase64!),
              width: 250,
              height: 250,
            ),
          )
        else
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: colors.surfaceOverlay,
              borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 80,
                  color: colors.textTertiary,
                ),
                const SizedBox(height: DSSpacing.sm),
                Text(
                  'QR Code será exibido\nquando a API estiver integrada',
                  textAlign: TextAlign.center,
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: DSSpacing.lg),

        // Copia e cola
        Text(
          'Ou copie o código PIX:',
          style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: DSSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceOverlay,
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            border: Border.all(color: colors.divider),
          ),
          child: SelectableText(
            _pixCode ?? '',
            style: textStyles.bodySmall.copyWith(
              fontFamily: 'monospace',
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: DSSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: DSButton.secondary(
            label: 'Copiar código PIX',
            icon: Icons.content_copy_rounded,
            onTap: _copyPixCode,
          ),
        ),
        const SizedBox(height: DSSpacing.xl),

        // Aguardando
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: colors.yellowLight,
            borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
            border: Border.all(color: colors.yellow.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: Text(
                  'Aguardando confirmação do pagamento...\nO status será atualizado automaticamente.',
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.xxl),
      ],
    );
  }

  // MARK: - Success View

  Widget _buildSuccessView(DSColors colors, DSTextStyle textStyles) {
    return Column(
      children: [
        const SizedBox(height: DSSpacing.xxxl),
        Container(
          padding: const EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
            color: colors.greenLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: colors.green,
          ),
        ),
        const SizedBox(height: DSSpacing.lg),
        Text('Pagamento confirmado!', style: textStyles.headline1),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Seu plano $_selectedPlanLabel foi ativado com sucesso.',
          style: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.xxl),
        SizedBox(
          width: 300,
          child: DSButton.primary(
            label: 'Ir para o Dashboard',
            icon: Icons.dashboard_rounded,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (_) => false,
              );
            },
          ),
        ),
        const SizedBox(height: DSSpacing.xxl),
      ],
    );
  }
}
