import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/core/theme/app_theme.dart';
import 'package:vendora/core/theme/theme_provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/services/deep_link_service.dart';
import 'package:vendora/features/auth/data/repositories/auth_repository.dart';
import 'package:vendora/core/services/cache_service.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart'
    as auth;
import 'package:vendora/core/data/repositories/cart_repository.dart';
import 'package:vendora/features/cart/presentation/providers/cart_provider.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/core/data/repositories/wishlist_repository.dart';
import 'package:vendora/features/buyer/presentation/providers/wishlist_provider.dart';
import 'package:vendora/core/data/repositories/review_repository.dart';
import 'package:vendora/features/buyer/presentation/providers/review_provider.dart';
import 'package:vendora/core/data/repositories/notification_repository.dart';
import 'package:vendora/features/common/presentation/providers/notification_provider.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/features/seller/presentation/providers/seller_dashboard_provider.dart';
import 'package:vendora/core/data/repositories/address_repository.dart';
import 'package:vendora/features/buyer/presentation/providers/address_provider.dart';
import 'package:vendora/core/data/repositories/order_repository.dart';
import 'package:vendora/features/buyer/presentation/providers/checkout_provider.dart';
import 'package:vendora/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:vendora/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:vendora/features/admin/presentation/providers/admin_seller_provider.dart';
import 'package:vendora/features/admin/presentation/providers/product_moderation_provider.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';
import 'package:vendora/core/data/repositories/category_repository.dart';
import 'package:vendora/features/seller/presentation/providers/category_provider.dart';
import 'package:vendora/features/admin/presentation/providers/admin_orders_provider.dart';
import 'package:vendora/features/admin/presentation/providers/dispute_provider.dart';
import 'package:vendora/features/admin/presentation/providers/admin_kyc_provider.dart';
import 'package:vendora/features/admin/presentation/providers/admin_kyc_provider.dart';
import 'package:vendora/services/image_upload_service.dart';
import 'package:vendora/features/common/data/repositories/support_repository.dart';
import 'package:vendora/features/common/presentation/providers/support_provider.dart';
import 'package:vendora/core/data/repositories/proposal_repository.dart';
import 'package:vendora/features/common/providers/proposal_provider.dart';

