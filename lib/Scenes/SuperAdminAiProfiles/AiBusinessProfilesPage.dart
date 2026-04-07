import 'package:flutter/material.dart';
import '../../Commons/Enums/BusinessSegment.dart';
import '../../Commons/Models/AiBusinessProfileModel.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'AiBusinessProfileRepository.dart';

class AiBusinessProfilesPage extends StatefulWidget {
  const AiBusinessProfilesPage({super.key});

  @override
  State<AiBusinessProfilesPage> createState() => _AiBusinessProfilesPageState();
}

class _AiBusinessProfilesPageState extends State<AiBusinessProfilesPage> {
  final _repository = AiBusinessProfileRepository();
  final _recommendationsController = TextEditingController();
  final _examplesController = TextEditingController();

  BusinessSegment _selectedSegment = BusinessSegment.fashion;
  String? _boundProfileId;
  bool _isSeedingDefaults = false;
  bool _isSaving = false;
  bool _isRestoringCurrent = false;
  bool _isRestoringAll = false;
  bool _hasUnsavedChanges = false;
  bool _isSyncingControllers = false;

  @override
  void initState() {
    super.initState();
    _recommendationsController.addListener(_handleControllerChange);
    _examplesController.addListener(_handleControllerChange);
    _ensureDefaults();
  }

