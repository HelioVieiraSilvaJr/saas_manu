import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../../Sources/SessionManager.dart';
import '../TenantSettingsPresenter.dart';
import '../TenantSettingsViewModel.dart';

/// Widget da seção "Integrações" — Módulo 8.
class IntegrationsSection extends StatefulWidget {
  final TenantSettingsPresenter presenter;
  final TenantSettingsViewModel viewModel;

  const IntegrationsSection({
    super.key,
    required this.presenter,
    required this.viewModel,
  });

  @override
  State<IntegrationsSection> createState() => _IntegrationsSectionState();
}

class _IntegrationsSectionState extends State<IntegrationsSection> {
  bool _showApiKey = false;
  Timer? _pollingTimer;

  TenantSettingsPresenter get presenter => widget.presenter;
  TenantSettingsViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant IntegrationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _syncPolling() {
    final shouldPoll =
        viewModel.hasManagedWhatsAppSetup &&
        !viewModel.isWhatsAppConnected &&
        !viewModel.isProvisioningManagedWhatsApp;

    if (!shouldPoll) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      return;
    }

    if (_pollingTimer != null) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      presenter.refreshManagedWhatsAppStatus(includeQrCode: true, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final isSuperAdmin = SessionManager.instance.isSuperAdmin;

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
          // Header
          Row(
            children: [
              Icon(Icons.power_outlined, size: 20, color: colors.textTertiary),
              const SizedBox(width: DSSpacing.sm),
              Text('Integrações', style: textStyles.headline3),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),

          // WhatsApp Section
          _buildWhatsAppSection(colors, textStyles),
          if (isSuperAdmin) ...[
            const SizedBox(height: DSSpacing.xl),

            // n8n Webhook Section
            _buildWebhookSection(colors, textStyles),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDisconnectManagedWhatsApp() async {
    final confirmed = await DSAlertDialog.showWarning(
      context: context,
      title: 'Desconectar WhatsApp',
      message:
          'Isso vai encerrar o numero atualmente conectado para que voce possa parear outro aparelho depois.',
      confirmLabel: 'Desconectar',
      cancelLabel: 'Cancelar',
    );

    if (confirmed == true) {
      await presenter.disconnectManagedWhatsApp();
    }
  }

  Widget _buildWhatsAppSection(DSColors colors, DSTextStyle textStyles) {
    final isSuperAdmin = SessionManager.instance.isSuperAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-header
        Row(
          children: [
            Icon(Icons.chat_outlined, size: 18, color: colors.green),
            const SizedBox(width: DSSpacing.xs),
            Text(
              'WhatsApp / Evolution API',
              style: textStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.sm,
                vertical: DSSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: viewModel.isWhatsAppConnected
                    ? colors.green.withValues(alpha: 0.1)
                    : colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: viewModel.isWhatsAppConnected
                        ? colors.green
                        : colors.red,
                  ),
                  const SizedBox(width: DSSpacing.xxs),
                  Text(
                    viewModel.isWhatsAppConnected
                        ? 'Conectado'
                        : 'Não Conectado',
                    style: textStyles.bodySmall.copyWith(
                      color: viewModel.isWhatsAppConnected
                          ? colors.green
                          : colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),

        _buildManagedWhatsAppPanel(colors, textStyles),
        if (isSuperAdmin) ...[
          const SizedBox(height: DSSpacing.lg),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: colors.textSecondary,
            collapsedIconColor: colors.textSecondary,
            title: Text(
              'Configuração avançada',
              style: textStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Use apenas como fallback manual da Evolution API.',
              style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
            ),
            children: [_buildAdvancedWhatsAppForm(colors, textStyles)],
          ),
        ],
      ],
    );
  }

  Widget _buildManagedWhatsAppPanel(DSColors colors, DSTextStyle textStyles) {
    final statusColor = _statusColor(colors);
    final hasQrCode = viewModel.managedWhatsAppQrCodeBase64.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.secundarySurface,
            colors.primarySurface.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: colors.secundaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integração Gerenciada',
                      style: textStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.xxs),
                    Text(
                      'Conecte o número do vendedor com QR Code e deixe a automação pronta para atender sem expor credenciais técnicas.',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Text(
                  viewModel.hasManagedWhatsAppSetup
                      ? viewModel.whatsappConnectionStatus
                      : 'Pronto para conectar',
                  style: textStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          Wrap(
            spacing: DSSpacing.sm,
            runSpacing: DSSpacing.sm,
            children: [
              _buildMetaChip(
                colors,
                textStyles,
                icon: Icons.hub_outlined,
                label: 'Provider',
                value: viewModel.hasManagedWhatsAppSetup
                    ? viewModel.whatsappProvider
                    : 'Evolution API',
              ),
              _buildMetaChip(
                colors,
                textStyles,
                icon: Icons.phone_iphone_outlined,
                label: 'Número',
                value: viewModel.whatsappConnectedNumber.isNotEmpty
                    ? viewModel.whatsappConnectedNumber
                    : 'Ainda não conectado',
              ),
              _buildMetaChip(
                colors,
                textStyles,
                icon: Icons.webhook_outlined,
                label: 'Webhook',
                value: viewModel.webhookToken.isNotEmpty
                    ? 'Pronto'
                    : 'Pendente',
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DSSpacing.sm),
            decoration: BoxDecoration(
              color: colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atendimento automático',
                        style: textStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.xxs),
                      Text(
                        viewModel.aiAgentEnabled
                            ? 'Ligado. O mestre de vendas responde novos contatos automaticamente.'
                            : 'Desligado. Novas conversas ficam para atendimento manual do tenant.',
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: viewModel.aiAgentEnabled,
                  onChanged: viewModel.isUpdatingAiAgentEnabled
                      ? null
                      : presenter.updateAiAgentEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.md),
          Text(
            viewModel.isWhatsAppConnected
                ? 'Tudo certo. Esse número já está apto para receber os contatos e alimentar o mestre de vendas.'
                : hasQrCode
                ? 'Escaneie o QR Code abaixo no WhatsApp do vendedor. Enquanto ele estiver aberto, a tela acompanha o status automaticamente.'
                : 'Clique em "Conectar número" para criar a instância gerenciada e abrir o QR Code de pareamento.',
            style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
          if (hasQrCode && !viewModel.isWhatsAppConnected) ...[
            const SizedBox(height: DSSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DSSpacing.lg),
              decoration: BoxDecoration(
                color: colors.white,
                borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                children: [
                  Image.memory(
                    base64Decode(viewModel.managedWhatsAppQrCodeBase64),
                    width: 220,
                    height: 220,
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  Text(
                    'Abra o WhatsApp no celular, vá em aparelhos conectados e escaneie este código.',
                    textAlign: TextAlign.center,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DSSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: DSSpacing.sm,
            runSpacing: DSSpacing.sm,
            children: [
              DSButton.secondary(
                label: 'Atualizar status',
                icon: Icons.refresh_rounded,
                isLoading: viewModel.isRefreshingManagedWhatsApp,
                onTap: () => presenter.refreshManagedWhatsAppStatus(
                  includeQrCode: !viewModel.isWhatsAppConnected,
                ),
              ),
              if (viewModel.hasManagedWhatsAppSetup)
                DSButton.danger(
                  label: 'Desconectar numero',
                  icon: Icons.link_off_rounded,
                  isLoading: viewModel.isDisconnectingManagedWhatsApp,
                  onTap:
                      viewModel.isProvisioningManagedWhatsApp ||
                          viewModel.isRefreshingManagedWhatsApp
                      ? null
                      : _confirmDisconnectManagedWhatsApp,
                ),
              DSButton.accent(
                label: viewModel.hasManagedWhatsAppSetup
                    ? 'Gerar QR novamente'
                    : 'Conectar número',
                icon: Icons.qr_code_rounded,
                isLoading: viewModel.isProvisioningManagedWhatsApp,
                onTap: viewModel.isDisconnectingManagedWhatsApp
                    ? null
                    : presenter.provisionManagedWhatsApp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(
    DSColors colors,
    DSTextStyle textStyles, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: DSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textTertiary),
          const SizedBox(width: DSSpacing.xs),
          Text(
            '$label: ',
            style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
          ),
          Text(
            value,
            style: textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(DSColors colors) {
    final status = viewModel.whatsappConnectionStatus.toLowerCase();
    if (status.contains('conectado')) return colors.green;
    if (status.contains('qr') || status.contains('preparando')) {
      return colors.yellow;
    }
    if (status.contains('erro')) return colors.red;
    return colors.textSecondary;
  }

  Widget _buildAdvancedWhatsAppForm(DSColors colors, DSTextStyle textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Modo avançado para operação manual ou contingência.',
          style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.md),

        // URL
        FormTextField(
          label: 'URL da Evolution API',
          controller: presenter.evolutionUrlController,
          keyboardType: TextInputType.url,
          prefixIcon: Icons.link,
          hintText: 'https://api.evolution.com',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: DSSpacing.md),

        // API Key
        FormTextField(
          label: 'API Key',
          controller: presenter.apiKeyController,
          obscureText: !_showApiKey,
          prefixIcon: Icons.key_outlined,
          hintText: 'Sua chave de API',
          textInputAction: TextInputAction.next,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _showApiKey ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: colors.textTertiary,
                ),
                onPressed: () {
                  setState(() => _showApiKey = !_showApiKey);
                },
                tooltip: _showApiKey ? 'Ocultar' : 'Mostrar',
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 20, color: colors.textTertiary),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: presenter.apiKeyController.text),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API Key copiada!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: 'Copiar',
              ),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.md),

        // Instance Name
        FormTextField(
          label: 'Instance Name',
          controller: presenter.instanceNameController,
          prefixIcon: Icons.devices_outlined,
          hintText: 'nome-da-instancia',
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: DSSpacing.lg),

        // Botões
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DSButton.secondary(
              label: 'Testar Conexão',
              icon: Icons.wifi_tethering,
              isLoading: viewModel.isTestingConnection,
              onTap: presenter.testWhatsAppConnection,
            ),
            const SizedBox(width: DSSpacing.sm),
            DSButton.primary(
              label: 'Salvar',
              icon: Icons.save_rounded,
              isLoading: viewModel.isSavingWhatsApp,
              onTap: presenter.saveWhatsAppConfig,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebhookSection(DSColors colors, DSTextStyle textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-header
        Row(
          children: [
            Icon(Icons.webhook_outlined, size: 18, color: colors.blue),
            const SizedBox(width: DSSpacing.xs),
            Text(
              'n8n Automation',
              style: textStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.sm,
                vertical: DSSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: viewModel.webhookToken.isNotEmpty
                    ? colors.green.withValues(alpha: 0.1)
                    : colors.greyLighter.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: viewModel.webhookToken.isNotEmpty
                        ? colors.green
                        : colors.grey,
                  ),
                  const SizedBox(width: DSSpacing.xxs),
                  Text(
                    viewModel.webhookToken.isNotEmpty
                        ? 'Ativo'
                        : 'Não configurado',
                    style: textStyles.bodySmall.copyWith(
                      color: viewModel.webhookToken.isNotEmpty
                          ? colors.green
                          : colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),

        // Webhook URL (read-only)
        Text(
          'Webhook URL',
          style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: colors.greyLightest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            border: Border.all(color: colors.inputBorder),
          ),
          child: SelectableText(
            viewModel.webhookUrl.isNotEmpty
                ? viewModel.webhookUrl
                : 'Nenhum webhook gerado. Clique em "Gerar URL" abaixo.',
            style: textStyles.bodySmall.copyWith(
              fontFamily: 'monospace',
              color: viewModel.webhookUrl.isNotEmpty
                  ? colors.textPrimary
                  : colors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: DSSpacing.sm),

        // Info
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: colors.textTertiary),
            const SizedBox(width: DSSpacing.xxs),
            Expanded(
              child: Text(
                'Use esta URL no seu workflow n8n para enviar vendas automaticamente.',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),

        // Botões
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (viewModel.webhookUrl.isEmpty)
              DSButton.secondary(
                label: 'Gerar URL',
                icon: Icons.add_link,
                onTap: () => presenter.generateWebhookUrl(),
              ),
            if (viewModel.webhookUrl.isNotEmpty) ...[
              DSButton.secondary(
                label: 'Copiar URL',
                icon: Icons.copy,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: viewModel.webhookUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Webhook URL copiada!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
