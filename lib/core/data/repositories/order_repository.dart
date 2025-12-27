import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../../../models/order.dart';
import '../../../../features/seller/data/models/seller_stats.dart';

/// Abstract interface for order operations
/// Defines contract for order repository implementations
abstract class IOrderRepository {
  /// Create a new order with pending status
  /// Requirements: 7.1
  Future<Either<Failure, Order>> createOrder({
    required String userId,
    required String addressId,
    required List<OrderItem> items,
    required String paymentMethod,
  });

  /// Get a single order by ID
  /// Requirements: 7.7
  Future<Either<Failure, Order>> getOrderById(String id);

  /// Get all orders for a user
  /// Requirements: 7.7
  Future<Either<Failure, List<Order>>> getUserOrders(String userId);

  /// Update order status with state machine validation
  /// Requirements: 7.3, 7.4, 7.5, 7.6
  Future<Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNumber,
  });

  /// Get orders containing seller's products
  /// Requirements: 7.8
  Future<Either<Failure, List<Order>>> getSellerOrders(String sellerId);

  /// Get seller dashboard stats
  /// Requirements: 18.2
  Future<Either<Failure, SellerStats>> getSellerStats(String sellerId);
}

/// Concrete implementation of order repository using Supabase
/// Handles order creation with stock decrement and status updates
class OrderRepository implements IOrderRepository {
  final SupabaseConfig _supabaseConfig;

  OrderRepository({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, Order>> createOrder({
    required String userId,
    required String addressId,
    required List<OrderItem> items,
    required String paymentMethod,
  }) async {
    try {
      // Calculate order totals
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.quantity * item.unitPrice),
      );
      final platformCommission = subtotal * 0.10; // 10% commission
      final total = subtotal;

      // Create order
      final orderData = {
        'user_id': userId,
        'address_id': addressId,
        'status': OrderStatus.pending.name,
        'subtotal': subtotal,
        'platform_commission': platformCommission,
        'total': total,
        'payment_method': paymentMethod,
        'created_at': DateTime.now().toIso8601String(),
      };

      final orderResponse = await _supabaseConfig
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // Create order items and decrement stock
      for (final item in items) {
        // Insert order item
        await _supabaseConfig.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.quantity * item.unitPrice,
          'seller_id': item.sellerId, // Ensure sellerId is passed
        });

        // Decrement product stock using RPC for atomic operation
        await _supabaseConfig.client.rpc(
          'decrement_product_stock',
          params: {
            'product_id': item.productId,
            'quantity': item.quantity,
          },
        );
      }

      // Create order status history entry
      await _supabaseConfig.from('order_status_history').insert({
        'order_id': orderId,
        'status': OrderStatus.pending.name,
        'note': 'Order created',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Fetch complete order with items
      final order = await getOrderById(orderId);
      return order;
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id) async {
    try {
      final response = await _supabaseConfig.from('orders').select('''
        *,
        order_items(
          id,
          order_id,
          product_id,
          product_name,
          quantity,
          unit_price,
          total_price,
          seller_id
        ),
        order_status_history(
          id,
          order_id,
          status,
          note,
          created_at
        )
      ''').eq('id', id).single();

      final order = Order.fromJson(response);
      return Right(order);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left(NotFoundFailure('Order not found'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getUserOrders(String userId) async {
    try {
      final response = await _supabaseConfig.from('orders').select('''
        *,
        order_items(
          id,
          order_id,
          product_id,
          product_name,
          quantity,
          unit_price,
          total_price,
          seller_id
        ),
        order_status_history(
          id,
          order_id,
          status,
          note,
          created_at
        )
      ''').eq('user_id', userId).order('created_at', ascending: false);

      final orders = (response as List)
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(orders);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNumber,
  }) async {
    try {
      // Fetch current order to validate state transition
      final currentOrderResult = await getOrderById(orderId);
      if (currentOrderResult.isLeft()) {
        return currentOrderResult;
      }

      final currentOrder = currentOrderResult.getOrElse(() => throw Exception());
      
      // Validate state transition
      if (!currentOrder.canTransitionTo(newStatus)) {
         return Left(ValidationFailure(
          'Cannot transition from ${currentOrder.status.name} to ${newStatus.name}',
        ));
      }

      // Update order
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (trackingNumber != null) {
        updates['tracking_number'] = trackingNumber;
      }

      if (newStatus == OrderStatus.delivered) {
        updates['delivered_at'] = DateTime.now().toIso8601String();
      }

      await _supabaseConfig
          .from('orders')
          .update(updates)
          .eq('id', orderId);

      // Create status history entry
      await _supabaseConfig.from('order_status_history').insert({
        'order_id': orderId,
        'status': newStatus.name,
        'note': 'Status updated to ${newStatus.name}',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Fetch updated order
      final updatedOrder = await getOrderById(orderId);
      return updatedOrder;
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getSellerOrders(String sellerId) async {
    try {
      // Query orders that contain items from this seller
      final response = await _supabaseConfig.from('orders').select('''
        *,
        order_items!inner(
          id,
          order_id,
          product_id,
          product_name,
          quantity,
          unit_price,
          total_price,
          seller_id
        ),
        order_status_history(
          id,
          order_id,
          status,
          note,
          created_at
        )
      ''').eq('order_items.seller_id', sellerId).order(
        'created_at',
        ascending: false,
      );

      final orders = (response as List)
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(orders);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerStats>> getSellerStats(String sellerId) async {
    try {
      // Get all orders for this seller
      // Note: In a real app this should be optimized with a database view or function
      final ordersResult = await getSellerOrders(sellerId);
      
      return ordersResult.fold(
        (failure) => Left(failure),
        (orders) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          double totalSalesToday = 0;
          int pendingOrdersCount = 0;
          Map<String, int> productCounts = {};
          Map<int, double>  weeklySalesMap = {}; // Key: day difference

          // Initialize weekly sales map for last 7 days including today
          for (int i = 0; i < 7; i++) {
            weeklySalesMap[i] = 0;
          }

          for (final order in orders) {
            // Pending Orders
            if (order.status == OrderStatus.pending) {
              // We count the order as pending if ANY item belongs to seller
              // A refinement would be ensuring the seller hasn't fulfilled their part
              pendingOrdersCount++;
            }

            // Sales Calculations
            // Since an order can have items from multiple sellers, we must sum only our items
            double orderTotalForSeller = 0;
            for (final item in order.items) {
              if (item.sellerId == sellerId) {
                // Count product popularity
                productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity;
                orderTotalForSeller += item.totalPrice;
              }
            }
            
            // Stats based on created_at
            final orderDate = order.createdAt;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final differenceInDays = today.difference(orderDay).inDays;

            if (differenceInDays == 0) {
              totalSalesToday += orderTotalForSeller;
            }

            if (differenceInDays >= 0 && differenceInDays < 7) {
              weeklySalesMap[differenceInDays] = (weeklySalesMap[differenceInDays] ?? 0) + orderTotalForSeller;
            }
          }

          // Format Weekly Sales
          List<SalesPoint> weeklySales = [];
          for (int i = 6; i >= 0; i--) {
             final date = today.subtract(Duration(days: i));
             weeklySales.add(SalesPoint(date, weeklySalesMap[i] ?? 0));
          }

          // Top Products
          final sortedProducts = productCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final topProducts = sortedProducts
              .take(5)
              .map((e) => TopProduct(e.key, e.value))
              .toList();

          return Right(SellerStats(
            totalSalesToday: totalSalesToday,
            pendingOrdersCount: pendingOrdersCount,
            weeklySales: weeklySales,
            topProducts: topProducts,
            recentOrders: orders.take(5).toList(),
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
