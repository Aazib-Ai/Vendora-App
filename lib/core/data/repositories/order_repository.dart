import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../../models/order_model.dart';

/// Order status enumeration matching database schema
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

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
        (sum, item) => sum + (item.quantity * item.price),
      );
      final platformCommission = subtotal * 0.10; // 10% commission
      final total = subtotal;

      // Create order
      final orderData = {
        'user_id': userId,
        'address_id': addressId,
        'status': 'pending',
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
          'unit_price': item.price,
          'total_price': item.quantity * item.price,
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
        'status': 'pending',
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
          product_id,
          product_name,
          quantity,
          unit_price,
          total_price
        ),
        order_status_history(
          status,
          note,
          created_at
        )
      ''').eq('id', id).single();

      final order = _parseOrder(response);
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
          product_id,
          product_name,
          quantity,
          unit_price,
          total_price
        )
      ''').eq('user_id', userId).order('created_at', ascending: false);

      final orders = (response as List)
          .map((json) => _parseOrder(json as Map<String, dynamic>))
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
      final currentStatus = OrderStatus.values.byName(currentOrder.status);

      // Validate state transition
      if (!_canTransition(currentStatus, newStatus)) {
        return Left(ValidationFailure(
          'Cannot transition from ${currentStatus.name} to ${newStatus.name}',
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
          product_id,
          product_name,
          quantity,
          unit_price,
          total_price,
          seller_id
        )
      ''').eq('order_items.seller_id', sellerId).order(
        'created_at',
        ascending: false,
      );

      final orders = (response as List)
          .map((json) => _parseOrder(json as Map<String, dynamic>))
          .toList();

      return Right(orders);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Order state machine transition validation
  /// Requirements: 7.3, 7.4, 7.5, 7.6
  bool _canTransition(OrderStatus from, OrderStatus to) {
    const transitions = {
      OrderStatus.pending: [OrderStatus.processing, OrderStatus.cancelled],
      OrderStatus.processing: [OrderStatus.shipped, OrderStatus.cancelled],
      OrderStatus.shipped: [OrderStatus.delivered],
      OrderStatus.delivered: <OrderStatus>[],
      OrderStatus.cancelled: <OrderStatus>[],
    };

    return transitions[from]?.contains(to) ?? false;
  }

  /// Helper method to parse order data from JSON
  Order _parseOrder(Map<String, dynamic> json) {
    // Parse order items
    final itemsData = json['order_items'] as List?;
    final items = itemsData?.map((item) {
      return OrderItem(
        productId: item['product_id'] as String,
        productName: item['product_name'] as String,
        quantity: item['quantity'] as int,
        price: (item['unit_price'] as num).toDouble(),
      );
    }).toList() ?? [];

    // Parse shipping info (for now using placeholder, would come from address table)
    final shippingInfo = ShippingInfo(
      name: '',
      address: '',
      phone: '',
    );

    // Parse payment info
    final paymentInfo = PaymentInfo(
      method: json['payment_method'] as String? ?? 'Cash on Delivery',
      maskedNumber: '',
    );

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      shippingInfo: shippingInfo,
      paymentInfo: paymentInfo,
    );
  }
}
