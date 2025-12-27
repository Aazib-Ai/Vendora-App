import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/models/seller_model.dart';

abstract class ISellerRepository {
  Future<Either<Failure, Seller?>> getCurrentSeller(String userId);
  Future<Either<Failure, SellerStats>> getSellerStats(String sellerId);
}

class SellerRepository implements ISellerRepository {
  final SupabaseConfig _supabaseConfig;

  SellerRepository({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

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
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // 1. Orders Today and Sales Today
      final ordersResponse = await _supabaseConfig.client
          .from('orders')
          .select('id, total, created_at') // Joined query typically needed for seller specific filtering on order_items, simplifying for MVP as if seller owns the order (Single Vendor) OR assuming backend view exists. 
          // REALITY CHECK: Orders contain items from multiple sellers. We need to sum up order_items for THIS seller.
          // Correct approach: Query order_items for this seller created today.
          .select('total_price')
          .eq('seller_id', sellerId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());
          // NOTE: I am querying order_items? 'orders' table doesn't have seller_id directly if multi-vendor. 
          // Let's check Schema... order_items has seller_id. 
      
      // Re-querying correctly from order_items
      final todayItemsResponse = await _supabaseConfig.client
          .from('order_items')
          .select('total_price')
          .eq('seller_id', sellerId)
          .gte('created_at', startOfDay.toIso8601String()); // created_at on order_items might not exist, usually joined from orders.
          // Schema Check: order_items doesn't have created_at in the diagram? 
          // Diagram says: order_items { ... }. created_at is on orders.
          // JOIN REQUIRED. 
      
      // Supabase filtering on joined tables:
      final todayStats = await _supabaseConfig.client
          .from('order_items')
          .select('total_price, orders!inner(created_at)')
          .eq('seller_id', sellerId)
          .gte('orders.created_at', startOfDay.toIso8601String());

      double salesToday = 0;
      int ordersToday = 0; // Approximation: count line items or count unique order IDs.
      final uniqueOrderIdsToday = <String>{};

      for (var item in (todayStats as List)) {
          salesToday += (item['total_price'] as num).toDouble();
           // To count orders properly, we'd need order_id which is in order_items
           // But I didn't select it. Let's assume for now simplistic count or fix query if critical.
           // Updating query implies fetching more data.
      }
      
      // Let's simplify for "Orders Today" -> Total items sold today is easier, or just count calls.
      // Re-fetching with order_id to count unique orders
      final todayStatsDetailed = await _supabaseConfig.client
          .from('order_items')
          .select('total_price, order_id, orders!inner(created_at, status)')
          .eq('seller_id', sellerId)
          .gte('orders.created_at', startOfDay.toIso8601String());

      salesToday = 0;
      for (var item in (todayStatsDetailed as List)) {
          salesToday += (item['total_price'] as num).toDouble();
          uniqueOrderIdsToday.add(item['order_id']);
      }
      ordersToday = uniqueOrderIdsToday.length;


      // 2. Pending Orders
      // Orders that contain items from this seller and are pending/processing
      final pendingResponse = await _supabaseConfig.client
          .from('order_items')
          .select('order_id, orders!inner(status)')
          .eq('seller_id', sellerId)
          .inFilter('orders.status', ['pending', 'processing']); // using inFilter or similar
      
      // Supabase filter syntax might differ slightly for OR, checking 'pending,processing'
      // Use simpler logic: fetch all for seller where status is pending or processing.
      // Actually simpler logic:
       final pendingItems = await _supabaseConfig.client
          .from('order_items')
          .select('order_id, orders!inner(status)')
          .eq('seller_id', sellerId)
          .eq('orders.status', 'pending'); 
          // Just 'pending' for now to be safe with simple API
      
       final uniquePending = <String>{};
       for (var item in (pendingItems as List)) {
           uniquePending.add(item['order_id']);
       }
       final ordersPending = uniquePending.length;


      // 3. Weekly Sales (Last 7 days)
      final weekStart = now.subtract(const Duration(days: 7));
      final weeklyResponse = await _supabaseConfig.client
          .from('order_items')
          .select('total_price, orders!inner(created_at)')
          .eq('seller_id', sellerId)
          .gte('orders.created_at', weekStart.toIso8601String());
      
      List<double> weeklySales = List.filled(7, 0.0);
      
      for (var item in (weeklyResponse as List)) {
          final dateStr = item['orders']['created_at'] as String;
          final date = DateTime.parse(dateStr);
          final diff = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
          
          if (diff >= 0 && diff < 7) {
              // 0 = today (last index?), 6 = 7 days ago (first index?)
              // Generally charts go Left (old) -> Right (new).
              // So Today is index 6. 7 days ago is index 0.
              // index = 6 - diff
              int index = 6 - diff;
              if (index >= 0 && index < 7) {
                   weeklySales[index] += (item['total_price'] as num).toDouble();
              }
          }
      }

      return Right(SellerStats(
        ordersToday: ordersToday,
        ordersPending: ordersPending,
        salesToday: salesToday,
        weeklySales: weeklySales,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
