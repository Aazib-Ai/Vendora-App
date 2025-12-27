import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/core/theme/app_theme.dart';
import 'package:vendora/core/theme/theme_provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  final supabaseConfig = SupabaseConfig();
  await supabaseConfig.initialize();

  // Initialize Cache Service
  final cacheService = CacheService();
  await cacheService.init();

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
      ],
      child: const VendoraApp(),
    ),
  );
}

class VendoraApp extends StatelessWidget {
  const VendoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
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
