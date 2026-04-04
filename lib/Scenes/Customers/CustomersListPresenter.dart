import 'dart:async';
import 'package:flutter/material.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import 'CustomersRepository.dart';
import 'CustomersListViewModel.dart';

/// Presenter da listagem de clientes (MVP).
class CustomersListPresenter {
  final CustomersRepository _repository = CustomersRepository();
  final ValueChanged<CustomersListViewModel> onViewModelUpdated;

  CustomersListViewModel _viewModel = const CustomersListViewModel();
  CustomersListViewModel get viewModel => _viewModel;

  BuildContext? context;
  Timer? _debounceTimer;
  StreamSubscription<List<CustomerModel>>? _customersSubscription;

  CustomersListPresenter({required this.onViewModelUpdated});

  // MARK: - Load

  /// Carrega clientes. Usa cache se disponível.
  Future<void> loadCustomers({bool forceRefresh = false}) async {
    // Se cache está fresco, usa sem loading
    if (!forceRefresh && CustomersRepository.customersCache.isFresh) {
      final customers = CustomersRepository.customersCache.data;
      _update(_viewModel.copyWith(isLoading: false, allCustomers: customers));
      _applyFiltersAndSort();
      return;
    }

    _update(_viewModel.copyWith(isLoading: true));

    try {
      final customers = await _repository.getAll(forceRefresh: forceRefresh);
      _update(_viewModel.copyWith(isLoading: false, allCustomers: customers));
      _applyFiltersAndSort();
      AppLogger.info('Clientes carregados: ${customers.length}');
    } catch (e) {
      AppLogger.error('Erro ao carregar clientes', error: e);
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar clientes.',
          clearError: false,
        ),
      );
    }
  }

  /// Recarregar clientes (forçando refresh do Firestore).
  Future<void> refresh() async {
    await loadCustomers(forceRefresh: true);
  }

  void watchCustomers() {
    _customersSubscription?.cancel();
    _customersSubscription = _repository.watchAll().listen((customers) {
      _update(_viewModel.copyWith(isLoading: false, allCustomers: customers));
      _applyFiltersAndSort();
    });
  }

  // MARK: - Search

  /// Atualiza a busca com debounce de 300ms.
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _update(_viewModel.copyWith(searchQuery: query));
      _applyFiltersAndSort();
    });
  }

  /// Limpa a busca.
  void clearSearch() {
    _debounceTimer?.cancel();
    _update(_viewModel.copyWith(searchQuery: ''));
    _applyFiltersAndSort();
  }

  // MARK: - Filters

  /// Altera filtro de status.
  void setStatusFilter(CustomerStatusFilter filter) {
    _update(_viewModel.copyWith(statusFilter: filter));
    _applyFiltersAndSort();
  }

  /// Altera filtro de período.
  void setPurchasePeriod(CustomerPurchasePeriod period) {
    _update(_viewModel.copyWith(purchasePeriod: period));
    _applyFiltersAndSort();
  }

  /// Limpa todos os filtros.
  void clearFilters() {
    _update(
      _viewModel.copyWith(
        statusFilter: CustomerStatusFilter.all,
        purchasePeriod: CustomerPurchasePeriod.all,
        searchQuery: '',
      ),
    );
    _applyFiltersAndSort();
  }

  // MARK: - Sort

  /// Altera a ordenação.
  void setSortOption(CustomerSortOption option) {
    _update(_viewModel.copyWith(sortOption: option));
    _applyFiltersAndSort();
  }

  // MARK: - Delete

  /// Deleta um cliente (soft ou hard delete).
  Future<void> deleteCustomer(CustomerModel customer) async {
    if (context == null) return;

    if (customer.hasPurchases) {
      // Soft delete - inativar
      final confirm = await DSAlertDialog.showWarning(
        context: context!,
        title: 'Cliente com Compras',
        message:
            'Este cliente possui histórico de compras e será inativado (não deletado).',
      );

      if (confirm == true) {
        _update(_viewModel.copyWith(isDeleting: true));
        final success = await _repository.update(
          customer.copyWith(isActive: false),
        );
        _update(_viewModel.copyWith(isDeleting: false));

        if (success) {
          await DSAlertDialog.showSuccess(
            context: context!,
            title: 'Cliente Inativado',
            message: '${customer.name} foi inativado com sucesso.',
          );
          CustomersRepository.customersCache.invalidate();
          await loadCustomers(forceRefresh: true);
        }
      }
    } else {
      // Hard delete
      final confirm = await DSAlertDialog.showDelete(
        context: context!,
        title: 'Confirmar Exclusão',
        message: 'Este cliente será removido permanentemente.',
        content: DSAlertContentCard(
          icon: Icons.person_outline,
          title: customer.name,
          subtitle: customer.whatsapp,
        ),
      );

      if (confirm == true) {
        _update(_viewModel.copyWith(isDeleting: true));
        final success = await _repository.delete(customer.uid);
        _update(_viewModel.copyWith(isDeleting: false));

        if (success) {
          await DSAlertDialog.showSuccess(
            context: context!,
            title: 'Cliente Excluído',
            message: '${customer.name} foi removido permanentemente.',
          );
          CustomersRepository.customersCache.invalidate();
          await loadCustomers(forceRefresh: true);
        }
      }
    }
  }

  // MARK: - Dispose

  void dispose() {
    _debounceTimer?.cancel();
    _customersSubscription?.cancel();
  }

  // MARK: - Private

  void _update(CustomersListViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }

  /// Aplica busca, filtros e ordenação sobre allCustomers.
  void _applyFiltersAndSort() {
    var customers = List<CustomerModel>.from(_viewModel.allCustomers);

    // 1. Busca
    if (_viewModel.searchQuery.isNotEmpty) {
      final query = _viewModel.searchQuery.toLowerCase();
      customers = customers.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.whatsapp.contains(query) ||
            (c.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 2. Filtro de status
    switch (_viewModel.statusFilter) {
      case CustomerStatusFilter.active:
        customers = customers.where((c) => c.isActive).toList();
        break;
      case CustomerStatusFilter.inactive:
        customers = customers.where((c) => !c.isActive).toList();
        break;
      case CustomerStatusFilter.all:
        break;
    }

    // 3. Filtro de período última compra
    if (_viewModel.purchasePeriod != CustomerPurchasePeriod.all) {
      final now = DateTime.now();
      late final DateTime threshold;

      switch (_viewModel.purchasePeriod) {
        case CustomerPurchasePeriod.last7Days:
          threshold = now.subtract(const Duration(days: 7));
          break;
        case CustomerPurchasePeriod.last30Days:
          threshold = now.subtract(const Duration(days: 30));
          break;
        case CustomerPurchasePeriod.last90Days:
          threshold = now.subtract(const Duration(days: 90));
          break;
        case CustomerPurchasePeriod.all:
          threshold = DateTime(2000);
          break;
      }

      customers = customers.where((c) {
        if (c.lastPurchaseAt == null) return false;
        return c.lastPurchaseAt!.isAfter(threshold);
      }).toList();
    }

    // 4. Ordenação
    switch (_viewModel.sortOption) {
      case CustomerSortOption.newestFirst:
        customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CustomerSortOption.oldestFirst:
        customers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CustomerSortOption.nameAZ:
        customers.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case CustomerSortOption.nameZA:
        customers.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case CustomerSortOption.lastPurchaseRecent:
        customers.sort((a, b) {
          if (a.lastPurchaseAt == null && b.lastPurchaseAt == null) return 0;
          if (a.lastPurchaseAt == null) return 1;
          if (b.lastPurchaseAt == null) return -1;
          return b.lastPurchaseAt!.compareTo(a.lastPurchaseAt!);
        });
        break;
      case CustomerSortOption.lastPurchaseOld:
        customers.sort((a, b) {
          if (a.lastPurchaseAt == null && b.lastPurchaseAt == null) return 0;
          if (a.lastPurchaseAt == null) return 1;
          if (b.lastPurchaseAt == null) return -1;
          return a.lastPurchaseAt!.compareTo(b.lastPurchaseAt!);
        });
        break;
      case CustomerSortOption.totalSpentHigh:
        customers.sort(
          (a, b) => (b.totalSpent ?? 0).compareTo(a.totalSpent ?? 0),
        );
        break;
      case CustomerSortOption.totalSpentLow:
        customers.sort(
          (a, b) => (a.totalSpent ?? 0).compareTo(b.totalSpent ?? 0),
        );
        break;
    }

    _update(_viewModel.copyWith(filteredCustomers: customers));
  }
}
