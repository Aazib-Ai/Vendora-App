import 'package:equatable/equatable.dart';

class Seller extends Equatable {
  final String id;
  final String userId;
  final String businessName;
  final String businessCategory;
  final String description;
  final String whatsappNumber;
  final String status; // 'unverified', 'active', 'rejected', 'suspended'
  final double totalSales;
  final double walletBalance;
  final DateTime createdAt;

  const Seller({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessCategory,
    required this.description,
    required this.whatsappNumber,
    required this.status,
    required this.totalSales,
    required this.walletBalance,
    required this.createdAt,
  });

  bool get isApproved => status == 'active';
  bool get isPending => status == 'unverified';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      businessCategory: json['business_category'],
      description: json['description'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
      status: json['status'] ?? 'unverified',
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'business_category': businessCategory,
      'description': description,
      'whatsapp_number': whatsappNumber,
      'status': status,
      'total_sales': totalSales,
      'wallet_balance': walletBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Seller copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessCategory,
    String? description,
    String? whatsappNumber,
    String? status,
    double? totalSales,
    double? walletBalance,
    DateTime? createdAt,
  }) {
    return Seller(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      description: description ?? this.description,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      status: status ?? this.status,
      totalSales: totalSales ?? this.totalSales,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        businessName,
        businessCategory,
        description,
        whatsappNumber,
        status,
        totalSales,
        walletBalance,
        createdAt,
      ];
}

class SellerStats extends Equatable {
  final int ordersToday;
  final int ordersPending;
  final double salesToday;
  final double totalCommission;
  final double netEarnings;
  final List<double> weeklySales; // 7 days of sales
  final Map<String, double> categorySales;
  final List<ProductPerformance> topProducts;

  const SellerStats({
    required this.ordersToday,
    required this.ordersPending,
    required this.salesToday,
    required this.totalCommission,
    required this.netEarnings,
    required this.weeklySales,
    required this.categorySales,
    required this.topProducts,
  });

  @override
  List<Object?> get props => [
        ordersToday,
        ordersPending,
        salesToday,
        totalCommission,
        netEarnings,
        weeklySales,
        categorySales,
        topProducts,
      ];
}

class ProductPerformance extends Equatable {
  final String productName;
  final int salesCount;
  final double totalRevenue;

  const ProductPerformance({
    required this.productName,
    required this.salesCount,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [productName, salesCount, totalRevenue];
}
