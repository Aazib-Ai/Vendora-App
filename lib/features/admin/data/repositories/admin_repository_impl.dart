import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/services/notification_service.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';
import 'package:vendora/features/admin/domain/entities/admin_analytics_data.dart';
import 'package:vendora/features/admin/domain/entities/commission_data.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';
import 'package:vendora/models/dispute.dart';
import 'package:vendora/models/user_entity.dart';

/// Implementation of admin repository for managing platform operations
/// Handles dashboard statistics and product moderation
class AdminRepositoryImpl implements IAdminRepository {
  final SupabaseConfig _supabaseConfig;
  final IProductRepository? _productRepository;
  final NotificationService? _notificationService;

  AdminRepositoryImpl({
    SupabaseConfig? supabaseConfig,
    IProductRepository? productRepository,
    NotificationService? notificationService,
  })  : _supabaseConfig = supabaseConfig ?? SupabaseConfig(),
        _productRepository = productRepository,
        _notificationService = notificationService;

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

      // Send notification to seller about product approval
      if (_productRepository != null && _notificationService != null) {
        final productResult = await _productRepository.getProductById(productId);
        productResult.fold(
          (_) {}, // Ignore error, notification is best-effort
          (product) async {
            await _notificationService.notifyProductApproval(
              sellerId: product.sellerId,
              productId: productId,
              productName: product.name,
            );
          },
        );
      }

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

      // Send notification to seller about product rejection with reason
      if (_productRepository != null && _notificationService != null) {
        final productResult = await _productRepository.getProductById(productId);
        productResult.fold(
          (_) {}, // Ignore error, notification is best-effort
          (product) async {
            await _notificationService.notifyProductRejection(
              sellerId: product.sellerId,
              productId: productId,
              productName: product.name,
              reason: reason,
            );
          },
        );
      }

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

