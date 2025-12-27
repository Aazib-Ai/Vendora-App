import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/core/services/notification_service.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:vendora/core/utils/commission_calculator.dart';

abstract class ISellerRepository {
  Future<Either<Failure, Seller?>> getCurrentSeller(String userId);
  Future<Either<Failure, SellerStats>> getSellerStats(String sellerId);
  Future<Either<Failure, Seller>> updateSellerProfile(Seller seller);
  Future<Either<Failure, List<Seller>>> getUnverifiedSellers();
  Future<Either<Failure, void>> approveSeller(String sellerId);
  Future<Either<Failure, void>> rejectSeller(String sellerId, String reason);
}

class SellerRepository implements ISellerRepository {
  final SupabaseConfig _supabaseConfig;
  final NotificationService? _notificationService;

  SellerRepository({
    SupabaseConfig? supabaseConfig,
    NotificationService? notificationService,
  })  : _supabaseConfig = supabaseConfig ?? SupabaseConfig(),
        _notificationService = notificationService;

  @override
  Future<Either<Failure, Seller?>> getCurrentSeller(String userId) async {
    try {
      final response = await _supabaseConfig.client
          .from('sellers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return const Right(null);
      }

      return Right(Seller.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerStats>> getSellerStats(String sellerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(const Duration(days: 7));

      // Fetch all order items for this seller with related order and product details
      // using !inner to ensure we only get items with valid orders/products
      final response = await _supabaseConfig.client.from('order_items').select('''
            total_price,
            quantity,
            orders!inner (
              id,
              status,
              created_at
            ),
            products!inner (
              name,
              categories (
                name
              )
            )
          ''').eq('seller_id', sellerId);

      final List<dynamic> items = response as List<dynamic>;

      int ordersToday = 0;
      int ordersPending = 0;
      double salesToday = 0;
      double totalGrossSales = 0;
      List<double> weeklySales = List.filled(7, 0.0);
      Map<String, double> categorySalesMap = {};
      Map<String, Map<String, dynamic>> productPerformanceMap = {};
      Set<String> todayOrderIds = {};
      Set<String> pendingOrderIds = {};

      for (var item in items) {
        final order = item['orders'];
        final product = item['products'];
        final status = order['status'] as String;
        final createdAt = DateTime.parse(order['created_at'] as String); // Use order creation time
        final totalPrice = (item['total_price'] as num).toDouble();
        final quantity = (item['quantity'] as num).toInt();
        final orderId = order['id'] as String;

        // Skip cancelled orders for revenue calculations
        if (status == 'cancelled') continue;

        // 1. Total Sales (All Time)
        totalGrossSales += totalPrice;

        // 2. Category Aggregation
        final category = product['categories'];
        final categoryName = category != null ? (category['name'] as String) : 'Uncategorized';
        categorySalesMap[categoryName] = (categorySalesMap[categoryName] ?? 0) + totalPrice;

        // 3. Product Performance Aggregation
        final productName = product['name'] as String;
        if (!productPerformanceMap.containsKey(productName)) {
          productPerformanceMap[productName] = {
            'name': productName,
            'sales': 0,
            'revenue': 0.0,
          };
        }
        productPerformanceMap[productName]!['sales'] += quantity;
        productPerformanceMap[productName]!['revenue'] += totalPrice;

        // 4. Sales Today & Orders Today
        if (createdAt.isAfter(startOfDay)) {
          salesToday += totalPrice;
          todayOrderIds.add(orderId);
        }

        // 5. Pending Orders (Snapshot state, time independent)
        if (status == 'pending' || status == 'processing') {
          pendingOrderIds.add(orderId);
        }

        // 6. Weekly Sales Trend
        final diffDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
            .inDays;

        if (diffDays >= 0 && diffDays < 7) {
          // Index 6 is Today (diff 0), Index 0 is 7 days ago
          // Chart usually goes Left (Old) -> Right (New)
          // So 7 days ago should be index 0
          int index = 6 - diffDays;
          weeklySales[index] += totalPrice;
        }
      }

      ordersToday = todayOrderIds.length;
      ordersPending = pendingOrderIds.length;

      // Calculate Commission and Net using shared utility
      final commissionResult = CommissionCalculator.calculate(totalGrossSales);

      // Process Top Products
      final topProducts = productPerformanceMap.entries.map((e) {
        return ProductPerformance(
          productName: e.value['name'],
          salesCount: e.value['sales'],
          totalRevenue: e.value['revenue'],
        );
      }).toList();

      // Sort by Revenue Descending
      topProducts.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      return Right(SellerStats(
        ordersToday: ordersToday,
        ordersPending: ordersPending,
        salesToday: salesToday,
        totalCommission: commissionResult.commission,
        netEarnings: commissionResult.net,
        weeklySales: weeklySales,
        categorySales: categorySalesMap,
        topProducts: topProducts.take(5).toList(), // Top 5
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  }

  @override
  Future<Either<Failure, Seller>> updateSellerProfile(Seller seller) async {
    try {
      final response = await _supabaseConfig.client
          .from('sellers')
          .update({
            'business_name': seller.businessName,
            'description': seller.description,
            'whatsapp_number': seller.whatsappNumber,
          })
          .eq('id', seller.id)
          .select()
          .single();

      return Right(Seller.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Seller>>> getUnverifiedSellers() async {
    try {
      final response = await _supabaseConfig.client
          .from('sellers')
          .select()
          .eq('status', 'Unverified') // Assuming 'Unverified' is the status string based on requirements
          .order('created_at', ascending: true);

      final sellers = (response as List).map((json) => Seller.fromJson(json)).toList();
      return Right(sellers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveSeller(String sellerId) async {
    try {
      // Fetch seller to get user_id
      final sellerResponse = await _supabaseConfig.client
          .from('sellers')
          .select('user_id')
          .eq('id', sellerId)
          .single();
      
      final userId = sellerResponse['user_id'] as String;
      
      // Update seller status
      await _supabaseConfig.client
          .from('sellers')
          .update({'status': 'Active'})
          .eq('id', sellerId);
      
      // Send approval notification
      if (_notificationService != null) {
        await _notificationService.notifySellerApproval(userId: userId);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectSeller(String sellerId, String reason) async {
    try {
      // Fetch seller to get user_id
      final sellerResponse = await _supabaseConfig.client
          .from('sellers')
          .select('user_id')
          .eq('id', sellerId)
          .single();
      
      final userId = sellerResponse['user_id'] as String;
      
      // Update seller status
      await _supabaseConfig.client
          .from('sellers')
          .update({'status': 'Rejected'}) // We can't easily store reason without a schema change if columns don't exist
          .eq('id', sellerId);

      // Send rejection notification with reason
      if (_notificationService != null) {
        await _notificationService.notifySellerRejection(
          userId: userId,
          reason: reason,
        );
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
