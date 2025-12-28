import 'package:equatable/equatable.dart';

/// Product status enumeration
enum ProductStatus {
  pending,
  approved,
  rejected,
  reported;

  String toJson() => name;

  static ProductStatus fromJson(String json) {
    return values.byName(json);
  }
}

/// Product image model
class ProductImage extends Equatable {
  final String id;
  final String productId;
  final String url;
  final int displayOrder;
  final bool isPrimary;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.url,
    required this.displayOrder,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'url': url,
      'display_order': displayOrder,
      'is_primary': isPrimary,
    };
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      url: json['url'] as String,
      displayOrder: json['display_order'] as int,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  ProductImage copyWith({
    String? id,
    String? productId,
    String? url,
    int? displayOrder,
    bool? isPrimary,
  }) {
    return ProductImage(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      url: url ?? this.url,
      displayOrder: displayOrder ?? this.displayOrder,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  List<Object?> get props => [id, productId, url, displayOrder, isPrimary];
}

/// Product variant model
class ProductVariant extends Equatable {
  final String id;
  final String productId;
  final String sku;
  final String? size;
  final String? color;
  final String? material;
  final double price;
  final int stockQuantity;
  final DateTime createdAt;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    this.size,
    this.color,
    this.material,
    required this.price,
    required this.stockQuantity,
    required this.createdAt,
  });

  /// Check if variant is out of stock
  bool get isOutOfStock => stockQuantity == 0;

  /// Check if variant is low on stock
  bool get isLowStock => stockQuantity > 0 && stockQuantity < 5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'sku': sku,
      'size': size,
      'color': color,
      'material': material,
      'price': price,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      sku: json['sku'] as String,
      size: json['size'] as String?,
      color: json['color'] as String?,
      material: json['material'] as String?,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ProductVariant copyWith({
    String? id,
    String? productId,
    String? sku,
    String? size,
    String? color,
    String? material,
    double? price,
    int? stockQuantity,
    DateTime? createdAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      size: size ?? this.size,
      color: color ?? this.color,
      material: material ?? this.material,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        sku,
        size,
        color,
        material,
        price,
        stockQuantity,
        createdAt,
      ];
}

/// Complete Product model with JSON serialization
class Product extends Equatable {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String name;
  final String description;
  final double basePrice;
  final double? discountPercentage;
  final DateTime? discountValidUntil;
  final int stockQuantity;
  final Map<String, dynamic> specifications;
  final ProductStatus status;
  final bool isActive;
  final double averageRating;
  final int reviewCount;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? sellerName;
  final String? categoryName;

  const Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    this.discountPercentage,
    this.discountValidUntil,
    required this.stockQuantity,
    this.specifications = const {},
    this.status = ProductStatus.pending,
    this.isActive = true,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.images = const [],
    this.variants = const [],
    required this.createdAt,
    this.updatedAt,
    this.sellerName,
    this.categoryName,
  });

  /// Calculate current price considering active discount
  double get currentPrice {
    if (discountPercentage != null &&
        discountValidUntil != null &&
        discountValidUntil!.isAfter(DateTime.now())) {
      return basePrice * (1 - discountPercentage! / 100);
    }
    return basePrice;
  }

  /// Check if product has active discount
  bool get hasActiveDiscount =>
      discountPercentage != null &&
      discountValidUntil != null &&
      discountValidUntil!.isAfter(DateTime.now());

  /// Check if product is low on stock
  bool get isLowStock => stockQuantity > 0 && stockQuantity < 5;

  /// Check if product is out of stock
  bool get isOutOfStock => stockQuantity == 0;

  /// Get primary image URL or null
  String? get primaryImageUrl {
    final primary = images.where((img) => img.isPrimary).firstOrNull;
    return primary?.url ?? images.firstOrNull?.url;
  }

  /// Compatibility getters
  String get category => categoryName ?? categoryId ?? '';
  
  double get price => basePrice;
  
  double get rating => averageRating;

  String get imageUrl => primaryImageUrl ?? '';
  
  String get formattedPrice => 'PKR ${basePrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'discount_percentage': discountPercentage,
      'discount_valid_until': discountValidUntil?.toIso8601String(),
      'stock_quantity': stockQuantity,
      'specifications': specifications,
      'status': status.name,
      'is_active': isActive,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      discountValidUntil: json['discount_valid_until'] != null
          ? DateTime.parse(json['discount_valid_until'] as String)
          : null,
      stockQuantity: json['stock_quantity'] as int,
      specifications: json['specifications'] != null
          ? Map<String, dynamic>.from(json['specifications'] as Map)
          : {},
      status: ProductStatus.values.byName(json['status'] as String),
      isActive: json['is_active'] as bool? ?? true,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      categoryName: json['categories'] != null ? json['categories']['name'] as String? : null,
      sellerName: json['sellers'] != null ? json['sellers']['business_name'] as String? : null,
      images: (json['product_images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      variants: (json['product_variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? categoryId,
    String? name,
    String? description,
    double? basePrice,
    double? discountPercentage,
    DateTime? discountValidUntil,
    int? stockQuantity,
    Map<String, dynamic>? specifications,
    ProductStatus? status,
    bool? isActive,
    double? averageRating,
    int? reviewCount,
    List<ProductImage>? images,
    List<ProductVariant>? variants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountValidUntil: discountValidUntil ?? this.discountValidUntil,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      specifications: specifications ?? this.specifications,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        categoryId,
        name,
        description,
        basePrice,
        discountPercentage,
        discountValidUntil,
        stockQuantity,
        specifications,
        status,
        isActive,
        averageRating,
        reviewCount,
        images,
        variants,
        createdAt,
        updatedAt,
      ];
}
