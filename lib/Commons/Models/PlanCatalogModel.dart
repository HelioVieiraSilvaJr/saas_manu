import 'package:cloud_firestore/cloud_firestore.dart';

class PlanCatalogModel {
  final String id;
  final String period;
  final String tier;
  final String name;
  final String description;
  final double price;
  final int customerLimit;
  final int productLimit;
  final int durationDays;
  final bool isActive;
  final int sortOrder;
  final List<String> features;

  const PlanCatalogModel({
    required this.id,
    required this.period,
    required this.tier,
    required this.name,
    required this.description,
    required this.price,
    required this.customerLimit,
    required this.productLimit,
    required this.durationDays,
    required this.isActive,
    required this.sortOrder,
    this.features = const [],
  });

  static String buildId(String period, String tier) {
    if (period == 'trial') return 'trial';
    return '${period}_${tier.isEmpty ? 'standard' : tier}';
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static PlanCatalogModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final fallback = defaultById(doc.id);
    return PlanCatalogModel(
      id: doc.id,
      period: _asString(data['period'], fallback: fallback.period),
      tier: _asString(data['tier'], fallback: fallback.tier),
      name: _asString(data['name'], fallback: fallback.name),
      description: _asString(
        data['description'],
        fallback: fallback.description,
      ),
      price: _asDouble(data['price'], fallback: fallback.price),
      customerLimit: _asInt(
        data['customer_limit'],
        fallback: fallback.customerLimit,
      ),
      productLimit: _asInt(
        data['product_limit'],
        fallback: fallback.productLimit,
      ),
      durationDays: _asInt(
        data['duration_days'],
        fallback: fallback.durationDays,
      ),
      isActive: data['is_active'] ?? fallback.isActive,
      sortOrder: _asInt(data['sort_order'], fallback: fallback.sortOrder),
      features: _asStringList(data['features']).isNotEmpty
          ? _asStringList(data['features'])
          : fallback.features,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'tier': tier,
      'name': name,
      'description': description,
      'price': price,
      'customer_limit': customerLimit,
      'product_limit': productLimit,
      'duration_days': durationDays,
      'is_active': isActive,
      'sort_order': sortOrder,
      'features': features,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  PlanCatalogModel copyWith({
    String? id,
    String? period,
    String? tier,
    String? name,
    String? description,
    double? price,
    int? customerLimit,
    int? productLimit,
    int? durationDays,
    bool? isActive,
    int? sortOrder,
    List<String>? features,
  }) {
    return PlanCatalogModel(
      id: id ?? this.id,
      period: period ?? this.period,
      tier: tier ?? this.tier,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      customerLimit: customerLimit ?? this.customerLimit,
      productLimit: productLimit ?? this.productLimit,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      features: features ?? this.features,
    );
  }

  String get displayName {
    if (period == 'trial') return name;
    return '$name ${tier == 'pro' ? 'Pro' : 'Standard'}';
  }

  String get billingLabel {
    if (period == 'trial') return 'grátis por $durationDays dias';
    final suffix = period == 'quarterly' ? '/trimestre' : '/mês';
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}$suffix';
  }

  String get limitsLabel {
    final customers = customerLimit == 0
        ? 'Clientes ilimitados'
        : 'Até $customerLimit clientes';
    final products = productLimit == 0
        ? 'Produtos ilimitados'
        : 'Até $productLimit produtos';
    return '$customers • $products';
  }

  static const List<PlanCatalogModel> defaults = [
    PlanCatalogModel(
      id: 'trial',
      period: 'trial',
      tier: 'standard',
      name: 'Trial',
      description: 'Período inicial para explorar a plataforma.',
      price: 0,
      customerLimit: 0,
      productLimit: 500,
      durationDays: 15,
      isActive: true,
      sortOrder: 0,
      features: [
        'Todas as funcionalidades principais',
        'Até 500 produtos',
        'Atendimento com IA no WhatsApp',
      ],
    ),
    PlanCatalogModel(
      id: 'monthly_standard',
      period: 'monthly',
      tier: 'standard',
      name: 'Mensal',
      description: 'Plano mensal para operação recorrente.',
      price: 79.90,
      customerLimit: 1000,
      productLimit: 50,
      durationDays: 30,
      isActive: true,
      sortOrder: 10,
      features: [
        'Até 1.000 clientes',
        'Até 50 produtos',
        'CRM completo',
        'WhatsApp Bot',
      ],
    ),
    PlanCatalogModel(
      id: 'monthly_pro',
      period: 'monthly',
      tier: 'pro',
      name: 'Mensal',
      description: 'Plano mensal com limites ampliados.',
      price: 149.90,
      customerLimit: 0,
      productLimit: 500,
      durationDays: 30,
      isActive: true,
      sortOrder: 20,
      features: [
        'Clientes ilimitados',
        'Até 500 produtos',
        'CRM completo',
        'WhatsApp Bot',
        'Suporte prioritário',
      ],
    ),
    PlanCatalogModel(
      id: 'quarterly_standard',
      period: 'quarterly',
      tier: 'standard',
      name: 'Trimestral',
      description: 'Plano trimestral com economia no ciclo.',
      price: 199.90,
      customerLimit: 1000,
      productLimit: 50,
      durationDays: 90,
      isActive: true,
      sortOrder: 30,
      features: [
        'Até 1.000 clientes',
        'Até 50 produtos',
        'Suporte por email',
        'Economia no ciclo trimestral',
      ],
    ),
    PlanCatalogModel(
      id: 'quarterly_pro',
      period: 'quarterly',
      tier: 'pro',
      name: 'Trimestral',
      description: 'Plano trimestral com maior escala.',
      price: 399.90,
      customerLimit: 0,
      productLimit: 500,
      durationDays: 90,
      isActive: true,
      sortOrder: 40,
      features: [
        'Clientes ilimitados',
        'Até 500 produtos',
        'Relatórios avançados',
        'Suporte prioritário',
      ],
    ),
  ];

  static PlanCatalogModel defaultById(String id) {
    return defaults.firstWhere(
      (plan) => plan.id == id,
      orElse: () => defaults.first,
    );
  }

  static PlanCatalogModel defaultFor(String period, String tier) {
    final id = buildId(period, tier);
    return defaultById(id);
  }
}
