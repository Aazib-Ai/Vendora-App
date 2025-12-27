import 'package:flutter/material.dart';

enum NavigationRole { buyer, seller, admin }

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final NavigationRole role;
  final bool showNotifications;
  final int pendingOrdersCount; // Added for the badge logic

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = NavigationRole.buyer,
    this.showNotifications = false,
    this.pendingOrdersCount = 5, // Default mock value
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2727),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getButtonsByRole(context),
        ),
      ),
    );
  }

  // SWITCH BETWEEN ROLES
  List<Widget> _getButtonsByRole(BuildContext context) {
    switch (role) {
      case NavigationRole.seller:
        return _buildSellerButtons(context);
      case NavigationRole.admin:
        return _buildAdminButtons(context);
      default:
        return _buildBuyerButtons(context);
    }
  }

  // BUYER NAVIGATION SET
  List<Widget> _buildBuyerButtons(BuildContext context) {
    return [
      _navButton(index: 0, icon: Icons.notifications),
      _navButton(index: 1, icon: Icons.shopping_bag),
      _centerLogoButton(), // Home
      _navButton(index: 3, icon: Icons.settings),
      _navButton(index: 4, icon: Icons.person),
    ];
  }

  // SELLER NAVIGATION SET - UPDATED SEQUENCE
  List<Widget> _buildSellerButtons(BuildContext context) {
    return [
      _navButton(
        index: 0,
        icon: Icons.shopping_bag_outlined,
        hasBadge: true, // Enable badge for Orders
      ),
      _navButton(index: 1, icon: Icons.inventory_2_outlined), // Products
      _centerLogoButton(), // Dashboard (Index 2)
      _navButton(index: 3, icon: Icons.category_outlined), // Categories
      _navButton(index: 4, icon: Icons.person_outline), // Profile
    ];
  }

  // ADMIN NAVIGATION SET
  List<Widget> _buildAdminButtons(BuildContext context) {
    return [
      _navButton(index: 0, icon: Icons.dashboard_customize),
      _navButton(index: 1, icon: Icons.people),
      _centerLogoButton(),
      _navButton(index: 3, icon: Icons.analytics),
      _navButton(index: 4, icon: Icons.person_outline),
    ];
  }

  // ICON BUTTON WITH BADGE SUPPORT
  Widget _navButton({
    required int index,
    required IconData icon,
    bool hasBadge = false,
  }) {
    final bool isActive = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () => onTap(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3636),
              shape: BoxShape.circle,
              border: isActive ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          // RED BADGE FOR PENDING ORDERS
          if (hasBadge && pendingOrdersCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  '$pendingOrdersCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // CENTER LOGO BUTTON (same for all roles)
  Widget _centerLogoButton() {
    final bool isActive = currentIndex == 2;

    return InkWell(
      onTap: () => onTap(2),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3636),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : Colors.white54,
            width: 2,
          ),
        ),
        child: Center(
          child: Image.asset(
            "assets/images/v_logo.png",
            width: 34,
            height: 34,
            color: Colors.white,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}