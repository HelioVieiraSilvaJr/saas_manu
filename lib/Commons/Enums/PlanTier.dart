/// Tier (nível de recursos) do plano do tenant.
enum PlanTier {
  standard,
  pro;

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case PlanTier.standard:
        return 'Standard';
      case PlanTier.pro:
        return 'Pro';
    }
  }

  /// Descrição dos limites do tier.
  String get description {
    switch (this) {
      case PlanTier.standard:
        return 'Até 1.000 clientes e 50 produtos';
      case PlanTier.pro:
        return 'Clientes ilimitados e até 500 produtos';
    }
  }

  /// Limite de clientes (0 = ilimitado).
  int get maxCustomers {
    switch (this) {
      case PlanTier.standard:
        return 1000;
      case PlanTier.pro:
        return 0; // ilimitado
    }
  }

  /// Limite de produtos.
  int get maxProducts {
    switch (this) {
      case PlanTier.standard:
        return 50;
      case PlanTier.pro:
        return 500;
    }
  }

  /// Retorna o preço para o período + tier.
  double priceForPeriod(String period) {
    switch (this) {
      case PlanTier.standard:
        switch (period) {
          case 'monthly':
            return 79.90;
          case 'quarterly':
            return 199.90;
          default:
            return 0;
        }
      case PlanTier.pro:
        switch (period) {
          case 'monthly':
            return 149.90;
          case 'quarterly':
            return 399.90;
          default:
            return 0;
        }
    }
  }

  /// Converte string para PlanTier (padrão: standard).
  static PlanTier fromString(String value) {
    return PlanTier.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PlanTier.standard,
    );
  }
}
