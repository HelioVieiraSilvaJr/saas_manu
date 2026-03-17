import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Commons/Enums/PlanPeriod.dart';
import '../../Commons/Enums/PlanTier.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Models/PaymentModel.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../ManageTenants/TenantsRepository.dart';

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

  // Seleção do plano
  String _selectedPeriod = 'monthly';
  String _selectedTier = 'standard';

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
  }

  @override
  void dispose() {
    _tenantListener?.cancel();
    super.dispose();
  }

  double get _selectedPrice {
    return PlanTier.fromString(_selectedTier).priceForPeriod(_selectedPeriod);
  }

  int get _selectedDays {
    return PlanPeriod.fromString(_selectedPeriod).durationDays;
  }

  String get _selectedPlanLabel {
    final period = PlanPeriod.fromString(_selectedPeriod).label;
    final tier = PlanTier.fromString(_selectedTier).label;
    return '$period $tier';
  }

  // MARK: - Gerar PIX

  Future<void> _generatePix() async {
    if (_tenant == null) return;

    setState(() {
      _isGeneratingPix = true;
      _errorMessage = null;
    });

    try {
      // 1. Criar registro de pagamento pendente no Firestore
      final now = DateTime.now();
      final expiration = now.add(Duration(days: _selectedDays));

      final payment = PaymentModel(
        uid: '',
        plan: _selectedPeriod,
        planTier: _selectedTier,
        amount: _selectedPrice,
        status: PaymentStatus.pending,
        createdAt: now,
        planExpirationDate: expiration,
      );

      final paymentId = await _repository.createPayment(_tenant!.uid, payment);

      if (paymentId == null) {
        setState(() {
          _errorMessage = 'Erro ao criar registro de pagamento.';
          _isGeneratingPix = false;
        });
        return;
      }

      _paymentId = paymentId;

      // 2. TODO: Chamar API intermediária (n8n) para gerar PIX via EFI
      // O endpoint receberá:
      // - tenant_id, tenant_name, tenant_email
      // - payment_id
      // - plan, plan_tier, amount
      // E retornará:
      // - pix_code (copia-e-cola)
      // - qr_code_base64
      // - transaction_id (EFI)
      //
      // Por enquanto, simulação para desenvolvimento:
      await Future.delayed(const Duration(seconds: 1));

      // Simulação — substituir pela chamada real à API
      setState(() {
        _pixCode =
            '00020126580014br.gov.bcb.pix0136${_tenant!.uid.substring(0, 8)}-pix-${paymentId.substring(0, 6)}5204000053039865802BR5925SAAS MANU LTDA6009SAO PAULO62070503***63041234';
        _qrCodeBase64 = null; // Virá da API real
        _isGeneratingPix = false;
      });

      // 3. Iniciar listener no documento do tenant para detectar pagamento
      _startPaymentListener();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao gerar PIX. Tente novamente.';
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
                subtitle: '30 dias',
                colors: colors,
                textStyles: textStyles,
              ),
            ),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: _buildPeriodCard(
                period: 'quarterly',
                title: 'Trimestral',
                subtitle: '90 dias',
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
        _buildTierCard(
          tier: 'standard',
          title: 'Standard',
          features: [
            'Até 1.000 clientes',
            'Até 50 produtos',
            'CRM completo',
            'WhatsApp Bot',
          ],
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(height: DSSpacing.sm),
        _buildTierCard(
          tier: 'pro',
          title: 'Pro',
          features: [
            'Clientes ilimitados',
            'Até 500 produtos',
            'CRM completo',
            'WhatsApp Bot',
            'Suporte prioritário',
          ],
          badge: 'Recomendado',
          colors: colors,
          textStyles: textStyles,
        ),
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

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = period),
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
              subtitle,
              style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String title,
    required List<String> features,
    String? badge,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = _selectedTier == tier;
    final price = PlanTier.fromString(tier).priceForPeriod(_selectedPeriod);

    return InkWell(
      onTap: () => setState(() => _selectedTier = tier),
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
              value: tier,
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
                        title,
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
                  ...features.map(
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
              'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
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
