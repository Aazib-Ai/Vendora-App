import 'package:equatable/equatable.dart';

/// Data point for GMV (Gross Merchandise Value) trend
class GMVDataPoint extends Equatable {
  final DateTime date;
  final double value;

  const GMVDataPoint({
    required this.date,
    required this.value,
  });

  @override
  List<Object?> get props => [date, value];
}

/// Data point for user growth tracking
class UserGrowthDataPoint extends Equatable {
  final DateTime date;
  final int newUsers;
  final int totalUsers;

  const UserGrowthDataPoint({
    required this.date,
    required this.newUsers,
    required this.totalUsers,
  });

  @override
  List<Object?> get props => [date, newUsers, totalUsers];
}

/// Category sales data for top categories ranking
class CategorySalesData extends Equatable {
  final String categoryId;
  final String categoryName;
  final double revenue;
  final double percentage;
  final int productCount;

  const CategorySalesData({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.percentage,
    required this.productCount,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        revenue,
        percentage,
        productCount,
      ];
}

/// Seller revenue data for top sellers leaderboard
class SellerRevenueData extends Equatable {
  final String sellerId;
  final String sellerName;
  final String businessName;
  final double totalRevenue;
  final double commission;
  final double netEarnings;
  final int orderCount;

  const SellerRevenueData({
    required this.sellerId,
    required this.sellerName,
    required this.businessName,
    required this.totalRevenue,
    required this.commission,
    required this.netEarnings,
    required this.orderCount,
  });

  @override
  List<Object?> get props => [
        sellerId,
        sellerName,
        businessName,
        totalRevenue,
        commission,
        netEarnings,
        orderCount,
      ];
}

/// Main admin analytics data entity
/// Requirements: 8.8, 17.4
class AdminAnalyticsData extends Equatable {
  final double totalGMV;
  final double platformRevenue;
  final double averageOrderValue;
  final double conversionRate;
  final List<GMVDataPoint> gmvTrend;
  final List<UserGrowthDataPoint> userGrowth;
  final List<CategorySalesData> topCategories;
  final List<SellerRevenueData> topSellers;

  const AdminAnalyticsData({
    required this.totalGMV,
    required this.platformRevenue,
    required this.averageOrderValue,
    required this.conversionRate,
    required this.gmvTrend,
    required this.userGrowth,
    required this.topCategories,
    required this.topSellers,
  });

  @override
  List<Object?> get props => [
        totalGMV,
        platformRevenue,
        averageOrderValue,
        conversionRate,
        gmvTrend,
        userGrowth,
        topCategories,
        topSellers,
      ];

  factory AdminAnalyticsData.empty() {
    return const AdminAnalyticsData(
      totalGMV: 0,
      platformRevenue: 0,
      averageOrderValue: 0,
      conversionRate: 0,
      gmvTrend: [],
      userGrowth: [],
      topCategories: [],
      topSellers: [],
    );
  }
}
