import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/repositories/support_repository.dart';

class SupportProvider extends ChangeNotifier {
  final SupportRepository _supportRepository;
  bool _isLoading = false;
  String? _error;
  List<SupportTicket> _tickets = [];

  SupportProvider(this._supportRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SupportTicket> get tickets => _tickets;

  Future<void> submitTicket({
    required String subject,
    required String message,
    required TicketType type,
    required String userId,
    List<String>? images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ticket = SupportTicket(
        userId: userId,
        type: type,
        subject: subject,
        message: message,
        images: images,
        status: TicketStatus.open,
      );

      await _supportRepository.createTicket(ticket);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin specific methods can be added here or in a separate AdminSupportProvider
  Future<void> loadTickets({TicketStatus? status, TicketType? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _supportRepository.getTickets(status: status, type: type);
    } catch (e) {
      _error = e.toString();
      _tickets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTicketStatus(String id, TicketStatus status) async {
    // Optimistic update or wait for backend? Let's wait for backend for safety
    try {
        await _supportRepository.updateTicketStatus(id, status);
        // Update the ticket in the local list
        final index = _tickets.indexWhere((t) => t.id == id);
        if (index != -1) {
          _tickets[index] = _tickets[index].copyWith(status: status);
        }
        notifyListeners();
    } catch (e) {
        _error = e.toString();
        rethrow;
    }
  }
}
