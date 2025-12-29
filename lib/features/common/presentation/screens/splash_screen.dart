import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/services/deep_link_service.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _fadeController.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Skip navigation if password reset deep link is being handled
    final deepLinkService = context.read<DeepLinkService>();
    if (deepLinkService.isInPasswordResetMode) {
      return; // Let the deep link handler navigate to reset password screen
    }

    final authProvider = context.read<AuthProvider>();
    
    // Wait for auth state to be determined, but also check for password reset mode
    while (authProvider.state == AuthState.initial || authProvider.state == AuthState.loading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      // Check flag again during wait - it might have been set
      if (deepLinkService.isInPasswordResetMode) {
        return;
      }
    }

    if (!mounted) return;
    
    // Final check before any navigation
    if (deepLinkService.isInPasswordResetMode) {
      return;
    }

    // Navigate based on authentication state
    if (authProvider.isAuthenticated) {
      // User is logged in
      if (!authProvider.isEmailVerified) {
        // Email not verified - go to verification screen
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.emailVerification,
          arguments: authProvider.apiUser?.email,
        );
      } else {
        // Email verified - go to appropriate home screen
        final route = authProvider.getHomeRouteForRole();
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      // Not authenticated - show onboarding first
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/vendora_logo.png',
                width: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                "Your Style, Delivered.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
