import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';

/// Implementation of admin repository for managing platform operations
/// Handles dashboard statistics and product moderation
class AdminRepositoryImpl implements IAdminRepository {
  final SupabaseConfig _supabaseConfig;

  AdminRepositoryImpl({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, AdminStats>> getDashboardStats() async {
    try {
      // Fetch aggregated stats from Supabase
      final usersCount = await _supabaseConfig.client
          .from('users')
          .count(CountOption.exact);
      
      final sellersCount = await _supabaseConfig.client
          .from('sellers')
          .count(CountOption.exact);
      
      final productsCount = await _supabaseConfig.client
          .from('products')
          .count(CountOption.exact);
      
      final ordersCount = await _supabaseConfig.client
          .from('orders')
          .count(CountOption.exact);

      // Calculate total revenue and platform earnings from orders
      final ordersData = await _supabaseConfig.client
          .from('orders')
          .select('total, platform_commission');

      double totalRevenue = 0;
      double platformEarnings = 0;

      for (final order in ordersData) {
        totalRevenue += (order['total'] as num).toDouble();
        platformEarnings += (order['platform_commission'] as num).toDouble();
      }

      return Right(AdminStats(
        totalUsers: usersCount.count,
        totalSellers: sellersCount.count,
        totalProducts: productsCount.count,
        totalOrders: ordersCount.count,
        totalRevenue: totalRevenue,
        platformEarnings: platformEarnings,
      ));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AdminStats> watchDashboardStats() {
    // For real-time updates, we would listen to Supabase realtime changes
    // For this implementation, we'll return a periodic stream
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      final result = await getDashboardStats();
      return result.fold(
        (_) => AdminStats.empty(),
        (stats) => stats,
      );
    });
  }

  @override
  Future<Either<Failure, void>> approveProduct(String productId) async {
    try {
      // Update product status to approved and set is_active to true
      // Requirements: 8.4
      await _supabaseConfig.client
          .from('products')
          .update({
            'status': 'approved',
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      // TODO: Send notification to seller about product approval
      // This would require a notification service implementation

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectProduct(
    String productId,
    String reason,
  ) async {
    try {
      // Update product status to rejected
      await _supabaseConfig.client
          .from('products')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      // TODO: Send notification to seller about product rejection with reason
      // This would require a notification service implementation
      // For now, the rejection reason is not stored in the database
      // In a full implementation, we might add a rejection_reason column

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> hideProduct(String productId) async {
    try {
      // Set is_active to false to remove from search results
      // Requirements: 8.7
      await _supabaseConfig.client
          .from('products')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      // TODO: Send notification to seller about product being hidden
      // This would require a notification service implementation

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
