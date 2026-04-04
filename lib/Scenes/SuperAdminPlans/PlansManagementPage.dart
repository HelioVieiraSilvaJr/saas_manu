import 'package:flutter/material.dart';
import '../../Commons/Models/PlanCatalogModel.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'PlanCatalogRepository.dart';

class PlansManagementPage extends StatefulWidget {
  const PlansManagementPage({super.key});

  @override
  State<PlansManagementPage> createState() => _PlansManagementPageState();
}

class _PlansManagementPageState extends State<PlansManagementPage> {
  final _repository = PlanCatalogRepository();
  bool _isSeedingDefaults = false;

  @override
  void initState() {
    super.initState();
    _ensureDefaults();
  }

  Future<void> _ensureDefaults() async {
    setState(() => _isSeedingDefaults = true);
    await _repository.ensureDefaults();
    if (mounted) {
      setState(() => _isSeedingDefaults = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return AppShell(
      currentRoute: '/admin/plans',
      child: StreamBuilder<List<PlanCatalogModel>>(
        stream: _repository.watchAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData && _isSeedingDefaults) {
            return const LoadingIndicator(message: 'Carregando planos...');
          }

          final plans = snapshot.data ?? PlanCatalogModel.defaults;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.pagePaddingHorizontalWeb,
              vertical: DSSpacing.pagePaddingVerticalWeb,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Planos & Billing', style: textStyles.headline1),
                          const SizedBox(height: DSSpacing.xs),
                          Text(
                            'Defina preços, duração e limites para novas assinaturas. Renovação de clientes antigos continua usando o valor contratado no tenant.',
                            style: textStyles.bodyMedium.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DSButton.secondary(
                      label: 'Restaurar padrões',
                      icon: Icons.restart_alt_rounded,
                      isLoading: _isSeedingDefaults,
                      onTap: _isSeedingDefaults ? null : _ensureDefaults,
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.xl),
                Wrap(
                  spacing: DSSpacing.lg,
                  runSpacing: DSSpacing.lg,
                  children: plans.map((plan) {
                    return SizedBox(
                      width: 360,
                      child: _buildPlanCard(plan, colors, textStyles),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(
    PlanCatalogModel plan,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
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
          Row(
            children: [
              Expanded(
                child: Text(plan.displayName, style: textStyles.headline3),
              ),
              DSBadge(
                label: plan.isActive ? 'Ativo' : 'Inativo',
                type: plan.isActive ? DSBadgeType.success : DSBadgeType.warning,
                size: DSBadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xs),
          Text(
            plan.description,
            style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: DSSpacing.lg),
          Text(
            'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
            style: textStyles.headline1.copyWith(color: colors.primaryColor),
          ),
          Text(
            '${plan.durationDays} dias por ciclo',
            style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: DSSpacing.md),
          _buildInfoLine(
            'Clientes',
            _formatLimit(plan.customerLimit),
            textStyles,
          ),
          _buildInfoLine(
            'Produtos',
            _formatLimit(plan.productLimit),
            textStyles,
          ),
          _buildInfoLine('ID técnico', plan.id, textStyles),
          const SizedBox(height: DSSpacing.md),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.xxs),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 16, color: colors.green),
                  const SizedBox(width: DSSpacing.xs),
                  Expanded(child: Text(feature, style: textStyles.bodySmall)),
                ],
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.lg),
          DSButton.secondary(
            label: 'Editar plano',
            icon: Icons.edit_outlined,
            onTap: () => _showEditDialog(plan),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value, DSTextStyle textStyles) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.xxs),
      child: RichText(
        text: TextSpan(
          style: textStyles.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: textStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _formatLimit(int value) => value == 0 ? 'Ilimitado' : '$value';

  Future<void> _showEditDialog(PlanCatalogModel plan) async {
    final colors = DSColors();
    final nameController = TextEditingController(text: plan.name);
    final descriptionController = TextEditingController(text: plan.description);
    final priceController = TextEditingController(
      text: plan.price.toStringAsFixed(2).replaceAll('.', ','),
    );
    final customersController = TextEditingController(
      text: plan.customerLimit.toString(),
    );
    final productsController = TextEditingController(
      text: plan.productLimit.toString(),
    );
    final durationController = TextEditingController(
      text: plan.durationDays.toString(),
    );
    final featuresController = TextEditingController(
      text: plan.features.join('\n'),
    );
    var isActive = plan.isActive;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar ${plan.displayName}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: DSSpacing.md),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: DSSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Preço'),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: durationController,
                          decoration: const InputDecoration(
                            labelText: 'Dias do ciclo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: customersController,
                          decoration: const InputDecoration(
                            labelText: 'Limite de clientes',
                          ),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: productsController,
                          decoration: const InputDecoration(
                            labelText: 'Limite de produtos',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.md),
                  TextFormField(
                    controller: featuresController,
                    decoration: const InputDecoration(
                      labelText: 'Recursos (1 por linha)',
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 4,
                    maxLines: 6,
                  ),
                  const SizedBox(height: DSSpacing.md),
                  StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Plano ativo'),
                        activeThumbColor: colors.green,
                        value: isActive,
                        onChanged: (value) {
                          setStateDialog(() => isActive = value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            DSButton.text(
              label: 'Cancelar',
              onTap: () => Navigator.of(context).pop(),
            ),
            DSButton.primary(
              label: 'Salvar',
              icon: Icons.save_rounded,
              onTap: () async {
                final navigator = Navigator.of(context);
                final updated = plan.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  price:
                      double.tryParse(
                        priceController.text.trim().replaceAll(',', '.'),
                      ) ??
                      plan.price,
                  customerLimit:
                      int.tryParse(customersController.text.trim()) ??
                      plan.customerLimit,
                  productLimit:
                      int.tryParse(productsController.text.trim()) ??
                      plan.productLimit,
                  durationDays:
                      int.tryParse(durationController.text.trim()) ??
                      plan.durationDays,
                  isActive: isActive,
                  features: featuresController.text
                      .split('\n')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                );
                await _repository.save(updated);
                if (!mounted) return;
                navigator.pop();
              },
            ),
          ],
        );
      },
    );
  }
}
