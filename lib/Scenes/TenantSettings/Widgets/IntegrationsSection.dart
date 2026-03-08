import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../TenantSettingsPresenter.dart';
import '../TenantSettingsViewModel.dart';

/// Widget da seção "Integrações" (WhatsApp + n8n Webhook) — Módulo 8.
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

  TenantSettingsPresenter get presenter => widget.presenter;
  TenantSettingsViewModel get viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
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
          const SizedBox(height: DSSpacing.xl),

          // n8n Webhook Section
          _buildWebhookSection(colors, textStyles),
        ],
      ),
    );
  }

  Widget _buildWhatsAppSection(DSColors colors, DSTextStyle textStyles) {
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
