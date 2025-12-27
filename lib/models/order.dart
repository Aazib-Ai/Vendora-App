import 'package:equatable/equatable.dart';
import '../core/errors/failures.dart';

/// Order status enumeration
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  String toJson() => name;

  static OrderStatus fromJson(String json) {
    return values.byName(json);
  }
}

/// Order State Machine that defines valid state transitions
class OrderStateMachine {
  /// Map of valid state transitions
  static const Map<OrderStatus, List<OrderStatus>> _transitions = {
    OrderStatus.pending: [OrderStatus.processing, OrderStatus.cancelled],
    OrderStatus.processing: [OrderStatus.shipped, OrderStatus.cancelled],
    OrderStatus.shipped: [OrderStatus.delivered],
    OrderStatus.delivered: [],
    OrderStatus.cancelled: [],
  };

  /// Check if transition from one status to another is valid
  static bool canTransition(OrderStatus from, OrderStatus to) {
    return _transitions[from]?.contains(to) ?? false;
  }

  /// Attempt to transition from current status to target status
  /// Returns the new status if successful, or a Failure if not
  static OrderStatus? transition(
    OrderStatus current,
    OrderStatus target,
  ) {
    if (canTransition(current, target)) {
      return target;
    }
    return null;
  }

  /// Get available transitions for a given status
  static List<OrderStatus> getAvailableTransitions(OrderStatus current) {
    return _transitions[current] ?? [];
  }
}

/// Order status history entry
class OrderStatusHistory extends Equatable {
  final String id;
  final String orderId;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;

  const OrderStatusHistory({
    required this.id,
    required this.orderId,
    required this.status,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status.name,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: OrderStatus.values.byName(json['status'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  OrderStatusHistory copyWith({
    String? id,
    String? orderId,
    OrderStatus? status,
    String? note,
    DateTime? createdAt,
  }) {
    return OrderStatusHistory(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, orderId, status, note, createdAt];
}

/// Order item model
class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String? variantId;
  final String sellerId;
  final String productName;
  final String? variantInfo;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.sellerId,
    required this.productName,
    this.variantInfo,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'variant_id': variantId,
      'seller_id': sellerId,
      'product_name': productName,
      'variant_info': variantInfo,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      sellerId: json['seller_id'] as String,
      productName: json['product_name'] as String,
      variantInfo: json['variant_info'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? variantId,
    String? sellerId,
    String? productName,
    String? variantInfo,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      sellerId: sellerId ?? this.sellerId,
      productName: productName ?? this.productName,
      variantInfo: variantInfo ?? this.variantInfo,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        variantId,
        sellerId,
        productName,
        variantInfo,
        quantity,
        unitPrice,
        totalPrice,
      ];
}

/// Complete Order model with state machine support
class Order extends Equatable {
  final String id;
  final String userId;
  final String addressId;
  final OrderStatus status;
  final double subtotal;
  final double platformCommission;
  final double total;
  final String paymentMethod;
  final String? trackingNumber;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.status,
    required this.subtotal,
    required this.platformCommission,
    required this.total,
    required this.paymentMethod,
    this.trackingNumber,
    this.deliveredAt,
    this.items = const [],
    this.statusHistory = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if order can be cancelled
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.processing;

  /// Check if order can be disputed
  bool get canDispute =>
      status == OrderStatus.delivered &&
      deliveredAt != null &&
      DateTime.now().difference(deliveredAt!).inDays <= 7;

  /// Check if order can transition to a specific status
  bool canTransitionTo(OrderStatus newStatus) {
    return OrderStateMachine.canTransition(status, newStatus);
  }

  /// Get available status transitions
  List<OrderStatus> get availableTransitions {
    return OrderStateMachine.getAvailableTransitions(status);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address_id': addressId,
      'status': status.name,
      'subtotal': subtotal,
      'platform_commission': platformCommission,
      'total': total,
      'payment_method': paymentMethod,
      'tracking_number': trackingNumber,
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      addressId: json['address_id'] as String,
      status: OrderStatus.values.byName(json['status'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      platformCommission: (json['platform_commission'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      trackingNumber: json['tracking_number'] as String?,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      items: (json['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statusHistory: (json['order_status_history'] as List<dynamic>?)
              ?.map((e) => OrderStatusHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? addressId,
    OrderStatus? status,
    double? subtotal,
    double? platformCommission,
    double? total,
    String? paymentMethod,
    String? trackingNumber,
    DateTime? deliveredAt,
    List<OrderItem>? items,
    List<OrderStatusHistory>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressId: addressId ?? this.addressId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      platformCommission: platformCommission ?? this.platformCommission,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      items: items ?? this.items,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        addressId,
        status,
        subtotal,
        platformCommission,
        total,
        paymentMethod,
        trackingNumber,
        deliveredAt,
        items,
        statusHistory,
        createdAt,
        updatedAt,
      ];
}
