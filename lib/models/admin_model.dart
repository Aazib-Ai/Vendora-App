class Admin {
  final String id;
  final String name;
  final String email;
  final String password; // masked in UI
  final String role; // 'admin', 'super_admin'
  final String? profileImageUrl;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.profileImageUrl,
  });
}

