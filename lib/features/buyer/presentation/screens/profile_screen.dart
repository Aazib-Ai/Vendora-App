import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/core/theme/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.3,
        foregroundColor: Theme.of(context).colorScheme.primary,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
            subtitle: "Update your name, email & password",
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
            subtitle: "Find answers to your questions",
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpCenter),
          ),

          _profileTile(
            icon: Icons.mail_outline,
            label: "Contact Us",
            subtitle: "Get support from Vendora Team",
            onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
          ),

          _profileTile(
            icon: Icons.report_problem_outlined,
            label: "Report a Problem",
            subtitle: "Found a bug? Let us know",
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ==========================================================
  // NORMAL TILE - Theme Aware (Like Settings Page)
  // ==========================================================
  // ==========================================================
  // NORMAL TILE - Theme Aware (Like Settings Page)
  // ==========================================================
  Widget _profileTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPurple = themeProvider.isPurpleTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPurple ? const Color(0xFF3A2AD8) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isPurple ? Colors.white24 : Colors.black12,
                  child: Icon(
                    icon,
                    color: isPurple ? Colors.white : Colors.black87,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isPurple ? Colors.white : Colors.black,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isPurple ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isPurple ? Colors.white : Colors.black54,
                ),
              ],
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.red.shade100,
                  child: Icon(icon, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              ElevatedButton(
                onPressed: () async {
                  final ok = await context.read<AuthProvider>().updateProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                  );
                  if (ok) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully')),
                      );
                    }
                    Navigator.pop(modalContext);
                  } else {
                    if (mounted) {
                      final err = context.read<AuthProvider>().errorMessage ?? 'Failed to update profile';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err)),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
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
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? null : Colors.grey.shade300,
      ),
    );
  }
}
