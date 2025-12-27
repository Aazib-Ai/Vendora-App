import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

// If Order model path is unsure, I will use generic imports or verify first. 
// Based on previous file reads, ProductRepository was in core/data. 
// I'll try to guess common paths or strictly wait for verification. 
// But to be safe and fast, I can omit the import if I don't use the type explicitly or use dynamic.
// Better: I'll use the SupabaseService pattern.

class RealtimeManager {
  final SupabaseConfig _supabaseConfig;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeManager({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  /// Subscribe to order updates for a specific user
  void subscribeToOrders(String userId, void Function(Map<String, dynamic>) onUpdate) {
    final channelName = 'orders:$userId';
    if (_channels.containsKey(channelName)) return;

    final channel = _supabaseConfig.client.realtime.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        onUpdate(payload.newRecord);
      },
    ).subscribe();

    _channels[channelName] = channel;
  }

  /// Subscribe to product updates (e.g. stock changes)
  void subscribeToProducts(void Function(Map<String, dynamic>) onUpdate) {
    const channelName = 'products:updates';
    if (_channels.containsKey(channelName)) return;

    final channel = _supabaseConfig.client.realtime.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'products',
      callback: (payload) {
        onUpdate(payload.newRecord);
      },
    ).subscribe();

    _channels[channelName] = channel;
  }

  /// Unsubscribe from a specific channel
  void unsubscribe(String channelKey) {
    _channels[channelKey]?.unsubscribe();
    _channels.remove(channelKey);
  }

  /// Dispose all channels
  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
