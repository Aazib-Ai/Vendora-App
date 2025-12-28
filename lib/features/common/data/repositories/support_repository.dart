import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_ticket_model.dart';

class SupportRepository {
  final SupabaseClient _supabase;

  SupportRepository(this._supabase);

  Future<void> createTicket(SupportTicket ticket) async {
    try {
      await _supabase.from('support_tickets').insert(ticket.toJson());
    } catch (e) {
      throw Exception('Failed to create support ticket: $e');
    }
  }

  Future<List<SupportTicket>> getTickets({TicketStatus? status, TicketType? type}) async {
    try {
      var query = _supabase.from('support_tickets').select();

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }
      
      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List).map((e) => SupportTicket.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch support tickets: $e');
    }
  }

  Future<void> updateTicketStatus(String id, TicketStatus status) async {
    try {
      await _supabase.from('support_tickets').update({
        'status': status.toString().split('.').last,
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }
}
