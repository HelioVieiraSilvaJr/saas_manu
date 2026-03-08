import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../TenantsListPresenter.dart';
import '../TenantsListViewModel.dart';
import '../Widgets/TenantListItem.dart';

/// Lista de Tenants - Layout Mobile (< 1000px).
class TenantsListMobileView extends StatelessWidget {
  final TenantsListPresenter presenter;
  final TenantsListViewModel viewModel;
  final TextEditingController searchController;
  final void Function(String tenantId) onTapTenant;
  final void Function(String tenantId) onEditTenant;
  final void Function(String tenantId) onDeleteTenant;
  final VoidCallback onCreateTenant;

  const TenantsListMobileView({
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

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: presenter.loadTenants,
        color: colors.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(DSSpacing.md),
                child: _buildSearch(colors, textStyles),
              ),
            ),

            // Filtros horizontais
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
                child: _buildFilterChips(colors, textStyles),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.sm)),

            // Content
            _buildContent(colors),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateTenant,
        backgroundColor: colors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearch(DSColors colors, DSTextStyle textStyles) {
    return TextField(
      controller: searchController,
      onChanged: presenter.search,
      decoration: InputDecoration(
        hintText: 'Buscar tenants...',
        hintStyle: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
        prefixIcon: Icon(Icons.search_rounded, color: colors.textTertiary),
        suffixIcon: viewModel.hasSearch
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  presenter.search('');
                },
                icon: Icon(Icons.close_rounded, color: colors.textTertiary),
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
    );
  }

  Widget _buildFilterChips(DSColors colors, DSTextStyle textStyles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Plano
          _buildCompactDropdown<TenantPlanFilter>(
            value: viewModel.planFilter,
            items: {for (var f in TenantPlanFilter.values) f: f.label},
            onChanged: (v) =>
                presenter.setPlanFilter(v ?? TenantPlanFilter.all),
            colors: colors,
          ),
          const SizedBox(width: DSSpacing.xs),

          // Status
          _buildCompactDropdown<TenantStatusFilter>(
            value: viewModel.statusFilter,
            items: {for (var f in TenantStatusFilter.values) f: f.label},
            onChanged: (v) =>
                presenter.setStatusFilter(v ?? TenantStatusFilter.all),
            colors: colors,
          ),
          const SizedBox(width: DSSpacing.xs),

          // Situação
          _buildCompactDropdown<TenantSituationFilter>(
            value: viewModel.situationFilter,
            items: {for (var f in TenantSituationFilter.values) f: f.label},
            onChanged: (v) =>
                presenter.setSituationFilter(v ?? TenantSituationFilter.all),
            colors: colors,
          ),
          const SizedBox(width: DSSpacing.xs),

          // Ordenação
          _buildCompactDropdown<TenantSortOption>(
            value: viewModel.sortOption,
            items: {for (var s in TenantSortOption.values) s: s.label},
            onChanged: (v) =>
                presenter.setSortOption(v ?? TenantSortOption.newestFirst),
            colors: colors,
          ),

          // Limpar filtros
          if (viewModel.hasActiveFilters) ...[
            const SizedBox(width: DSSpacing.xs),
            ActionChip(
              label: const Icon(Icons.filter_alt_off_rounded, size: 16),
              onPressed: () {
                searchController.clear();
                presenter.clearFilters();
              },
              backgroundColor: colors.red.withValues(alpha: 0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    required DSColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xs),
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: colors.inputBorder),
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
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
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: colors.cardBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: colors.textTertiary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DSColors colors) {
    if (viewModel.isLoading) {
      return const SliverFillRemaining(
        child: LoadingIndicator(message: 'Carregando tenants...'),
      );
    }

    if (viewModel.filteredTenants.isEmpty) {
      if (viewModel.hasSearch || viewModel.hasActiveFilters) {
        return SliverFillRemaining(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Nenhum tenant encontrado',
            message: 'Tente alterar os filtros ou a busca.',
            actionLabel: 'Limpar filtros',
            onAction: () {
              searchController.clear();
              presenter.clearFilters();
            },
          ),
        );
      }

      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.business_outlined,
          title: 'Nenhum tenant cadastrado',
          message: 'Toque + para criar o primeiro tenant.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final tenant = viewModel.filteredTenants[index];
        return TenantListItem(
          tenant: tenant,
          onTap: () => onTapTenant(tenant.uid),
          onEdit: () => onEditTenant(tenant.uid),
          onDelete: () => onDeleteTenant(tenant.uid),
        );
      }, childCount: viewModel.filteredTenants.length),
    );
  }
}
