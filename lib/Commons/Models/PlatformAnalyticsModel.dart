import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de analytics agregados da plataforma.
///
/// Armazenado em `platform_analytics/global_summary`.
/// Atualizado via lazy-cache (recalculado se stale > 1 hora).
class PlatformAnalyticsModel {
  final double totalSalesToday;
  final double totalSalesMonth;
  final int salesCountToday;
  final int salesCountMonth;
  final int totalCustomers;
  final int newCustomersMonth;
  final double averageTicketMonth;
  final List<TopTenantDTO> topTenants;
  final DateTime lastUpdated;

  const PlatformAnalyticsModel({
    this.totalSalesToday = 0,
    this.totalSalesMonth = 0,
    this.salesCountToday = 0,
    this.salesCountMonth = 0,
    this.totalCustomers = 0,
    this.newCustomersMonth = 0,
    this.averageTicketMonth = 0,
    this.topTenants = const [],
    required this.lastUpdated,
  });

  bool get isStale => DateTime.now().difference(lastUpdated).inMinutes >= 60;

  factory PlatformAnalyticsModel.fromMap(Map<String, dynamic> data) {
    final topTenantsData = data['top_tenants'] as List<dynamic>? ?? [];
    return PlatformAnalyticsModel(
      totalSalesToday: (data['total_sales_today'] ?? 0).toDouble(),
      totalSalesMonth: (data['total_sales_month'] ?? 0).toDouble(),
      salesCountToday: (data['sales_count_today'] ?? 0) as int,
      salesCountMonth: (data['sales_count_month'] ?? 0) as int,
      totalCustomers: (data['total_customers'] ?? 0) as int,
      newCustomersMonth: (data['new_customers_month'] ?? 0) as int,
      averageTicketMonth: (data['average_ticket_month'] ?? 0).toDouble(),
      topTenants: topTenantsData
          .map((t) => TopTenantDTO.fromMap(t as Map<String, dynamic>))
          .toList(),
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_sales_today': totalSalesToday,
      'total_sales_month': totalSalesMonth,
      'sales_count_today': salesCountToday,
      'sales_count_month': salesCountMonth,
      'total_customers': totalCustomers,
      'new_customers_month': newCustomersMonth,
      'average_ticket_month': averageTicketMonth,
      'top_tenants': topTenants.map((t) => t.toMap()).toList(),
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// DTO para ranking de tenants por vendas.
class TopTenantDTO {
  final String tenantId;
  final String tenantName;
  final double salesMonth;
  final int salesCount;

  const TopTenantDTO({
    required this.tenantId,
    required this.tenantName,
    required this.salesMonth,
    required this.salesCount,
  });

  factory TopTenantDTO.fromMap(Map<String, dynamic> data) {
    return TopTenantDTO(
      tenantId: data['tenant_id'] ?? '',
      tenantName: data['tenant_name'] ?? '',
      salesMonth: (data['sales_month'] ?? 0).toDouble(),
      salesCount: (data['sales_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'sales_month': salesMonth,
      'sales_count': salesCount,
    };
  }
}
