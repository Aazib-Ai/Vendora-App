import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/widgets/custom_button.dart';
import 'package:vendora/core/widgets/vendora_logo.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/core/routes/app_routes.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  
  const EmailVerificationScreen({super.key, this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> 
    with SingleTickerProviderStateMixin {
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendEmail() async {
    final authProvider = context.read<AuthProvider>();
    final email = widget.email ?? authProvider.apiUser?.email;

    if (email == null) return;

    setState(() => _isResending = true);
    
    final success = await authProvider.resendVerificationEmail(email);

    if (mounted) {
      setState(() => _isResending = false);
      if (success) {
        _startCooldown();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Verification email sent! Check your inbox.' 
            : 'Failed to send email. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.reloadUser();
    
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (authProvider.isEmailVerified && authProvider.hasActiveSession) {
      // User verified and session exists - navigate to home
      final route = authProvider.getHomeRouteForRole();
      Navigator.pushReplacementNamed(context, route);
    } else if (!authProvider.hasActiveSession) {
      // No active session - verification might have happened on different device
      // Redirect to login so user can sign in with verified email
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Great! Please sign in with your verified email.'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      // Session exists but email not verified yet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email not verified yet. Please check your inbox and spam folder.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final displayEmail = widget.email ?? authProvider.apiUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              
              // Animated Mail Icon
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_bounceAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'We\'ve sent a verification link to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'What to do next:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Check your email inbox (and spam folder)'),
                    _buildStep('2', 'Click the verification link in the email'),
                    _buildStep('3', 'On this device? App opens automatically'),
                    _buildStep('4', 'Different device? Come back here and tap the button below'),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Verify Button
              CustomButton(
                text: _isChecking ? 'Checking...' : 'I\'ve Verified My Email',
                onPressed: _isChecking ? null : _checkVerificationStatus,
                isLoading: _isChecking,
              ),
              
              const SizedBox(height: 16),
              
              // Resend Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (_isResending || _resendCooldown > 0) ? null : _handleResendEmail,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: _resendCooldown > 0 ? Colors.grey.shade300 : Colors.green,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResending 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : Text(
                        _resendCooldown > 0 
                          ? 'Resend in ${_resendCooldown}s' 
                          : 'Resend Verification Email',
                        style: TextStyle(
                          color: _resendCooldown > 0 ? Colors.grey : Colors.green.shade700,
                        ),
                      ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Back to Login
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: Text(
                  'Use a different account',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
