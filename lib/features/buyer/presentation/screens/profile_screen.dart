import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.3,
        foregroundColor: Colors.black,
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ---------------- PROFILE HEADER ----------------
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              final userName = user?.name ?? "Guest";
              final userEmail = user?.email ?? "";
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.black,
                      backgroundImage: user?.profileImageUrl != null
                          ? NetworkImage(user!.profileImageUrl!)
                          : null,
                      child: user?.profileImageUrl == null
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : "G",
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // ---------------- ACCOUNT SECTION ----------------
          _sectionTitle("Account"),

          _profileTile(
            icon: Icons.person_outline,
            label: "Edit Profile",
            onTap: () => _openEditProfileModal(),
          ),

          _profileTile(
            icon: Icons.settings_outlined,
            label: "Settings",
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),

          const SizedBox(height: 20),

          // ---------------- SUPPORT SECTION ----------------
          _sectionTitle("Support"),

          _profileTile(
            icon: Icons.help_outline,
            label: "Help Center",
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpCenter),
          ),

          _profileTile(
            icon: Icons.mail_outline,
            label: "Contact Us",
            onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
          ),

          _profileTile(
            icon: Icons.report_problem_outlined,
            label: "Report a Problem",
            onTap: () => Navigator.pushNamed(context, AppRoutes.reportProblem),
          ),

          const SizedBox(height: 20),

          // ---------------- SELLER SECTION ----------------
          _sectionTitle("Seller"),

          _profileTile(
            icon: Icons.storefront_outlined,
            label: "Login as Seller",
            subtitle: "Access your seller dashboard",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.login, arguments: "seller");
            },
          ),

          const SizedBox(height: 20),

          // ---------------- LOGOUT SECTION ----------------
          _sectionTitle("Security"),

          _profileTile(
          icon: Icons.lock_outline,
          label: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
        ),
        const SizedBox(height: 24),
        _logoutTile(
            icon: Icons.logout,
            label: "Logout",
            onTap: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ==========================================================
  // NORMAL TILE
  // ==========================================================
  Widget _profileTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ==========================================================
  // LOGOUT TILE
  // ==========================================================
  Widget _logoutTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.red.shade100,
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ==========================================================
  // EDIT PROFILE MODAL (BOTTOM SHEET)
  // ==========================================================
  void _openEditProfileModal() {
    final user = context.read<AuthProvider>().currentUser;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final addressCtrl = TextEditingController(text: user?.address ?? '');

    showModalBottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      context: context,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              _editField("Name", nameCtrl),
              const SizedBox(height: 12),

              _editField("Email", emailCtrl, enabled: false),
              const SizedBox(height: 12),

              _editField("Phone Number", phoneCtrl),
              const SizedBox(height: 12),

              _editField("Address", addressCtrl),
              const SizedBox(height: 20),

              // SAVE BUTTON
              GestureDetector(
                onTap: () {
                  // TODO: Implement profile update via repository
                  // For now, just close the modal
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile update coming soon!')),
                  );
                  Navigator.pop(modalContext);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Reusable modal field
  Widget _editField(String hint, TextEditingController controller, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade200 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(40),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }
}
