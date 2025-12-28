import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/features/buyer/presentation/screens/cart_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/home_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/notifications_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/profile_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/settings_screen.dart';

class BuyerShellScreen extends StatefulWidget {
  const BuyerShellScreen({super.key});

  @override
  State<BuyerShellScreen> createState() => _BuyerShellScreenState();
}

class _BuyerShellScreenState extends State<BuyerShellScreen> {
  int _currentIndex = 2; // Start at Home (Index 2)

  // Using IndexedStack to preserve state of each tab
  final List<Widget> _screens = [
    const BuyerNotificationsScreen(),
    const CartScreen(isTab: true),
    const HomeScreen(),
    const SettingsScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.buyer,
        showNotifications: true, // Should probably be dynamic based on notification count
      ),
    );
  }
}
