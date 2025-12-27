import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/theme/app_theme.dart';
import 'package:vendora/core/theme/theme_provider.dart';
import 'package:vendora/core/routes/app_routes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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

          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
