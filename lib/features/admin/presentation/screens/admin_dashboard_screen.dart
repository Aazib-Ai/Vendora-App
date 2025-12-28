import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/features/admin/presentation/screens/admin_dashboard_tab.dart';
import 'package:vendora/features/admin/presentation/screens/admin_profile_screen.dart';
import 'package:vendora/features/admin/presentation/screens/analytics_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  // List of screens corresponding to the bottom navigation bar items
  final List<Widget> _screens = const [
    AdminDashboardTab(),        // Index 0: Dashboard
    UserManagementScreen(),     // Index 1: Users
    SizedBox.shrink(),          // Index 2: Placeholder for Logo Button (navigates to Dashboard)
    AnalyticsScreen(),          // Index 3: Analytics
    AdminProfileScreen(),       // Index 4: Profile
  ];

  void _onNavTap(int index) {
    setState(() {
      // If the logo button (index 2) is tapped, go to Dashboard (index 0)
      if (index == 2) {
        _currentIndex = 0;
      } else {
        _currentIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
