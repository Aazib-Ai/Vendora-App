import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // -----------------------------
            // 🎨 Theme Toggle
            // -----------------------------
            _SettingsCardModern(
              icon: Icons.color_lens_outlined,
              title: "App Theme",
              subtitle: themeProvider.isPurpleTheme
                  ? "Vendora Purple Theme"
                  : "Vendora Gray Theme",
              trailing: Switch(
                value: themeProvider.isPurpleTheme,
                onChanged: (value) => themeProvider.togglePurpleTheme(value),
                activeColor: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 16),

            _SettingsCardModern(
              icon: Icons.person_outline,
              title: "Edit Profile",
              subtitle: "Update your name, email & password",
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            const SizedBox(height: 16),

            _SettingsCardModern(
              icon: Icons.help_outline,
              title: "Help Center",
              subtitle: "Find answers to your questions",
              onTap: () => Navigator.pushNamed(context, AppRoutes.helpCenter),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            const SizedBox(height: 16),

            _SettingsCardModern(
              icon: Icons.mail_outline,
              title: "Contact Us",
              subtitle: "Get support from Vendora Team",
              onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            const SizedBox(height: 16),

            _SettingsCardModern(
              icon: Icons.info_outline,
              title: "About Vendora",
              subtitle: "Learn more about the platform",
              onTap: () => Navigator.pushNamed(context, AppRoutes.aboutVendora),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------
// 💎 Modern Settings Card (Updated)
// --------------------------------------------------------------
class _SettingsCardModern extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsCardModern({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPurple = themeProvider.isPurpleTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPurple ? const Color(0xFF3A2AD8) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isPurple ? Colors.white24 : Colors.black12,
              child: Icon(icon,
                  color: isPurple ? Colors.white : Colors.black87),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPurple ? Colors.white : Colors.black,
                      )),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPurple ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