// ... existing imports ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    final supabaseConfig = SupabaseConfig();
    await supabaseConfig.initialize();

    // Initialize Cache Service
    final cacheService = CacheService();
    await cacheService.init();

    // Initialize Deep Link Service
    final deepLinkService = DeepLinkService(supabaseConfig);
    await deepLinkService.initialize();

    // Create repositories
    final authRepository = AuthRepository(supabaseConfig);
    final cartRepository = CartRepository(supabaseConfig: supabaseConfig);
    final productRepository = ProductRepository(supabaseConfig: supabaseConfig, cacheService: cacheService);
    final wishlistRepository = WishlistRepository(supabaseConfig: supabaseConfig);
    final reviewRepository = ReviewRepository(supabaseConfig: supabaseConfig);
    final notificationRepository = NotificationRepository(supabaseConfig: supabaseConfig);
    final addressRepository = AddressRepository(supabaseConfig: supabaseConfig);
    final sellerRepository = SellerRepository(supabaseConfig: supabaseConfig);
    final orderRepository = OrderRepository(supabaseConfig: supabaseConfig);
    final adminRepository = AdminRepositoryImpl(supabaseConfig: supabaseConfig);
    final categoryRepository = CategoryRepository(supabaseConfig: supabaseConfig);
    final supportRepository = SupportRepository(supabaseConfig.client);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => auth.AuthProvider(authRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => CartProvider(cartRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => WishlistProvider(
              wishlistRepository: wishlistRepository,
              productRepository: productRepository,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ReviewProvider(reviewRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationProvider(notificationRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => SellerDashboardProvider(
              sellerRepository: sellerRepository,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AddressProvider(addressRepository: addressRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => CheckoutProvider(
              orderRepository: orderRepository,
              cartRepository: cartRepository,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminDashboardProvider(adminRepository),
          ),
          // Provide ProductRepository for seller and buyer screens
          Provider<ProductRepository>.value(value: productRepository),
          // Provide OrderRepository for seller dashboard and other screens
          Provider<OrderRepository>.value(value: orderRepository),
          // Provide IImageUploadService for product and category image uploads
          Provider<IImageUploadService>(
            create: (_) => R2ImageUploadService(), // Use direct R2 upload
          ),
          // Provide CategoryRepository and CategoryProvider for seller category management
          Provider<CategoryRepository>.value(value: categoryRepository),
          ChangeNotifierProvider(
            create: (ctx) => CategoryProvider(
              categoryRepository: categoryRepository,
              imageUploadService: ctx.read<IImageUploadService>(),
            ),
          ),
          // Provide SellerRepository for seller profile operations
          Provider<SellerRepository>.value(value: sellerRepository),
          // Provide deep link service for navigation handling
          Provider<DeepLinkService>.value(value: deepLinkService),
          
          // Admin Providers
          Provider<IAdminRepository>.value(value: adminRepository),
          ChangeNotifierProvider(
            create: (_) => AdminSellerProvider(sellerRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => ProductModerationProvider(
              productRepository: productRepository,
              adminRepository: adminRepository,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminOrdersProvider(orderRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => DisputeProvider(adminRepository: adminRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminKYCProvider(sellerRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => SupportProvider(supportRepository),
          ),
          // Provide ProposalRepository and ProposalProvider
          Provider<ProposalRepository>(
            create: (_) => ProposalRepository(supabaseConfig: supabaseConfig),
          ),
          ChangeNotifierProvider(
            create: (ctx) => ProposalProvider(
              proposalRepository: ctx.read<ProposalRepository>(),
            ),
          ),
        ],
        child: VendoraApp(deepLinkService: deepLinkService),
      ),
    );
  } catch (e, stack) {
    debugPrint('Failed to initialize app: $e');
    debugPrint(stack.toString());
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text('Failed to initialize app:\n$e\n\nStack Trace:\n$stack'),
            ),
          ),
        ),
      ),
    ));
  }
}

class VendoraApp extends StatefulWidget {
  final DeepLinkService deepLinkService;
  
  const VendoraApp({super.key, required this.deepLinkService});

  @override
  State<VendoraApp> createState() => _VendoraAppState();
}

class _VendoraAppState extends State<VendoraApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    _deepLinkSubscription = widget.deepLinkService.deepLinkStream.listen((uri) {
      // When a deep link is received, check if it's an auth callback
      if (widget.deepLinkService.isAuthCallback(uri)) {
        // Auth callback processed by DeepLinkService, refresh auth state
        // and navigate to appropriate screen
        _handleAuthCallback();
      } else if (widget.deepLinkService.isPasswordResetCallback(uri)) {
        // Navigate to password reset screen
        // Remove until false effectively clears the stack (including splash)
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.resetPassword,
          (route) => false,
        );
      }
    });

    // Check for pending initial link (cold start)
    final pendingLink = widget.deepLinkService.pendingInitialLink;
    if (pendingLink != null) {
      if (widget.deepLinkService.isAuthCallback(pendingLink)) {
        _handleAuthCallback();
      } else if (widget.deepLinkService.isPasswordResetCallback(pendingLink)) {
        // Wait a small bit for navigator to be ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.resetPassword,
            (route) => false,
          );
        });
      }
      widget.deepLinkService.clearPendingLink();
    }
  }

  Future<void> _handleAuthCallback() async {
    // Wait a bit for the session to be set
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Get auth provider and check state
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null && navigatorContext.mounted) {
      final authProvider = Provider.of<auth.AuthProvider>(navigatorContext, listen: false);
      await authProvider.reloadUser();
      
      if (!mounted) return;
      
      if (authProvider.isEmailVerified) {
        final route = authProvider.getHomeRouteForRole();
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
      } else {
        // Show email confirmed screen (in case they clicked from different device browser)
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.emailConfirmed, 
          (_) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // 🎨 Select theme based on user preference
        final selectedTheme = themeProvider.isPurpleTheme 
            ? AppTheme.purpleBuyerTheme 
            : AppTheme.grayBuyerTheme;

        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Vendora',
          debugShowCheckedModeBanner: false,

          // 🔥 Apply theme dynamically based on ThemeProvider
          theme: selectedTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),

          themeMode: ThemeMode.light,

          // Use splash initially, which will check auth and navigate accordingly
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, child) {
            return WillPopScope(
              onWillPop: () async {
                final nav = _navigatorKey.currentState;
                if (nav != null && nav.canPop()) {
                  nav.pop();
                  return false;
                }
                return false;
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
