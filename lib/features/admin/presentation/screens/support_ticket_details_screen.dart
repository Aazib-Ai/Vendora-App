import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/common/data/models/support_ticket_model.dart';
import 'package:vendora/features/common/presentation/providers/support_provider.dart';
import 'package:vendora/core/theme/app_typography.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminTicketDetailsScreen extends StatefulWidget {
  final SupportTicket ticket;

  const AdminTicketDetailsScreen({super.key, required this.ticket});

  @override
  State<AdminTicketDetailsScreen> createState() => _AdminTicketDetailsScreenState();
}

class _AdminTicketDetailsScreenState extends State<AdminTicketDetailsScreen> {
  late TicketStatus _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
  }

  Future<void> _updateStatus(TicketStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await context.read<SupportProvider>().updateTicketStatus(
        widget.ticket.id!, // Assuming ID is not null here
        newStatus,
      );
      setState(() => _currentStatus = newStatus);
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status updated successfully')),
          );
      }
    } catch (e) {
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update status: $e')),
          );
      }
    } finally {
      if(mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.ticket.subject,
                    style: AppTypography.headingSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getStatusColor(_currentStatus)),
                  ),
                  child: Text(
                    _currentStatus.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(_currentStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
             Text(
              'Type: ${widget.ticket.type.toString().split('.').last.replaceAll('_', ' ').toUpperCase()}',
               style: const TextStyle(color: Colors.grey),
            ),
             Text(
              'Submitted: ${timeago.format(widget.ticket.createdAt ?? DateTime.now())}',
              style: const TextStyle(color: Colors.grey),
            ),
             Text(
              'User ID: ${widget.ticket.userId}',
               style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text('Message:', style: AppTypography.headingSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.ticket.message),
            ),
            const SizedBox(height: 24),
            if (widget.ticket.images != null && widget.ticket.images!.isNotEmpty) ...[
                Text('Attachments:', style: AppTypography.headingSmall),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.ticket.images!.map((url) {
                        return GestureDetector(
                            onTap: () {
                                // Open full screen image
                                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                                    appBar: AppBar(),
                                    body: Center(child: Image.network(url)),
                                )));
                            },
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, _, __) => Container(
                                        width: 100, 
                                        height: 100, 
                                        color: Colors.grey, 
                                        child: const Icon(Icons.broken_image)
                                    ),
                                ),
                            ),
                        );
                    }).toList(),
                ),
                const SizedBox(height: 24),
            ],

            Text('Update Status:', style: AppTypography.headingSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusButton(
                    status: TicketStatus.open, 
                    currentStatus: _currentStatus, 
                    onPressed: () => _updateStatus(TicketStatus.open),
                    color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _StatusButton(
                    status: TicketStatus.in_progress, 
                    currentStatus: _currentStatus, 
                    onPressed: () => _updateStatus(TicketStatus.in_progress),
                    color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _StatusButton(
                    status: TicketStatus.resolved, 
                    currentStatus: _currentStatus, 
                    onPressed: () => _updateStatus(TicketStatus.resolved),
                    color: Colors.green,
                ),
              ],
            ),
             if (_isUpdating)
                 const Padding(
                   padding: EdgeInsets.only(top: 16.0),
                   child: LinearProgressIndicator(),
                 ),
            
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return Colors.orange;
      case TicketStatus.in_progress: return Colors.blue;
      case TicketStatus.resolved: return Colors.green;
    }
  }
}

class _StatusButton extends StatelessWidget {
    final TicketStatus status;
    final TicketStatus currentStatus;
    final VoidCallback onPressed;
    final Color color;

  const _StatusButton({
      required this.status, 
      required this.currentStatus, 
      required this.onPressed,
      required this.color,
  });

  @override
  Widget build(BuildContext context) {
      final isSelected = status == currentStatus;
    return Expanded(
        child: ElevatedButton(
            onPressed: isSelected ? null : onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? color : Colors.white,
                foregroundColor: isSelected ? Colors.white : color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
                status.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
            ),
        ),
    );
  }
}
