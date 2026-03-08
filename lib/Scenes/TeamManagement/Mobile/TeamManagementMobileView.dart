import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../TeamManagementPresenter.dart';
import '../TeamManagementViewModel.dart';
import '../Widgets/MemberListItem.dart';

/// Gerenciar Equipe — Layout Mobile (< 1000px).
class TeamManagementMobileView extends StatelessWidget {
  final TeamManagementPresenter presenter;
  final TeamManagementViewModel viewModel;

  const TeamManagementMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando equipe...');
    }

    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => presenter.navigateToAddMember(context),
        backgroundColor: colors.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.base,
              DSSpacing.base,
              DSSpacing.base,
              DSSpacing.sm,
            ),
            child: Text(
              'Equipe (${viewModel.activeCount})',
              style: textStyles.headline2,
            ),
          ),

          // Busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
            child: TextField(
              onChanged: presenter.onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                  borderSide: BorderSide(color: colors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.sm),

          // Lista
          Expanded(
            child: viewModel.filteredMembers.isEmpty
                ? EmptyState(
                    icon: Icons.group_outlined,
                    title: viewModel.searchQuery.isNotEmpty
                        ? 'Nenhum membro encontrado'
                        : 'Apenas você na equipe',
                    message: viewModel.searchQuery.isNotEmpty
                        ? 'Tente outro termo de busca.'
                        : 'Adicione membros para colaborar!',
                    actionLabel: viewModel.searchQuery.isEmpty
                        ? 'Adicionar Membro'
                        : null,
                    onAction: viewModel.searchQuery.isEmpty
                        ? () => presenter.navigateToAddMember(context)
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                    ),
                    itemCount: viewModel.filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = viewModel.filteredMembers[index];
                      return MemberListItem(
                        member: member,
                        onEdit: () => presenter.editMember(context, member),
                        onRemove: () => presenter.removeMember(context, member),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
