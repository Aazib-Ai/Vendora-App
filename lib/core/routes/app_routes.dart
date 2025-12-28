import 'package:flutter/material.dart';
import 'package:vendora/models/demo_data.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/theme/theme_provider.dart';
import 'package:vendora/core/theme/app_theme.dart';
import 'package:vendora/core/config/supabase_config.dart';

// COMMON
import 'package:vendora/features/common/presentation/screens/splash_screen.dart';
import 'package:vendora/features/common/presentation/screens/onboarding_screen.dart';
import 'package:vendora/features/common/presentation/screens/role_selection_screen.dart';
import 'package:vendora/features/common/presentation/screens/login_screen.dart';
import 'package:vendora/features/common/presentation/screens/signup_screen.dart';
import 'package:vendora/features/common/presentation/screens/forgot_password_screen.dart';
import 'package:vendora/features/common/presentation/screens/reset_password_screen.dart';
import 'package:vendora/features/common/presentation/screens/change_password_screen.dart';
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
import 'package:vendora/features/common/presentation/screens/contact_us_screen.dart';
import 'package:vendora/features/common/presentation/screens/report_problem_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/notifications_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/about_vendora_screen.dart';
import 'package:vendora/features/buyer/presentation/screens/category_products_screen.dart';
import 'package:vendora/models/category_model.dart';

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
import 'package:vendora/features/admin/presentation/screens/admin_support_screen.dart';
import 'package:vendora/features/admin/presentation/screens/support_ticket_details_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_proposals_screen.dart';
import 'package:vendora/features/admin/presentation/screens/add_edit_proposal_screen.dart';
import 'package:vendora/models/proposal.dart';

// REQUIRED MODEL
import 'package:vendora/models/product.dart';
import 'package:vendora/features/common/data/models/support_ticket_model.dart';

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
  static const String buyerCategory = '/buyer/category';
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
  static const String adminSupport = '/admin/support';
  static const String adminTicketDetails = '/admin/ticket-details';
  static const String manageProposals = '/admin/manage-proposals';
  static const String editProposal = '/admin/edit-proposal';

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
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const BuyerShellScreen());
          },
        );
      case buyerCategory:
        final category = routeSettings.arguments as Category;
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(
              data: themeData,
              child: CategoryProductsScreen(category: category),
            );
          },
        );
      case productDetails:
        final product = routeSettings.arguments as Product;
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: ProductDetailsScreen(product: product));
          },
        );
      case cart:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const CartScreen());
          },
        );
      case checkout:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const CheckoutScreen());
          },
        );
      case orderComplete:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const OrderCompleteScreen());
          },
        );
      case profile:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const ProfileScreen());
          },
        );
      case settings:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const SettingsScreen());
          },
        );
      case changePassword:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const ChangePasswordScreen());
          },
        );
      case helpCenter:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const HelpCenterScreen());
          },
        );
      case contactUs:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const ContactUsScreen());
          },
        );
      case reportProblem:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const ReportProblemScreen());
          },
        );
      case buyerNotifications:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const BuyerNotificationsScreen());
          },
        );
      case aboutVendora:
        return MaterialPageRoute(
          builder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final themeData = themeProvider.isPurpleTheme
                ? AppTheme.purpleBuyerTheme
                : Theme.of(context);
            return Theme(data: themeData, child: const AboutVendoraScreen());
          },
        );

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
      case adminSupport:
        return MaterialPageRoute(builder: (_) => const AdminSupportScreen());
      case adminTicketDetails:
        final ticket = routeSettings.arguments as SupportTicket;
        return MaterialPageRoute(builder: (_) => AdminTicketDetailsScreen(ticket: ticket));
      case manageProposals:
        return MaterialPageRoute(builder: (_) => const ManageProposalsScreen());
      case editProposal:
        final proposal = routeSettings.arguments as Proposal?;
        return MaterialPageRoute(builder: (_) => AddEditProposalScreen(proposal: proposal));

      default:
        if (routeSettings.name?.startsWith('/?') == true) {
          final name = routeSettings.name!;
          return MaterialPageRoute(
            builder: (context) => _DeepLinkEntryScreen(initialRouteName: name),
          );
        }

        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text("No route defined for ${routeSettings.name}")),
          ),
        );
    }
  }
}

class _DeepLinkEntryScreen extends StatefulWidget {
  final String initialRouteName;
  const _DeepLinkEntryScreen({required this.initialRouteName});

  @override
  State<_DeepLinkEntryScreen> createState() => _DeepLinkEntryScreenState();
}

class _DeepLinkEntryScreenState extends State<_DeepLinkEntryScreen> {
  @override
  void initState() {
    super.initState();
    _processDeepLink();
  }

  Future<void> _processDeepLink() async {
    final name = widget.initialRouteName;
    final i = name.indexOf('?');
    final query = i >= 0 ? name.substring(i + 1) : '';
    String? code;
    if (query.isNotEmpty) {
      final params = Uri.splitQueryString(query);
      code = params['code'];
    }
    if (code != null && code.isNotEmpty) {
      try {
        await SupabaseConfig().auth.exchangeCodeForSession(code);
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.resetPassword);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
