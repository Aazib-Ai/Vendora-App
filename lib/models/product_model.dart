class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final Map<String, String> specifications;
  final String sellerId;
  final String status; // 'approved', 'pending', 'rejected'

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.specifications,
    required this.sellerId,
    this.status = 'approved',
  });

  String get formattedPrice => 'Rs ${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

