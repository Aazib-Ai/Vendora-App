import 'package:flutter/material.dart';
import 'package:vendora/models/demo_data.dart';

// COMMON
import 'package:vendora/features/common/presentation/screens/splash_screen.dart';
import 'package:vendora/features/common/presentation/screens/onboarding_screen.dart';
import 'package:vendora/features/common/presentation/screens/role_selection_screen.dart';
import 'package:vendora/features/common/presentation/screens/login_screen.dart';
import 'package:vendora/features/common/presentation/screens/signup_screen.dart';
import 'package:vendora/features/common/presentation/screens/forgot_password_screen.dart';
import 'package:vendora/features/common/presentation/screens/reset_password_screen.dart';
import 'package:vendora/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:vendora/features/auth/presentation/screens/email_confirmed_screen.dart';

// BUYER
import 'package:vendora/features/buyer/presentation/screens/buyer_shell_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/home_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/product_details_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/cart_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/checkout_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/order_complete_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/profile_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/settings_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/help_center_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/contact_us_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/report_problem_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/notifications_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/about_vendora_screen.dart';

// SELLER
import 'package:vendora/features/seller/presentation/screens/dashboard_screen.dart';
import 'package:vendora/features/seller/presentation/screens/manage_categories_screen.dart'; // NEW
import 'package:vendora/features/seller/presentation/screens/manage_products_screen.dart';
import 'package:vendora/features/seller/presentation/screens/view_product_screen.dart';
import 'package:vendora/features/seller/presentation/screens/orders_screen.dart';
import 'package:vendora/features/seller/presentation/screens/sales_screen.dart';
import 'package:vendora/features/seller/presentation/screens/notifications_screen.dart';
import 'package:vendora/features/seller/presentation/screens/stats_screen.dart';
import 'package:vendora/features/seller/screens/seller_pending_screen.dart';

// ADMIN
import 'package:vendora/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_sellers_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_products_screen.dart' as admin;
import 'package:vendora/features/admin/presentation/screens/manage_users_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_admins_screen.dart';
import 'package:vendora/features/admin/presentation/screens/analytics_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_orders_screen.dart';
import 'package:vendora/features/admin/presentation/screens/dispute_center_screen.dart';

// REQUIRED MODEL
import 'package:vendora/models/product.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String emailVerification = '/email-verification';
  static const String emailConfirmed = '/email-confirmed';
  static const String adminLogin = '/admin-login';

  // Buyer Routes
  static const String buyerHome = '/buyer/home';
  static const String productDetails = '/buyer/product-details';
  static const String cart = '/buyer/cart';
  static const String checkout = '/buyer/checkout';
  static const String orderComplete = '/buyer/order-complete';
  static const String profile = '/buyer/profile';
  static const String settings = '/buyer/settings';
  static const String changePassword = '/change-password';
  static const String helpCenter = '/buyer/help-center';
  static const String contactUs = '/buyer/contact-us';
  static const String reportProblem = '/buyer/report-problem';
  static const String buyerNotifications = '/buyer/notifications';
  static const String aboutVendora = '/buyer/about-vendora';

  // Seller Routes
  static const String sellerDashboard = '/seller/dashboard';
  static const String addProduct = '/seller/add-product';
  static const String manageProducts = '/seller/manage-products';
  static const String manageCategories = '/seller/manage-categories'; // NEW
  static const String viewProduct = '/seller/view-product';
  static const String sellerOrders = '/seller/orders';
  static const String sales = '/seller/sales';
  static const String sellerNotifications = '/seller/notifications';
  static const String stats = '/seller/stats';
  static const String sellerPending = '/seller-pending';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String manageSellers = '/admin/manage-sellers';
  static const String adminManageProducts = '/admin/manage-products';
  static const String manageUsers = '/admin/manage-users';
  static const String manageAdmins = '/admin/manage-admins';
  static const String analytics = '/admin/analytics';
  static const String manageOrders = '/admin/manage-orders';
  static const String disputeCenter = '/admin/dispute-center';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: routeSettings);
      case adminLogin:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: const RouteSettings(arguments: 'admin'));
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case emailVerification:
        final email = routeSettings.arguments as String?;
        return MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email));
      case emailConfirmed:
        return MaterialPageRoute(builder: (_) => const EmailConfirmedScreen());

    // BUYER
      case buyerHome:
        return MaterialPageRoute(builder: (_) => const BuyerShellScreen());
      case productDetails:
        final product = routeSettings.arguments as Product;
        return MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product));
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case orderComplete:
        return MaterialPageRoute(builder: (_) => const OrderCompleteScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case contactUs:
        return MaterialPageRoute(builder: (_) => const ContactUsScreen());
      case reportProblem:
        return MaterialPageRoute(builder: (_) => const ReportProblemScreen());
      case buyerNotifications:
        return MaterialPageRoute(builder: (_) => const BuyerNotificationsScreen());
      case aboutVendora:
        return MaterialPageRoute(builder: (_) => const AboutVendoraScreen());

    // SELLER
      case sellerDashboard:
        return MaterialPageRoute(builder: (_) => const SellerDashboardScreen());
      case manageProducts:
        return MaterialPageRoute(builder: (_) => const ManageProductsScreen());
      case manageCategories: // NEW
        return MaterialPageRoute(builder: (_) => const ManageCategoriesScreen());
      case viewProduct:
        return MaterialPageRoute(builder: (_) => const ViewProductScreen());
      case sellerOrders:
        return MaterialPageRoute(builder: (_) => const SellerOrdersScreen());
      case sales:
        return MaterialPageRoute(builder: (_) => const SalesScreen());
      case sellerNotifications:
        return MaterialPageRoute(builder: (_) => const SellerNotificationsScreen());
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());
      case sellerPending:
        return MaterialPageRoute(builder: (_) => const SellerPendingScreen());

    // ADMIN
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case manageSellers:
        return MaterialPageRoute(builder: (_) => const ManageSellersScreen());
      case adminManageProducts:
        return MaterialPageRoute(builder: (_) => const admin.ManageProductsScreen());
      case manageUsers:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case manageAdmins:
        return MaterialPageRoute(builder: (_) => const ManageAdminsScreen());
      case analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      case manageOrders:
        return MaterialPageRoute(builder: (_) => const ManageOrdersScreen());
      case disputeCenter:
        return MaterialPageRoute(builder: (_) => const DisputeCenterScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text("No route defined for ${routeSettings.name}")),
          ),
        );
    }
  }
}