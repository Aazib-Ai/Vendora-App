class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String role; // 'buyer', 'seller', 'admin'
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    required this.role,
    this.profileImageUrl,
  });
}

