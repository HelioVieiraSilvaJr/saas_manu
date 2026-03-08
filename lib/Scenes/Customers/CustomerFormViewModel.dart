import '../../Commons/Models/CustomerModel.dart';

/// Estado do formulário de cliente.
class CustomerFormViewModel {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final CustomerModel? customer;
  final bool isEditing;

  const CustomerFormViewModel({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.customer,
    this.isEditing = false,
  });

  CustomerFormViewModel copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    CustomerModel? customer,
    bool? isEditing,
    bool clearError = true,
    bool clearSuccess = true,
  }) {
    return CustomerFormViewModel(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? successMessage
          : (successMessage ?? this.successMessage),
      customer: customer ?? this.customer,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}
