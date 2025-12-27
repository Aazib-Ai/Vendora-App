import 'package:equatable/equatable.dart';

/// Review model for product reviews
class Review extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String orderId;
  final int rating;
  final String? comment;
  final String? sellerReply;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.rating,
    this.comment,
    this.sellerReply,
    required this.createdAt,
  });

  /// Check if rating is valid (1-5 stars)
  bool get isValidRating => rating >= 1 && rating <= 5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
      'seller_reply': sellerReply,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      orderId: json['order_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      sellerReply: json['seller_reply'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Review copyWith({
    String? id,
    String? userId,
    String? productId,
    String? orderId,
    int? rating,
    String? comment,
    String? sellerReply,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      sellerReply: sellerReply ?? this.sellerReply,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        orderId,
        rating,
        comment,
        sellerReply,
        createdAt,
      ];
}
