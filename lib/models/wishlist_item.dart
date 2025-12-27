import 'package:equatable/equatable.dart';

/// Wishlist item model
class WishlistItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final double priceAtAdd;
  final DateTime createdAt;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.priceAtAdd,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'price_at_add': priceAtAdd,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      priceAtAdd: (json['price_at_add'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? productId,
    double? priceAtAdd,
    DateTime? createdAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      priceAtAdd: priceAtAdd ?? this.priceAtAdd,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, productId, priceAtAdd, createdAt];
}
