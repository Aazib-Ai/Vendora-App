import 'package:dartz/dartz.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';

abstract class IAdminRepository {
  Future<Either<Failure, AdminStats>> getDashboardStats();
  Stream<AdminStats> watchDashboardStats();
  
  // Product Moderation - Requirements 8.4, 8.7
  Future<Either<Failure, void>> approveProduct(String productId);
  Future<Either<Failure, void>> rejectProduct(String productId, String reason);
  Future<Either<Failure, void>> hideProduct(String productId);
}
