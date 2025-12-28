import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/features/admin/presentation/screens/admin_overview_tab.dart';
import 'package:vendora/features/admin/presentation/screens/admin_profile_screen.dart';
import 'package:vendora/features/admin/presentation/screens/analytics_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_products_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Start with index 2 (AdminOverviewTab / Logo)
  int _currentIndex = 2;

  // List of screens for the shell
  final List<Widget> _screens = const [
    ManageProductsScreen(), // Index 0: Dashboard/Customize -> Manage Products
    UserManagementScreen(), // Index 1: People -> User Management
    AdminOverviewTab(),     // Index 2: Logo -> Overview Dashboard
    AnalyticsScreen(),      // Index 3: Analytics -> Analytics
    AdminProfileScreen(),   // Index 4: Person -> Profile & Settings
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // No AppBar here, each tab manages its own AppBar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.admin,
      ),
    );
  }
}
