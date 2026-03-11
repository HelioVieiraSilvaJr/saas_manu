import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../TenantsListPresenter.dart';
import '../TenantsListViewModel.dart';
import '../Widgets/TenantListItem.dart';

/// Lista de Tenants - Layout Web (>= 1000px).
class TenantsListWebView extends StatelessWidget {
  final TenantsListPresenter presenter;
  final TenantsListViewModel viewModel;
  final TextEditingController searchController;
  final void Function(String tenantId) onTapTenant;
  final void Function(String tenantId) onEditTenant;
  final void Function(String tenantId) onDeleteTenant;
  final VoidCallback onCreateTenant;

  const TenantsListWebView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.searchController,
    required this.onTapTenant,
    required this.onEditTenant,
    required this.onDeleteTenant,
    required this.onCreateTenant,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
        vertical: DSSpacing.pagePaddingVerticalWeb,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          _buildSearchAndFilters(colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          Expanded(child: _buildContent(colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tenants', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xxs),
              Text(
                '${viewModel.totalCount} tenant${viewModel.totalCount != 1 ? 's' : ''} cadastrado${viewModel.totalCount != 1 ? 's' : ''}',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        DSButton.primary(
          label: 'Novo Tenant',
          icon: Icons.add_rounded,
          onTap: onCreateTenant,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        // Campo de busca
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            onChanged: presenter.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, e-mail ou telefone...',
              hintStyle: textStyles.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.textTertiary,
              ),
              suffixIcon: viewModel.hasSearch
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        presenter.search('');
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textTertiary,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                borderSide: BorderSide(color: colors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                borderSide: BorderSide(color: colors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                borderSide: BorderSide(color: colors.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: colors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(width: DSSpacing.md),

        // Filtro Plano
        _buildDropdown<TenantPlanFilter>(
          value: viewModel.planFilter,
          items: {for (var f in TenantPlanFilter.values) f: f.label},
          onChanged: (v) => presenter.setPlanFilter(v ?? TenantPlanFilter.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Filtro Status
        _buildDropdown<TenantStatusFilter>(
          value: viewModel.statusFilter,
          items: {for (var f in TenantStatusFilter.values) f: f.label},
          onChanged: (v) =>
              presenter.setStatusFilter(v ?? TenantStatusFilter.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Filtro Situação
        _buildDropdown<TenantSituationFilter>(
          value: viewModel.situationFilter,
          items: {for (var f in TenantSituationFilter.values) f: f.label},
          onChanged: (v) =>
              presenter.setSituationFilter(v ?? TenantSituationFilter.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Ordenação
        _buildDropdown<TenantSortOption>(
          value: viewModel.sortOption,
          items: {for (var s in TenantSortOption.values) s: s.label},
          onChanged: (v) =>
              presenter.setSortOption(v ?? TenantSortOption.newestFirst),
          colors: colors,
        ),

        // Limpar filtros
        if (viewModel.hasActiveFilters) ...[
          const SizedBox(width: DSSpacing.sm),
          Tooltip(
            message: 'Limpar filtros',
            child: InkWell(
              onTap: () {
                searchController.clear();
                presenter.clearFilters();
              },
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.filter_alt_off_rounded,
                  color: colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    required DSColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: colors.inputBorder),
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        color: colors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: colors.cardBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildContent(DSColors colors) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando tenants...');
    }

    if (viewModel.filteredTenants.isEmpty) {
      if (viewModel.hasSearch || viewModel.hasActiveFilters) {
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Nenhum tenant encontrado',
          message: 'Tente alterar os filtros ou a busca.',
          actionLabel: 'Limpar filtros',
          onAction: () {
            searchController.clear();
            presenter.clearFilters();
          },
        );
      }

      return EmptyState(
        icon: Icons.business_outlined,
        title: 'Nenhum tenant cadastrado',
        message: 'Crie o primeiro tenant para começar.',
        actionLabel: 'Novo Tenant',
        onAction: onCreateTenant,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador de resultados filtrados
        if (viewModel.hasSearch || viewModel.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: DSSpacing.sm),
            child: Text(
              '${viewModel.filteredCount} resultado${viewModel.filteredCount != 1 ? 's' : ''}',
              style: DSTextStyle().bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.filteredTenants.length,
            itemBuilder: (context, index) {
              final tenant = viewModel.filteredTenants[index];
              return TenantListItem(
                tenant: tenant,
                onTap: () => onTapTenant(tenant.uid),
                onEdit: () => onEditTenant(tenant.uid),
                onDelete: () => onDeleteTenant(tenant.uid),
              );
            },
          ),
        ),
      ],
    );
  }
}
