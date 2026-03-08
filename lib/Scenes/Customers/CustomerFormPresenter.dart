import 'package:flutter/material.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import 'CustomersRepository.dart';
import 'CustomerFormViewModel.dart';

/// Presenter do formulário de cliente (criar/editar).
class CustomerFormPresenter {
  final CustomersRepository _repository = CustomersRepository();
  final ValueChanged<CustomerFormViewModel> onViewModelUpdated;

  CustomerFormViewModel _viewModel = const CustomerFormViewModel();
  CustomerFormViewModel get viewModel => _viewModel;

  BuildContext? context;

  CustomerFormPresenter({required this.onViewModelUpdated});

  // MARK: - Init

  /// Inicializa para criar novo cliente.
  void initForCreate() {
    _update(
      _viewModel.copyWith(customer: CustomerModel.newModel(), isEditing: false),
    );
  }

  /// Inicializa para editar cliente existente.
  Future<void> initForEdit(String customerId) async {
    _update(_viewModel.copyWith(isLoading: true, isEditing: true));

    final customer = await _repository.getById(customerId);
    if (customer != null) {
      _update(_viewModel.copyWith(isLoading: false, customer: customer));
    } else {
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Cliente não encontrado.',
          clearError: false,
        ),
      );
    }
  }

  // MARK: - Validate WhatsApp

  /// Verifica se o WhatsApp é único no tenant.
  Future<bool> validateWhatsapp(String whatsapp) async {
    return await _repository.whatsappExists(
      whatsapp,
      excludeId: _viewModel.isEditing ? _viewModel.customer?.uid : null,
    );
  }

  // MARK: - Save

  /// Salva o cliente (criar ou atualizar).
  Future<bool> save({
    required String name,
    required String whatsapp,
    String? email,
    String? notes,
  }) async {
    if (context == null) return false;

    _update(_viewModel.copyWith(isSaving: true));

    try {
      // Validar WhatsApp único
      final exists = await _repository.whatsappExists(
        whatsapp,
        excludeId: _viewModel.isEditing ? _viewModel.customer?.uid : null,
      );

      if (exists) {
        _update(
          _viewModel.copyWith(
            isSaving: false,
            errorMessage: 'Este WhatsApp já está cadastrado.',
            clearError: false,
          ),
        );
        return false;
      }

      if (_viewModel.isEditing) {
        // EDITAR
        final customer = _viewModel.customer!.copyWith(
          name: name,
          whatsapp: whatsapp,
          email: email,
          notes: notes,
          updatedAt: DateTime.now(),
        );

        final success = await _repository.update(customer);

        if (success) {
          _update(_viewModel.copyWith(isSaving: false));
          return true;
        } else {
          _update(
            _viewModel.copyWith(
              isSaving: false,
              errorMessage: 'Erro ao atualizar cliente.',
              clearError: false,
            ),
          );
          return false;
        }
      } else {
        // CRIAR
        final customer = CustomerModel(
          uid: '',
          name: name,
          whatsapp: whatsapp,
          email: email,
          notes: notes,
          isActive: true,
          createdAt: DateTime.now(),
        );

        final customerId = await _repository.create(customer);

        if (customerId != null) {
          _update(_viewModel.copyWith(isSaving: false));
          return true;
        } else {
          _update(
            _viewModel.copyWith(
              isSaving: false,
              errorMessage: 'Erro ao criar cliente.',
              clearError: false,
            ),
          );
          return false;
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar cliente', error: e);
      _update(
        _viewModel.copyWith(
          isSaving: false,
          errorMessage: 'Erro inesperado ao salvar cliente.',
          clearError: false,
        ),
      );
      return false;
    }
  }

  // MARK: - Private

  void _update(CustomerFormViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }
}
