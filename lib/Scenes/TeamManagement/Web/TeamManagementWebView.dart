import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../TeamManagementPresenter.dart';
import '../TeamManagementViewModel.dart';
import '../Widgets/MemberListItem.dart';

/// Gerenciar Equipe — Layout Web (>= 1000px).
class TeamManagementWebView extends StatelessWidget {
  final TeamManagementPresenter presenter;
  final TeamManagementViewModel viewModel;

  const TeamManagementWebView({
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Equipe (${viewModel.activeCount} membros)',
                      style: textStyles.headline1,
                    ),
                  ),
                  DSButton.primary(
                    label: 'Adicionar Membro',
                    icon: Icons.person_add_outlined,
                    onTap: () => presenter.navigateToAddMember(context),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.lg),

              // Busca
              TextField(
                onChanged: presenter.onSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou email...',
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
                ),
              ),
              const SizedBox(height: DSSpacing.lg),

              // Lista
              if (viewModel.filteredMembers.isEmpty)
                EmptyState(
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
              else
                ...viewModel.filteredMembers.map(
                  (member) => MemberListItem(
                    member: member,
                    isWeb: true,
                    onEdit: () => presenter.editMember(context, member),
                    onRemove: () => presenter.removeMember(context, member),
                  ),
                ),
              const SizedBox(height: DSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
