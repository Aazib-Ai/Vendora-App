class Seller {
  final String id;
  final String name;
  final String email;
  final String businessCategory;
  final String address;
  final String? profileImageUrl;
  final String status; // 'approved', 'pending', 'rejected'
  final int totalProducts;
  final double totalSales;

  Seller({
    required this.id,
    required this.name,
    required this.email,
    required this.businessCategory,
    required this.address,
    this.profileImageUrl,
    this.status = 'pending',
    this.totalProducts = 0,
    this.totalSales = 0.0,
  });
}

