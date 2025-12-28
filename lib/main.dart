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
import 'package:vendora/core/data/repositories/category_repository.dart';
import 'package:vendora/features/seller/presentation/providers/category_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          create: (_) => SellerDashboardProvider(sellerRepository),
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
        // Provide CategoryRepository and CategoryProvider for seller category management
        Provider<CategoryRepository>.value(value: categoryRepository),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryRepository: categoryRepository),
        ),
        // Provide SellerRepository for seller profile operations
        Provider<SellerRepository>.value(value: sellerRepository),
        // Provide deep link service for navigation handling
        Provider<DeepLinkService>.value(value: deepLinkService),
      ],
      child: VendoraApp(deepLinkService: deepLinkService),
    ),
  );
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
        _navigatorKey.currentState?.pushNamed(AppRoutes.resetPassword);
      }
    });
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
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Vendora',
          debugShowCheckedModeBanner: false,

          // 🔥 Apply theme
          theme: AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),

          themeMode: ThemeMode.light,

          // Use splash initially, which will check auth and navigate accordingly
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
