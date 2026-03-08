import '../../Commons/Models/MembershipModel.dart';

/// ViewModel para Gerenciar Equipe — Módulo 9.
class TeamManagementViewModel {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<MembershipModel> members;
  final String searchQuery;

  const TeamManagementViewModel({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.members = const [],
    this.searchQuery = '',
  });

  TeamManagementViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<MembershipModel>? members,
    String? searchQuery,
  }) {
    return TeamManagementViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      members: members ?? this.members,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Helpers

  List<MembershipModel> get filteredMembers {
    if (searchQuery.isEmpty) return members;
    final q = searchQuery.toLowerCase();
    return members.where((m) {
      final name = (m.userName ?? '').toLowerCase();
      final email = (m.userEmail ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  int get activeCount => members.where((m) => m.isActive).length;

  int get totalCount => members.length;
}
