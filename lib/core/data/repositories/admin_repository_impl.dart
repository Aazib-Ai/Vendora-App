import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements IAdminRepository {
  final SupabaseClient _supabase;

  AdminRepositoryImpl(this._supabase);

  @override
  Future<Either<Failure, AdminStats>> getDashboardStats() async {
    try {
      // Fetch all statistics in parallel for better performance
      final results = await Future.wait([
        _getTotalRevenue(),
        _getTotalOrders(),
        _getTotalUsers(),
        _getTotalSellers(),
        _getTotalProducts(),
        _getPlatformEarnings(),
        _getPendingSellers(),
        _getPendingProducts(),
        _getActiveDisputes(),
        _getReportedProducts(),
        _getRevenueTrend(),
      ]);

      final stats = AdminStats(
        totalRevenue: results[0] as double,
        totalOrders: results[1] as int,
        totalUsers: results[2] as int,
        totalSellers: results[3] as int,
        totalProducts: results[4] as int,
        totalEarnings: results[5] as double,
        pendingSellers: results[6] as int,
        pendingProducts: results[7] as int,
        activeDisputes: results[8] as int,
        reportedProducts: results[9] as int,
        revenueTrend: results[10] as List<double>,
      );

      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AdminStats> watchDashboardStats() async* {
    // Initial fetch
    final initialResult = await getDashboardStats();
    yield initialResult.fold(
      (failure) => AdminStats.empty(),
      (stats) => stats,
    );

    // Subscribe to real-time changes
    // Create a stream controller to combine multiple table subscriptions
    final controller = StreamController<AdminStats>();

    // Subscribe to orders changes (affects revenue, orders count, earnings)
    final ordersChannel = _supabase
        .channel('admin_dashboard_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) async {
            final stats = await getDashboardStats();
            stats.fold(
              (failure) => null,
              (updatedStats) => controller.add(updatedStats),
            );
          },
        )
        .subscribe();

    // Subscribe to users changes
    final usersChannel = _supabase
        .channel('admin_dashboard_users')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) async {
            final stats = await getDashboardStats();
            stats.fold(
              (failure) => null,
              (updatedStats) => controller.add(updatedStats),
            );
          },
        )
        .subscribe();

    // Subscribe to sellers changes
    final sellersChannel = _supabase
        .channel('admin_dashboard_sellers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sellers',
          callback: (payload) async {
            final stats = await getDashboardStats();
            stats.fold(
              (failure) => null,
              (updatedStats) => controller.add(updatedStats),
            );
          },
        )
        .subscribe();

    // Subscribe to products changes
    final productsChannel = _supabase
        .channel('admin_dashboard_products')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) async {
            final stats = await getDashboardStats();
            stats.fold(
              (failure) => null,
              (updatedStats) => controller.add(updatedStats),
            );
          },
        )
        .subscribe();

    yield* controller.stream;
  }

  Future<double> _getTotalRevenue() async {
    final response = await _supabase
        .from('orders')
        .select('total')
        .eq('status', 'delivered');

    if (response == null || response.isEmpty) return 0.0;

    double total = 0.0;
    for (var order in response) {
      total += (order['total'] as num).toDouble();
    }
    return total;
  }

  Future<int> _getTotalOrders() async {
    final response = await _supabase
        .from('orders')
        .select('id', const FetchOptions(count: CountOption.exact, head: true));

    return response.count ?? 0;
  }

  Future<int> _getTotalUsers() async {
    final response = await _supabase
        .from('users')
        .select('id', const FetchOptions(count: CountOption.exact, head: true))
        .eq('role', 'buyer');

    return response.count ?? 0;
  }

  Future<int> _getTotalSellers() async {
    final response = await _supabase
        .from('sellers')
        .select('id', const FetchOptions(count: CountOption.exact, head: true));

    return response.count ?? 0;
  }

  Future<int> _getTotalProducts() async {
    final response = await _supabase
        .from('products')
        .select('id', const FetchOptions(count: CountOption.exact, head: true));

    return response.count ?? 0;
  }

  Future<double> _getPlatformEarnings() async {
    final response = await _supabase
        .from('orders')
        .select('platform_commission')
        .eq('status', 'delivered');

    if (response == null || response.isEmpty) return 0.0;

    double total = 0.0;
    for (var order in response) {
      total += (order['platform_commission'] as num).toDouble();
    }
    return total;
  }

  Future<int> _getPendingSellers() async {
    final response = await _supabase
        .from('sellers')
        .select('id', const FetchOptions(count: CountOption.exact, head: true))
        .eq('status', 'unverified');

    return response.count ?? 0;
  }

  Future<int> _getPendingProducts() async {
    final response = await _supabase
        .from('products')
        .select('id', const FetchOptions(count: CountOption.exact, head: true))
        .eq('status', 'pending');

    return response.count ?? 0;
  }

  Future<int> _getActiveDisputes() async {
    final response = await _supabase
        .from('disputes')
        .select('id', const FetchOptions(count: CountOption.exact, head: true))
        .neq('status', 'resolved');

    return response.count ?? 0;
  }

  Future<int> _getReportedProducts() async {
    final response = await _supabase
        .from('products')
        .select('id', const FetchOptions(count: CountOption.exact, head: true))
        .eq('status', 'reported');

    return response.count ?? 0;
  }

  Future<List<double>> _getRevenueTrend() async {
    // Get revenue for last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final response = await _supabase
        .from('orders')
        .select('total, created_at')
        .eq('status', 'delivered')
        .gte('created_at', thirtyDaysAgo.toIso8601String())
        .order('created_at', ascending: true);

    if (response == null || response.isEmpty) {
      return List.filled(30, 0.0);
    }

    // Group by day and sum revenue
    final Map<int, double> dailyRevenue = {};
    for (var order in response) {
      final date = DateTime.parse(order['created_at'] as String);
      final dayIndex = now.difference(date).inDays;
      final reversedIndex = 29 - dayIndex; // Reverse so oldest is first
      
      if (reversedIndex >= 0 && reversedIndex < 30) {
        dailyRevenue[reversedIndex] = 
            (dailyRevenue[reversedIndex] ?? 0.0) + (order['total'] as num).toDouble();
      }
    }

    // Create array with 30 days
    final List<double> trend = List.filled(30, 0.0);
    dailyRevenue.forEach((index, revenue) {
      trend[index] = revenue;
    });

    return trend;
  }
}
