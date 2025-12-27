import 'dart:convert';

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double total;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime createdAt;
  final ShippingInfo shippingInfo;
  final PaymentInfo paymentInfo;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.shippingInfo,
    required this.paymentInfo,
  });

  // The copyWith method allows you to "change" a value by creating a new instance
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? total,
    String? status,
    DateTime? createdAt,
    ShippingInfo? shippingInfo,
    PaymentInfo? paymentInfo,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  // Helper methods for JSON conversion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'total': total,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'shippingInfo': shippingInfo.toMap(),
      'paymentInfo': paymentInfo.toMap(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<OrderItem>.from(map['items']?.map((x) => OrderItem.fromMap(x))),
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      shippingInfo: ShippingInfo.fromMap(map['shippingInfo']),
      paymentInfo: PaymentInfo.fromMap(map['paymentInfo']),
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
    );
  }
}

class ShippingInfo {
  final String name;
  final String address;
  final String phone;

  ShippingInfo({
    required this.name,
    required this.address,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
    };
  }

  factory ShippingInfo.fromMap(Map<String, dynamic> map) {
    return ShippingInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}

class PaymentInfo {
  final String method;
  final String maskedNumber;

  PaymentInfo({
    required this.method,
    required this.maskedNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'maskedNumber': maskedNumber,
    };
  }

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      method: map['method'] ?? '',
      maskedNumber: map['maskedNumber'] ?? '',
    );
  }
}