/// Category model for product categorization
class Category {
  final String id;
  final String sellerId;
  final String name;
  final String? iconUrl;
  final int productCount;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.sellerId,
    required this.name,
    this.iconUrl,
    this.productCount = 0,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      productCount: json['product_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'icon_url': iconUrl,
      'product_count': productCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? iconUrl,
    int? productCount,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
