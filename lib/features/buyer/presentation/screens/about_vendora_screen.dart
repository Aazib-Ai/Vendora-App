import 'package:flutter/material.dart';

class AboutVendoraScreen extends StatelessWidget {
  const AboutVendoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPurple = theme.colorScheme.primary.value == const Color(0xFF3A2AD8).value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.primary,
        title: const Text(
          "About Vendora",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---------------------------
            // MAIN INFO CARD
            // ---------------------------
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isPurple ? const Color(0xFF3A2AD8) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vendora Marketplace",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isPurple ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Vendora is a modern multi-vendor marketplace app built to connect buyers "
                        "and sellers seamlessly. Discover products, manage stores, track orders, "
                        "and enjoy a smooth shopping experience — all inside one platform.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isPurple ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ---------------------------
            // VERSION CARD
            // ---------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPurple ? const Color(0xFF3A2AD8) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isPurple ? Colors.white24 : Colors.black12,
                    child: Icon(
                      Icons.info_outline,
                      color: isPurple ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "App Version",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isPurple ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "1.0.0",
                        style: TextStyle(
                          fontSize: 13,
                          color: isPurple ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ---------------------------
            // FOOTER TEXT
            // ---------------------------
            Text(
              "© 2025 Vendora • All Rights Reserved",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPurple ? Colors.black87 : Colors.black45,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