  @override
  void dispose() {
    _recommendationsController.dispose();
    _examplesController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (_isSyncingControllers || _hasUnsavedChanges || !mounted) return;
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _ensureDefaults() async {
    setState(() => _isSeedingDefaults = true);
    await _repository.ensureDefaults();
    if (mounted) {
      setState(() => _isSeedingDefaults = false);
    }
  }

  void _bindProfile(AiBusinessProfileModel profile, {bool force = false}) {
    if (!force && _boundProfileId == profile.id && _hasUnsavedChanges) return;
    if (!force &&
        _boundProfileId == profile.id &&
        _recommendationsController.text == profile.recommendations &&
        _examplesController.text == profile.exampleConversations) {
      return;
    }

    _isSyncingControllers = true;
    _boundProfileId = profile.id;
    _recommendationsController.text = profile.recommendations;
    _examplesController.text = profile.exampleConversations;
    _hasUnsavedChanges = false;
    _isSyncingControllers = false;
  }

  Future<void> _saveCurrentProfile(AiBusinessProfileModel baseProfile) async {
    setState(() => _isSaving = true);
    final updatedProfile = baseProfile.copyWith(
      recommendations: _recommendationsController.text.trim(),
      exampleConversations: _examplesController.text.trim(),
    );

    await _repository.save(updatedProfile);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil de IA para ${updatedProfile.segmentLabel} salvo com sucesso.',
        ),
      ),
    );
  }

  Future<void> _restoreCurrent(BusinessSegment segment) async {
    setState(() => _isRestoringCurrent = true);
    await _repository.restoreDefault(segment);
    if (!mounted) return;
    setState(() {
      _isRestoringCurrent = false;
      _hasUnsavedChanges = false;
    });
    final defaultProfile = AiBusinessProfileModel.defaultForSegment(segment);
    _bindProfile(defaultProfile, force: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Padrao restaurado para ${defaultProfile.segmentLabel}.'),
      ),
    );
  }

  Future<void> _restoreAll() async {
    setState(() => _isRestoringAll = true);
    for (final segment in BusinessSegment.values) {
      await _repository.restoreDefault(segment);
    }
    if (!mounted) return;
    setState(() {
      _isRestoringAll = false;
      _hasUnsavedChanges = false;
    });
    _bindProfile(
      AiBusinessProfileModel.defaultForSegment(_selectedSegment),
      force: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfis globais de IA restaurados para o padrao.'),
      ),
    );
  }

  Future<void> _selectSegment(BusinessSegment segment) async {
    if (segment == _selectedSegment) return;
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar alteracoes?'),
          content: const Text(
            'Voce tem alteracoes nao salvas nesse segmento. Deseja descartar para trocar de tipo de negocio?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (shouldDiscard != true) return;
    }

    setState(() {
      _selectedSegment = segment;
      _hasUnsavedChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return AppShell(
      currentRoute: '/admin/ai-profiles',
      child: StreamBuilder<List<AiBusinessProfileModel>>(
        stream: _repository.watchAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData && _isSeedingDefaults) {
            return const LoadingIndicator(
              message: 'Carregando perfis globais de IA...',
            );
          }

          final profiles = snapshot.data ?? AiBusinessProfileModel.defaults;
          final currentProfile = profiles.firstWhere(
            (profile) => profile.segment == _selectedSegment,
            orElse: () =>
                AiBusinessProfileModel.defaultForSegment(_selectedSegment),
          );

          _bindProfile(currentProfile);

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
                _buildSegmentSelector(colors, textStyles),
                const SizedBox(height: DSSpacing.lg),
                _buildProfileEditor(currentProfile, colors, textStyles),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(DSColors colors, DSTextStyle textStyles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IA por Tipo de Negocio', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Defina recomendacoes globais e exemplos comerciais por segmento. Esse material sera somado ao contexto proprio de cada tenant antes do atendimento no WhatsApp.',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DSSpacing.md),
        DSButton.secondary(
          label: 'Restaurar todos os padroes',
          icon: Icons.restart_alt_rounded,
          isLoading: _isRestoringAll || _isSeedingDefaults,
          onTap: (_isRestoringAll || _isSeedingDefaults) ? null : _restoreAll,
        ),
      ],
    );
  }

  Widget _buildSegmentSelector(DSColors colors, DSTextStyle textStyles) {
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
          Text('Tipos de negocio', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.xs),
          Text(
            'Escolha o segmento que deseja ajustar. Cada perfil vale para todos os tenants desse mesmo tipo.',
            style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: DSSpacing.md),
          Wrap(
            spacing: DSSpacing.sm,
            runSpacing: DSSpacing.sm,
            children: BusinessSegment.values.map((segment) {
              final isSelected = _selectedSegment == segment;
              return ChoiceChip(
                label: Text(segment.label),
                selected: isSelected,
                onSelected: (_) => _selectSegment(segment),
                selectedColor: colors.primarySurface,
                labelStyle: textStyles.bodySmall.copyWith(
                  color: isSelected
                      ? colors.primaryColor
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? colors.primaryColor : colors.divider,
                ),
                backgroundColor: colors.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileEditor(
    AiBusinessProfileModel profile,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuracao global: ${profile.segmentLabel}',
                      style: textStyles.headline3,
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      'O agente vai usar essas instrucoes como camada global do segmento e combinar isso com o contexto especifico do tenant, produtos e cliente.',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasUnsavedChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.sm,
                    vertical: DSSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DSSpacing.radiusFull),
                  ),
                  child: Text(
                    'Alteracoes nao salvas',
                    style: textStyles.bodySmall.copyWith(
                      color: colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),
          FormTextField(
            label: 'Recomendacoes para o agente',
            controller: _recommendationsController,
            maxLines: 14,
            textInputAction: TextInputAction.newline,
            hintText:
                'Escreva orientacoes comerciais globais para esse segmento.',
            helperText:
                'Ex.: abordagem ideal, objecoes comuns, tecnicas de conversao, pontos de atencao e cross-sell.',
          ),
          const SizedBox(height: DSSpacing.lg),
          FormTextField(
            label: 'Exemplos de atendimento que convertem',
            controller: _examplesController,
            maxLines: 18,
            textInputAction: TextInputAction.newline,
            hintText:
                'Inclua roteiros, respostas-modelo e exemplos de abordagem.',
            helperText:
                'Esses exemplos ajudam o agente a internalizar estilo comercial, ritmo e direcionamento de fechamento.',
          ),
          const SizedBox(height: DSSpacing.lg),
          Wrap(
            spacing: DSSpacing.md,
            runSpacing: DSSpacing.md,
            children: [
              DSButton.primary(
                label: 'Salvar configuracao',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onTap: _isSaving ? null : () => _saveCurrentProfile(profile),
              ),
              DSButton.secondary(
                label: 'Restaurar padrao deste segmento',
                icon: Icons.history_rounded,
                isLoading: _isRestoringCurrent,
                onTap: _isRestoringCurrent
                    ? null
                    : () => _restoreCurrent(profile.segment),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
