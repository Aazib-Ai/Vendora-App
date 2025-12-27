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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  final supabaseConfig = SupabaseConfig();
  await supabaseConfig.initialize();

  // Initialize Cache Service
  final cacheService = CacheService();
  await cacheService.init();

  // Create auth repository
  final authRepository = AuthRepository(supabaseConfig);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => auth.AuthProvider(authRepository),
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

          // 🔥 Dynamically switch theme based on toggle
          theme: themeProvider.isPurpleTheme
              ? AppTheme.purpleTheme.copyWith(
                  textTheme: GoogleFonts.poppinsTextTheme(),
                )
              : AppTheme.grayTheme.copyWith(
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
