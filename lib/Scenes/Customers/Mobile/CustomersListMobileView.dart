import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../CustomersListPresenter.dart';
import '../CustomersListViewModel.dart';
import '../CustomersCoordinator.dart';
import '../Widgets/CustomerListItem.dart';

/// Lista de Clientes - Layout Mobile (< 1000px).
///
/// Cards com busca, filtros, FAB para novo cliente.
class CustomersListMobileView extends StatelessWidget {
  final CustomersListPresenter presenter;
  final CustomersListViewModel viewModel;
  final TextEditingController searchController;

  const CustomersListMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Stack(
      children: [
        Column(
          children: [
            // Busca e filtros
            _buildSearchAndFilters(colors, textStyles),

            // Contagem
            if (!viewModel.isLoading) _buildCountBar(colors, textStyles),

            // Content
            Expanded(child: _buildContent(context, colors)),
          ],
        ),

        // FAB
        Positioned(
          right: DSSpacing.lg,
          bottom: DSSpacing.lg,
          child: FloatingActionButton.extended(
            onPressed: () => CustomersCoordinator.navigateToCreate(context),
            backgroundColor: colors.primaryColor,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: const Text(
              'Novo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(DSColors colors, DSTextStyle textStyles) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            controller: searchController,
            onChanged: presenter.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar clientes...',
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
              isDense: true,
            ),
          ),
          const SizedBox(height: DSSpacing.sm),

          // Filtros inline
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown<CustomerStatusFilter>(
                  value: viewModel.statusFilter,
                  items: const {
                    CustomerStatusFilter.all: 'Status',
                    CustomerStatusFilter.active: 'Ativos',
                    CustomerStatusFilter.inactive: 'Inativos',
                  },
                  onChanged: (v) =>
                      presenter.setStatusFilter(v ?? CustomerStatusFilter.all),
                  colors: colors,
                ),
              ),
              const SizedBox(width: DSSpacing.xs),
              Expanded(
                child: _buildCompactDropdown<CustomerPurchasePeriod>(
                  value: viewModel.purchasePeriod,
                  items: const {
                    CustomerPurchasePeriod.all: 'Período',
                    CustomerPurchasePeriod.last7Days: '7 dias',
                    CustomerPurchasePeriod.last30Days: '30 dias',
                    CustomerPurchasePeriod.last90Days: '90 dias',
                  },
                  onChanged: (v) => presenter.setPurchasePeriod(
                    v ?? CustomerPurchasePeriod.all,
                  ),
                  colors: colors,
                ),
              ),
              const SizedBox(width: DSSpacing.xs),
              Expanded(
                child: _buildCompactDropdown<CustomerSortOption>(
                  value: viewModel.sortOption,
                  items: const {
                    CustomerSortOption.newestFirst: 'Recentes',
                    CustomerSortOption.oldestFirst: 'Antigos',
                    CustomerSortOption.nameAZ: 'A–Z',
                    CustomerSortOption.nameZA: 'Z–A',
                    CustomerSortOption.lastPurchaseRecent: 'Ult. Compra',
                    CustomerSortOption.totalSpentHigh: 'Maior R\$',
                    CustomerSortOption.totalSpentLow: 'Menor R\$',
                  },
                  onChanged: (v) => presenter.setSortOption(
                    v ?? CustomerSortOption.newestFirst,
                  ),
                  colors: colors,
                ),
              ),
              if (viewModel.hasActiveFilters) ...[
                const SizedBox(width: DSSpacing.xs),
                GestureDetector(
                  onTap: () {
                    searchController.clear();
                    presenter.clearFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(DSSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.filter_alt_off_rounded,
                      color: colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
      decoration: BoxDecoration(
        border: Border.all(color: colors.inputBorder),
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        color: colors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: TextStyle(fontSize: 12, color: colors.textPrimary),
          dropdownColor: colors.cardBackground,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: colors.textTertiary,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCountBar(DSColors colors, DSTextStyle textStyles) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${viewModel.filteredCount} de ${viewModel.totalCount} cliente${viewModel.totalCount != 1 ? 's' : ''}',
            style: textStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DSColors colors) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando clientes...');
    }

    if (viewModel.allCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Nenhum cliente cadastrado',
        message: 'Toque no botão + para adicionar.',
      );
    }

    if (viewModel.filteredCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nenhum cliente encontrado',
        message: viewModel.hasSearch
            ? 'Sem resultados para "${viewModel.searchQuery}".'
            : 'Altere os filtros aplicados.',
        actionLabel: 'Limpar Filtros',
        onAction: () {
          searchController.clear();
          presenter.clearFilters();
        },
      );
    }

    // Lista de cards
    return RefreshIndicator(
      onRefresh: presenter.refresh,
      color: colors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(DSSpacing.md, 0, DSSpacing.md, 80),
        itemCount: viewModel.filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = viewModel.filteredCustomers[index];
          return CustomerListItem(
            customer: customer,
            isWeb: false,
            onTap: () =>
                CustomersCoordinator.navigateToDetail(context, customer),
            onEdit: () =>
                CustomersCoordinator.navigateToEdit(context, customer),
            onDelete: () => presenter.deleteCustomer(customer),
          );
        },
      ),
    );
  }
}
