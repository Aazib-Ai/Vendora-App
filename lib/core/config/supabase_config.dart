import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_constants.dart';

/// Supabase configuration singleton with connection retry logic
/// Implements exponential backoff for connection failures
class SupabaseConfig {
  static final SupabaseConfig _instance = SupabaseConfig._internal();
  factory SupabaseConfig() => _instance;
  SupabaseConfig._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  /// Get the Supabase client instance
  SupabaseClient get client {
    if (_client == null || !_isInitialized) {
      throw Exception(
        'Supabase not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  bool get isInitialized => _isInitialized;

  /// Get auth client
  GoTrueClient get auth => client.auth;

  /// Get database client
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Get realtime client
  RealtimeClient get realtime => client.realtime;

  /// Get functions client  
  FunctionsClient get functions => client.functions;

  /// Get storage client
  SupabaseStorageClient get storage => client.storage;

  /// Initialize Supabase with connection retry logic
  /// Implements exponential backoff (1s, 2s, 4s) with max 3 attempts
  /// 
  /// Validates Requirements 1.1, 1.2
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('Supabase already initialized');
      }
      return;
    }

    // Load environment variables
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      throw Exception(
        'Failed to load .env file. Make sure .env exists and contains SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }

    // Initialize with retry logic
    await _initializeWithRetry(supabaseUrl, supabaseAnonKey);
  }

  /// Internal method to initialize with exponential backoff retry
  Future<void> _initializeWithRetry(String url, String anonKey) async {
    int attempts = 0;
    Duration delay = Duration(seconds: AppConstants.initialRetryDelaySeconds);
    Exception? lastException;

    while (attempts < AppConstants.maxRetryAttempts) {
      try {
        attempts++;
        
        if (kDebugMode) {
          print('Attempting to initialize Supabase (attempt $attempts/${AppConstants.maxRetryAttempts})');
        }

        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
          debug: kDebugMode,
        );

        _client = Supabase.instance.client;
        _isInitialized = true;

        if (kDebugMode) {
          print('✓ Supabase initialized successfully');
        }

        return; // Success - exit the retry loop
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (kDebugMode) {
          print('✗ Supabase initialization failed (attempt $attempts): $e');
        }

        if (attempts >= AppConstants.maxRetryAttempts) {
          // Max attempts reached - throw exception
          throw Exception(
            'Failed to initialize Supabase after ${AppConstants.maxRetryAttempts} attempts. '
            'Last error: ${lastException.toString()}',
          );
        }

        // Wait before next retry with exponential backoff
        if (kDebugMode) {
          print('Retrying in ${delay.inSeconds} seconds...');
        }
        
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff: 1s -> 2s -> 4s
      }
    }

    // This should never be reached, but just in case
    throw lastException ?? Exception('Unknown error during Supabase initialization');
  }

  /// Dispose the Supabase client (useful for tests)
  void dispose() {
    _client = null;
    _isInitialized = false;
  }

  /// Test helper to check connection
  Future<bool> testConnection() async {
    try {
      // Simple query to test connection
      await client.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Connection test failed: $e');
      }
      return false;
    }
  }
}
