import 'package:flutter/material.dart';
import 'package:vendora/core/routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [


              // ---------- LOGO (Image from assets) ----------
              Transform.translate(
                offset: const Offset(-4, 0),
                child: Image.asset(
                  "assets/images/vendora_logo.png",
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Continue as",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // Buyer Button
              _RoleButton(
                title: 'Buyer',
                subtitle: 'to buy goods',
                imagePath: 'assets/images/buyer.png',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.login, arguments: "buyer");
                },
              ),

              const SizedBox(height: 20),

              // Seller Button
              _RoleButton(
                title: 'Seller',
                subtitle: 'to sell goods',
                imagePath: 'assets/images/seller.png',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.login, arguments: "seller");
                },
              ),

              const SizedBox(height: 20),

              // Admin Button
              _RoleButton(
                title: 'Admin',
                subtitle: 'to manage app',
                imagePath: 'assets/images/admin.png',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.login, arguments: "admin");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            // Left Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Right Image Icon
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
