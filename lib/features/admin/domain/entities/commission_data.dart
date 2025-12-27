import 'package:equatable/equatable.dart';

/// Commission data for individual seller
class SellerCommissionData extends Equatable {
  final String sellerId;
  final String sellerName;
  final String businessName;
  final double grossSales;
  final double commissionAmount;
  final double netEarnings;
  final int orderCount;

  const SellerCommissionData({
    required this.sellerId,
    required this.sellerName,
    required this.businessName,
    required this.grossSales,
    required this.commissionAmount,
    required this.netEarnings,
    required this.orderCount,
  });

  @override
  List<Object?> get props => [
        sellerId,
        sellerName,
        businessName,
        grossSales,
        commissionAmount,
        netEarnings,
        orderCount,
      ];
}

/// Commission trend data point
class CommissionTrendPoint extends Equatable {
  final DateTime date;
  final double commissionAmount;

  const CommissionTrendPoint({
    required this.date,
    required this.commissionAmount,
  });

  @override
  List<Object?> get props => [date, commissionAmount];
}

/// Platform commission tracking data
/// Requirements: 17.4
class CommissionData extends Equatable {
  final double totalPlatformEarnings;
  final double averageCommissionPerOrder;
  final int totalOrders;
  final List<SellerCommissionData> commissionBySeller;
  final List<CommissionTrendPoint> commissionTrend;

  const CommissionData({
    required this.totalPlatformEarnings,
    required this.averageCommissionPerOrder,
    required this.totalOrders,
    required this.commissionBySeller,
    required this.commissionTrend,
  });

  @override
  List<Object?> get props => [
        totalPlatformEarnings,
        averageCommissionPerOrder,
        totalOrders,
        commissionBySeller,
        commissionTrend,
      ];

  factory CommissionData.empty() {
    return const CommissionData(
      totalPlatformEarnings: 0,
      averageCommissionPerOrder: 0,
      totalOrders: 0,
      commissionBySeller: [],
      commissionTrend: [],
    );
  }
}
