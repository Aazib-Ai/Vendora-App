import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  final double totalRevenue;
  final int totalOrders;
  final int totalUsers;
  final int totalSellers;
  final int totalProducts;
  final double totalEarnings;
  final int pendingSellers;
  final int pendingProducts;
  final int activeDisputes;
  final int reportedProducts;
  final List<double> revenueTrend;

  const AdminStats({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalUsers,
    required this.totalSellers,
    required this.totalProducts,
    required this.totalEarnings,
    required this.pendingSellers,
    required this.pendingProducts,
    required this.activeDisputes,
    required this.reportedProducts,
    required this.revenueTrend,
  });

  @override
  List<Object?> get props => [
        totalRevenue,
        totalOrders,
        totalUsers,
        totalSellers,
        totalProducts,
        totalEarnings,
        pendingSellers,
        pendingProducts,
        activeDisputes,
        reportedProducts,
        revenueTrend,
      ];
      
  factory AdminStats.empty() {
    return const AdminStats(
      totalRevenue: 0,
      totalOrders: 0,
      totalUsers: 0,
      totalSellers: 0,
      totalProducts: 0,
      totalEarnings: 0,
      pendingSellers: 0,
      pendingProducts: 0,
      activeDisputes: 0,
      reportedProducts: 0,
      revenueTrend: [],
    );
  }
}
