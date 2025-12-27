import 'package:dartz/dartz.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';
import 'package:vendora/models/user_entity.dart';
import 'package:vendora/features/admin/domain/entities/admin_analytics_data.dart';
import 'package:vendora/features/admin/domain/entities/commission_data.dart';
import 'package:vendora/models/dispute.dart';

abstract class IAdminRepository {
  Future<Either<Failure, AdminStats>> getDashboardStats();
  Stream<AdminStats> watchDashboardStats();
  
  // Product Moderation - Requirements 8.4, 8.7
  Future<Either<Failure, void>> approveProduct(String productId);
  Future<Either<Failure, void>> rejectProduct(String productId, String reason);
  Future<Either<Failure, void>> hideProduct(String productId);
  
  // Dispute Management - Requirements 8.4, 21.4, 21.5, 21.6
  Future<Either<Failure, List<Dispute>>> getDisputes({DisputeStatus? status});
  Future<Either<Failure, Dispute>> getDisputeById(String disputeId);
  Future<Either<Failure, void>> resolveDisputeRefundBuyer(
    String disputeId,
    String resolution,
  );
  Future<Either<Failure, void>> resolveDisputeReleaseSeller(
    String disputeId,
    String resolution,
  );

  // Analytics - Requirements 8.8, 17.4
  Future<Either<Failure, AdminAnalyticsData>> getAnalyticsData({
    required DateTime startDate,
    required DateTime endDate,
 });

  Future<Either<Failure, List<GMVDataPoint>>> getGMVTrend({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, List<UserGrowthDataPoint>>> getUserGrowthData({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, List<CategorySalesData>>> getTopCategories({
    int limit = 10,
  });

  Future<Either<Failure, List<SellerRevenueData>>> getTopSellers({
    int limit = 10,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, CommissionData>> getCommissionTracking({
    required DateTime startDate,
    required DateTime endDate,
  });

  // User Management - Requirements 8.5, 8.6
  Future<Either<Failure, List<UserEntity>>> getUsers({
    UserRole? roleFilter,
    bool? isActiveFilter,
  });
  Future<Either<Failure, void>> banUser(String userId);
  Future<Either<Failure, void>> banSeller(String sellerId);
}