      // Send notification to seller about product being hidden
      if (_productRepository != null && _notificationService != null) {
        final productResult = await _productRepository.getProductById(productId);
        productResult.fold(
          (_) {}, // Ignore error, notification is best-effort
          (product) async {
            await _notificationService.notifyProductHidden(
              sellerId: product.sellerId,
              productId: productId,
              productName: product.name,
            );
          },
        );
      }

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Dispute>>> getDisputes({
    DisputeStatus? status,
  }) async {
    try {
      var query = _supabaseConfig.client
          .from('disputes')
          .select()
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final data = await query;
      final disputes = (data as List)
          .map((json) => Dispute.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(disputes);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Dispute>> getDisputeById(String disputeId) async {
    try {
      final data = await _supabaseConfig.client
          .from('disputes')
          .select()
          .eq('id', disputeId)
          .single();

      final dispute = Dispute.fromJson(data as Map<String, dynamic>);
      return Right(dispute);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resolveDisputeRefundBuyer(
    String disputeId,
    String resolution,
  ) async {
    try {
      // Get the dispute to find the order
      final disputeData = await _supabaseConfig.client
          .from('disputes')
          .select()
          .eq('id', disputeId)
          .single();

      final orderId = disputeData['order_id'] as String;

      // Update dispute status to resolved
      await _supabaseConfig.client.from('disputes').update({
        'status': DisputeStatus.resolved.name,
        'admin_resolution': resolution,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);

      // Update order status to cancelled (refund scenario)
      await _supabaseConfig.client.from('orders').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // TODO: Create notification for buyer about refund
      // TODO: Create notification for seller about dispute resolution

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resolveDisputeReleaseSeller(
    String disputeId,
    String resolution,
  ) async {
    try {
      // Update dispute status to resolved
      // Order remains as delivered (funds released to seller)
      await _supabaseConfig.client.from('disputes').update({
        'status': DisputeStatus.resolved.name,
        'admin_resolution': resolution,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);

      // TODO: Create notification for buyer about dispute resolution
      // TODO: Create notification for seller about successful resolution

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Analytics Methods - Requirements 8.8, 17.4

  @override
  Future<Either<Failure, AdminAnalyticsData>> getAnalyticsData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch all analytics data concurrently
      final results = await Future.wait([
        getGMVTrend(startDate: startDate, endDate: endDate),
        getUserGrowthData(startDate: startDate, endDate: endDate),
        getTopCategories(limit: 10),
        getTopSellers(limit: 10, startDate: startDate, endDate: endDate),
      ]);

      // Extract data from results
      final gmvTrend = results[0].fold((_) => <GMVDataPoint>[], (data) => data as List<GMVDataPoint>);
      final userGrowth = results[1].fold((_) => <UserGrowthDataPoint>[], (data) => data as List<UserGrowthDataPoint>);
      final topCategories = results[2].fold((_) => <CategorySalesData>[], (data) => data as List<CategorySalesData>);
      final topSellers = results[3].fold((_) => <SellerRevenueData>[], (data) => data as List<SellerRevenueData>);

      // Calculate summary metrics
      final totalGMV = gmvTrend.fold(0.0, (sum, point) => sum + point.value);
      final platformRevenue = totalGMV * 0.1; // 10% commission

      // Get order count for average calculation
      final ordersData = await _supabaseConfig.client
          .from('orders')
          .select('id')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final orderCount = ordersData.length;
      final averageOrderValue = orderCount > 0 ? totalGMV / orderCount : 0.0;

      // Conversion rate placeholder (would need sessions data)
      const conversionRate = 0.0;

      return Right(AdminAnalyticsData(
        totalGMV: totalGMV,
        platformRevenue: platformRevenue,
        averageOrderValue: averageOrderValue,
        conversionRate: conversionRate,
        gmvTrend: gmvTrend,
        userGrowth: userGrowth,
        topCategories: topCategories,
        topSellers: topSellers,
      ));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GMVDataPoint>>> getGMVTrend({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch orders in date range and group by date
      final ordersData = await _supabaseConfig.client
          .from('orders')
          .select('created_at, total')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at');

      // Group orders by date
      final Map<String, double> dailyGMV = {};
      for (final order in ordersData) {
        final date = DateTime.parse(order['created_at'] as String);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final total = (order['total'] as num).toDouble();
        dailyGMV[dateKey] = (dailyGMV[dateKey] ?? 0) + total;
      }

      // Convert to list of data points
      final dataPoints = dailyGMV.entries.map((entry) {
        return GMVDataPoint(
          date: DateTime.parse(entry.key),
          value: entry.value,
        );
      }).toList();

      dataPoints.sort((a, b) => a.date.compareTo(b.date));

      return Right(dataPoints);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserGrowthDataPoint>>> getUserGrowthData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch all users
      final allUsers = await _supabaseConfig.client
          .from('users')
          .select('created_at')
          .order('created_at');

      // Group users by date
      final Map<String, int> dailyNewUsers = {};
      int cumulativeTotal = 0;

      for (final user in allUsers) {
        final date = DateTime.parse(user['created_at'] as String);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyNewUsers[dateKey] = (dailyNewUsers[dateKey] ?? 0) + 1;
      }

      // Create data points with cumulative totals
      final dataPoints = <UserGrowthDataPoint>[];
      final sortedDates = dailyNewUsers.keys.toList()..sort();

      for (final dateKey in sortedDates) {
        final date = DateTime.parse(dateKey);
        if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)))) {
          cumulativeTotal += dailyNewUsers[dateKey]!;
          dataPoints.add(UserGrowthDataPoint(
            date: date,
            newUsers: dailyNewUsers[dateKey]!,
            totalUsers: cumulativeTotal,
          ));
        }
      }

      return Right(dataPoints);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CategorySalesData>>> getTopCategories({
    int limit = 10,
  }) async {
    try {
      // Fetch order items with product category information
      final orderItems = await _supabaseConfig.client
          .from('order_items')
          .select('total_price, product_id, products(category_id)');

      // Group by category and calculate totals
      final Map<String, double> categoryRevenue = {};
      final Map<String, int> categoryProductCount = {};

      for (final item in orderItems) {
        final productData = item['products'];
        if (productData != null) {
          final categoryId = productData['category_id'] as String?;
          if (categoryId != null) {
            final revenue = (item['total_price'] as num).toDouble();
            categoryRevenue[categoryId] = (categoryRevenue[categoryId] ?? 0) + revenue;
            categoryProductCount[categoryId] = (categoryProductCount[categoryId] ?? 0) + 1;
          }
        }
      }

      // Calculate total for percentages
      final totalRevenue = categoryRevenue.values.fold(0.0, (sum, value) => sum + value);

      // Fetch category names (assuming categories table exists)
      // For now, use category ID as name
      final categoryDataList = <CategorySalesData>[];
      for (final entry in categoryRevenue.entries) {
        final percentage = totalRevenue > 0 ? (entry.value / totalRevenue) * 100 : 0;
        categoryDataList.add(CategorySalesData(
          categoryId: entry.key,
          categoryName: 'Category ${entry.key.substring(0, 8)}', // Simplified
          revenue: entry.value,
          percentage: percentage,
          productCount: categoryProductCount[entry.key] ?? 0,
        ));
      }

      // Sort by revenue and limit
      categoryDataList.sort((a, b) => b.revenue.compareTo(a.revenue));
      final limitedList = categoryDataList.take(limit).toList();

      return Right(limitedList);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SellerRevenueData>>> getTopSellers({
    int limit = 10,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch order items with seller information
      final orderItems = await _supabaseConfig.client
          .from('order_items')
          .select('seller_id, total_price, orders!inner(created_at)')
          .gte('orders.created_at', startDate.toIso8601String())
          .lte('orders.created_at', endDate.toIso8601String());

      // Group by seller
      final Map<String, double> sellerRevenue = {};
      final Map<String, int> sellerOrderCount = {};

      for (final item in orderItems) {
        final sellerId = item['seller_id'] as String;
        final revenue = (item['total_price'] as num).toDouble();
        sellerRevenue[sellerId] = (sellerRevenue[sellerId] ?? 0) + revenue;
        sellerOrderCount[sellerId] = (sellerOrderCount[sellerId] ?? 0) + 1;
      }

      // Fetch seller details
      final sellerDataList = <SellerRevenueData>[];
      for (final sellerId in sellerRevenue.keys) {
        try {
          final sellerData = await _supabaseConfig.client
              .from('sellers')
              .select('business_name, users(name)')
              .eq('id', sellerId)
              .single();

          final totalRevenue = sellerRevenue[sellerId]!;
          final commission = totalRevenue * 0.1; // 10% platform commission
          final netEarnings = totalRevenue - commission;

          sellerDataList.add(SellerRevenueData(
            sellerId: sellerId,
            sellerName: sellerData['users']?['name'] ?? 'Unknown',
            businessName: sellerData['business_name'] as String,
            totalRevenue: totalRevenue,
            commission: commission,
            netEarnings: netEarnings,
            orderCount: sellerOrderCount[sellerId] ?? 0,
          ));
        } catch (e) {
          // Skip seller if data fetch fails
          continue;
        }
      }

      // Sort by revenue and limit
      sellerDataList.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
      final limitedList = sellerDataList.take(limit).toList();

      return Right(limitedList);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommissionData>> getCommissionTracking({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch orders in date range
      final ordersData = await _supabaseConfig.client
          .from('orders')
          .select('platform_commission, created_at')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalCommission = 0;
      final Map<String, double> dailyCommission = {};

      for (final order in ordersData) {
        final commission = (order['platform_commission'] as num).toDouble();
        totalCommission += commission;

        final date = DateTime.parse(order['created_at'] as String);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyCommission[dateKey] = (dailyCommission[dateKey] ?? 0) + commission;
      }

      final orderCount = ordersData.length;
      final averageCommission = orderCount > 0 ? totalCommission / orderCount : 0.0;

      // Get commission by seller
      final sellerResult = await getTopSellers(
        limit: 100, // Get more sellers for commission breakdown
        startDate: startDate,
        endDate: endDate,
      );

      final commissionBySeller = sellerResult.fold(
        (_) => <SellerCommissionData>[],
        (sellers) => sellers.map((seller) {
          return SellerCommissionData(
            sellerId: seller.sellerId,
            sellerName: seller.sellerName,
            businessName: seller.businessName,
            grossSales: seller.totalRevenue,
            commissionAmount: seller.commission,
            netEarnings: seller.netEarnings,
            orderCount: seller.orderCount,
          );
        }).toList(),
      );

      // Create commission trend
      final commissionTrend = dailyCommission.entries.map((entry) {
        return CommissionTrendPoint(
          date: DateTime.parse(entry.key),
          commissionAmount: entry.value,
        );
      }).toList();

      commissionTrend.sort((a, b) => a.date.compareTo(b.date));

      return Right(CommissionData(
        totalPlatformEarnings: totalCommission,
        averageCommissionPerOrder: averageCommission,
        totalOrders: orderCount,
        commissionBySeller: commissionBySeller,
        commissionTrend: commissionTrend,
      ));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // User Management Methods - Requirements 8.5, 8.6

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers({
    UserRole? roleFilter,
    bool? isActiveFilter,
  }) async {
    try {
      // Start with base query
      PostgrestFilterBuilder query = _supabaseConfig.client.from('users').select();

      // Apply role filter if specified
      if (roleFilter != null) {
        query = query.eq('role', roleFilter.name);
      }

      // Apply active status filter if specified
      if (isActiveFilter != null) {
        query = query.eq('is_active', isActiveFilter);
      }

      // Execute query with ordering
      final response = await query.order('created_at', ascending: false);
      
      final users = (response as List)
          .map((json) => UserEntity.fromJson(json))
          .toList();

      return Right(users);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> banUser(String userId) async {
    try {
      // Set isActive to false - Requirements: 8.5
      await _supabaseConfig.client
          .from('users')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Attempt to revoke session using Supabase admin API
      // This requires admin privileges
      try {
        await _supabaseConfig.client.auth.admin.deleteUser(userId);
      } catch (e) {
        // Session revocation may fail if admin API is not configured
        // We continue anyway as the user is marked inactive
        print('Warning: Could not revoke user session: $e');
      }

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> banSeller(String sellerId) async {
    try {
      // First, get the seller's user_id
      final sellerData = await _supabaseConfig.client
          .from('sellers')
          .select('user_id')
          .eq('id', sellerId)
          .single();

      final userId = sellerData['user_id'] as String;

      // Set seller isActive to false - Requirements: 8.6
      await _supabaseConfig.client
          .from('sellers')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId);

      // Hide all seller's products - Requirements: 8.6
      await _supabaseConfig.client
          .from('products')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('seller_id', sellerId);

      // Also ban the associated user account
      await _supabaseConfig.client
          .from('users')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Attempt to revoke session
      try {
        await _supabaseConfig.client.auth.admin.deleteUser(userId);
      } catch (e) {
        print('Warning: Could not revoke seller session: $e');
      }

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
