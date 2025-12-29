import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep links for Supabase Auth (email verification, password reset).
/// 
/// For email verification:
/// - Same device: Deep link opens app, session is auto-refreshed
/// - Different device: User manually taps "I've Verified" button
/// 
/// The deep link scheme is: io.supabase.vendora://
class DeepLinkService {
  final SupabaseConfig _supabaseConfig;
  final AppLinks _appLinks = AppLinks();
  
  StreamSubscription<Uri>? _linkSubscription;
  final _deepLinkController = StreamController<Uri>.broadcast();
  
  /// Stream of deep link URIs that can be listened to
  Stream<Uri> get deepLinkStream => _deepLinkController.stream;
  
  DeepLinkService(this._supabaseConfig);
  
  Uri? _pendingInitialLink;
  Uri? get pendingInitialLink => _pendingInitialLink;

  void clearPendingLink() => _pendingInitialLink = null;

  /// Flag to indicate if a password reset deep link is being processed.
  /// Used by SplashScreen to avoid auto-navigating away.
  bool _isInPasswordResetMode = false;
  bool get isInPasswordResetMode => _isInPasswordResetMode;
  
  void setPasswordResetMode(bool value) {
    _isInPasswordResetMode = value;
    if (kDebugMode) {
      print('DeepLinkService: Password reset mode set to: $value');
    }
  }

  /// Initialize the deep link listener.
  /// Call this once in main() after Supabase is initialized.
  Future<void> initialize() async {
    // Handle initial link (app was opened via deep link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _pendingInitialLink = initialLink;
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Error getting initial link: $e');
      }
    }
    
    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        if (kDebugMode) {
          print('DeepLinkService: Error in link stream: $error');
        }
      },
    );
    
    if (kDebugMode) {
      print('DeepLinkService: Initialized and listening for deep links');
    }
  }
  
  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    if (kDebugMode) {
      print('DeepLinkService: Received deep link: $uri');
    }
    
    if (isPasswordResetCallback(uri)) {
      await _handlePasswordResetCallback(uri);
      _deepLinkController.add(uri);
      return;
    }
    if (uri.host == 'login-callback' || uri.path.contains('login-callback')) {
      await _handleAuthCallback(uri);
      _deepLinkController.add(uri);
    } else if (uri.host == 'reset-callback' || uri.path.contains('reset-callback')) {
      await _handlePasswordResetCallback(uri);
      _deepLinkController.add(uri);
    } else {
      _deepLinkController.add(uri);
    }
  }
  
  /// Handle Supabase auth callback (email verification, magic link)
  Future<void> _handleAuthCallback(Uri uri) async {
    try {
      // The fragment contains the tokens: #access_token=...&refresh_token=...
      final fragment = uri.fragment;
      if (fragment.isEmpty) {
        if (kDebugMode) {
          print('DeepLinkService: Auth callback has no fragment');
        }
        return;
      }
      
      // Parse fragment as query params
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'];
      final type = params['type']; // 'signup', 'recovery', 'magiclink'
      
      if (kDebugMode) {
        print('DeepLinkService: Auth type: $type');
      }
      
      if (accessToken != null && refreshToken != null) {
        // Set the session with the tokens from the deep link
        await _supabaseConfig.auth.setSession(refreshToken);
        
        if (kDebugMode) {
          print('DeepLinkService: Session set successfully for type: $type');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Error handling auth callback: $e');
      }
    }
  }
  
  Future<void> _handlePasswordResetCallback(Uri uri) async {
    // Set the flag to prevent SplashScreen from auto-navigating
    setPasswordResetMode(true);
    try {
      // Check for code in query params (PKCE flow)
      final code = uri.queryParameters['code'];
      if (code != null) {
        if (kDebugMode) {
          print('DeepLinkService: Exchanging code for session...');
        }
        await _supabaseConfig.auth.exchangeCodeForSession(code);
        if (kDebugMode) {
          print('DeepLinkService: Code exchanged successfully');
        }
        return;
      }

      // Check for fragment (Implicit flow)
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        final params = Uri.splitQueryString(fragment);
        final accessToken = params['access_token'];
        final refreshToken = params['refresh_token'];
        
        if (accessToken != null && refreshToken != null) {
          await _supabaseConfig.auth.setSession(refreshToken);
          
          if (kDebugMode) {
            print('DeepLinkService: Password reset session set from fragment');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Error handling password reset callback: $e');
      }
    }
  }
  
  /// Check if a deep link is an auth callback
  bool isAuthCallback(Uri uri) {
    if (isPasswordResetCallback(uri)) return false;

    return uri.host == 'login-callback' || 
           uri.path.contains('login-callback') ||
           uri.fragment.contains('access_token');
  }
  
  /// Check if a deep link is a password reset callback
  bool isPasswordResetCallback(Uri uri) {
    return uri.host == 'reset-callback' || 
           uri.path.contains('reset-callback') ||
           uri.queryParameters.containsKey('code') ||
           (uri.fragment.contains('type=recovery'));
  }
  
  /// Dispose of resources
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
