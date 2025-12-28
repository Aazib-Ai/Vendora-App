import 'package:equatable/equatable.dart';

/// Cart item entity representing a product in the user's cart
class CartItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final String sellerId;
  final DateTime createdAt;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    required this.sellerId,
    required this.createdAt,
  });

  /// Calculate total price for this item (quantity * unitPrice)
  double get total => quantity * unitPrice;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    
    String extractedProductName;
    double extractedUnitPrice;
    String extractedSellerId;
    String? extractedImageUrl;

    if (product != null && product is Map) {
       // Nested structure from Supabase join
       extractedProductName = product['name'] as String? ?? 'Unknown Product';
       extractedUnitPrice = (product['base_price'] as num?)?.toDouble() ?? 0.0;
       extractedSellerId = product['seller_id'] as String? ?? '';
       
       final images = product['product_images'] as List?;
       if (images != null && images.isNotEmpty) {
         extractedImageUrl = images[0]['url'] as String?;
       }
    } else {
       // Flat structure or legacy
       extractedProductName = json['product_name'] as String? ?? 'Unknown Product';
       extractedUnitPrice = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
       extractedSellerId = json['seller_id'] as String? ?? '';
       extractedImageUrl = json['image_url'] as String?;
    }

    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      productName: extractedProductName,
      quantity: json['quantity'] as int,
      unitPrice: extractedUnitPrice,
      imageUrl: extractedImageUrl,
      sellerId: extractedSellerId,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'image_url': imageUrl,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    String? imageUrl,
    String? sellerId,
    DateTime? createdAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productName,
        quantity,
        unitPrice,
        imageUrl,
        sellerId,
        createdAt,
      ];
}
