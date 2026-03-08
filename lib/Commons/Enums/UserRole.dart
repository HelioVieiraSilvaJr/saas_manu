/// Roles de usuário no sistema multi-tenant.
enum UserRole {
  superAdmin, // Acesso global, gerencia tenants e billing
  tenantAdmin, // Administra seu próprio tenant, convida usuários
  user; // Usuário padrão do tenant

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.tenantAdmin:
        return 'Administrador';
      case UserRole.user:
        return 'Usuário';
    }
  }

  /// Descrição detalhada do role.
  String get description {
    switch (this) {
      case UserRole.superAdmin:
        return 'Acesso global, gerencia tenants e billing';
      case UserRole.tenantAdmin:
        return 'Pode gerenciar equipe, produtos, clientes e vendas';
      case UserRole.user:
        return 'Pode registrar vendas e visualizar dados';
    }
  }

  /// Converte string para UserRole (padrão: user).
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.user,
    );
  }
}
