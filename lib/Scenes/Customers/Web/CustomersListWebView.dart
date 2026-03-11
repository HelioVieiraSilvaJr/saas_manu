import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../CustomersListPresenter.dart';
import '../CustomersListViewModel.dart';
import '../CustomersCoordinator.dart';
import '../Widgets/CustomerListItem.dart';

/// Lista de Clientes - Layout Web (>= 1000px).
///
/// Lista compacta com DSListTile, busca, filtros dropdown, ordenação.
class CustomersListWebView extends StatelessWidget {
  final CustomersListPresenter presenter;
  final CustomersListViewModel viewModel;
  final TextEditingController searchController;

  const CustomersListWebView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.searchController,
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
          // Header
          _buildHeader(context, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),

          // Busca e filtros
          _buildSearchAndFilters(colors, textStyles),
          const SizedBox(height: DSSpacing.lg),

          // Content
          Expanded(child: _buildContent(context, colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clientes', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xxs),
              Text(
                '${viewModel.totalCount} cliente${viewModel.totalCount != 1 ? 's' : ''} cadastrado${viewModel.totalCount != 1 ? 's' : ''}',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        DSButton.primary(
          label: 'Novo Cliente',
          icon: Icons.person_add_rounded,
          onTap: () => CustomersCoordinator.navigateToCreate(context),
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
            onChanged: presenter.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, WhatsApp ou email...',
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
                        presenter.clearSearch();
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

        // Filtro Status
        _buildDropdown<CustomerStatusFilter>(
          value: viewModel.statusFilter,
          items: const {
            CustomerStatusFilter.all: 'Todos Status',
            CustomerStatusFilter.active: 'Ativos (compraram)',
            CustomerStatusFilter.inactive: 'Inativos',
          },
          onChanged: (v) =>
              presenter.setStatusFilter(v ?? CustomerStatusFilter.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Filtro Período
        _buildDropdown<CustomerPurchasePeriod>(
          value: viewModel.purchasePeriod,
          items: const {
            CustomerPurchasePeriod.all: 'Período',
            CustomerPurchasePeriod.last7Days: 'Últimos 7 dias',
            CustomerPurchasePeriod.last30Days: 'Últimos 30 dias',
            CustomerPurchasePeriod.last90Days: 'Últimos 90 dias',
          },
          onChanged: (v) =>
              presenter.setPurchasePeriod(v ?? CustomerPurchasePeriod.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Ordenação
        _buildDropdown<CustomerSortOption>(
          value: viewModel.sortOption,
          items: const {
            CustomerSortOption.newestFirst: 'Mais Recentes',
            CustomerSortOption.oldestFirst: 'Mais Antigos',
            CustomerSortOption.nameAZ: 'Nome A–Z',
            CustomerSortOption.nameZA: 'Nome Z–A',
            CustomerSortOption.lastPurchaseRecent: 'Ult. Compra Recente',
            CustomerSortOption.lastPurchaseOld: 'Ult. Compra Antiga',
            CustomerSortOption.totalSpentHigh: 'Maior Gasto',
            CustomerSortOption.totalSpentLow: 'Menor Gasto',
          },
          onChanged: (v) =>
              presenter.setSortOption(v ?? CustomerSortOption.newestFirst),
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
                  size: DSSpacing.iconMd,
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
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          dropdownColor: colors.cardBackground,
          icon: Icon(Icons.arrow_drop_down, color: colors.textTertiary),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DSColors colors) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando clientes...');
    }

    // Nenhum cliente cadastrado
    if (viewModel.allCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Nenhum cliente cadastrado',
        message: 'Comece adicionando seu primeiro cliente.',
        actionLabel: 'Novo Cliente',
        onAction: () => CustomersCoordinator.navigateToCreate(context),
      );
    }

    // Filtros sem resultado
    if (viewModel.filteredCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nenhum cliente encontrado',
        message: viewModel.hasSearch
            ? 'Nenhum resultado para "${viewModel.searchQuery}".'
            : 'Tente alterar os filtros aplicados.',
        actionLabel: 'Limpar Filtros',
        onAction: () {
          searchController.clear();
          presenter.clearFilters();
        },
      );
    }

    // Lista de clientes
    return ListView.builder(
      itemCount: viewModel.filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = viewModel.filteredCustomers[index];
        return CustomerListItem(
          customer: customer,
          isWeb: true,
          onTap: () => CustomersCoordinator.navigateToDetail(context, customer),
          onEdit: () => CustomersCoordinator.navigateToEdit(context, customer),
          onDelete: () => presenter.deleteCustomer(customer),
        );
      },
    );
  }
}
