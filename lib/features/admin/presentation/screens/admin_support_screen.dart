import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/theme/app_colors.dart';
import 'package:vendora/features/common/data/models/support_ticket_model.dart';
import 'package:vendora/features/common/presentation/providers/support_provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  TicketStatus? _filterStatus;
  TicketType? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  Future<void> _loadTickets() async {
    await context.read<SupportProvider>().loadTickets(
      status: _filterStatus,
      type: _filterType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TicketStatus>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _filterStatus,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...TicketStatus.values.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.toString().split('.').last.toUpperCase()),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _filterStatus = v);
                      _loadTickets();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<TicketType>(
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _filterType,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ...TicketType.values.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toString().split('.').last.replaceAll('_', ' ').toUpperCase()),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _filterType = v);
                      _loadTickets();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SupportProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.error != null) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text('Error: ${provider.error}'),
                         const SizedBox(height: 16),
                         ElevatedButton(
                           onPressed: _loadTickets,
                           child: const Text('Retry'),
                         ),
                       ],
                     ),
                   );
                }

                final tickets = provider.tickets;
                
                if (tickets.isEmpty) {
                  return const Center(child: Text('No tickets found.'));
                }
                
                return ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          ticket.type == TicketType.report_problem 
                              ? Icons.bug_report 
                              : Icons.mail,
                          color: ticket.type == TicketType.report_problem 
                              ? Colors.red 
                              : Colors.blue,
                        ),
                        title: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ticket.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(ticket.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: _getStatusColor(ticket.status)),
                                  ),
                                  child: Text(
                                    ticket.status.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: _getStatusColor(ticket.status),
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if(ticket.createdAt != null)
                                  Text(
                                    timeago.format(ticket.createdAt!),
                                    style:const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                            Navigator.pushNamed(
                                context, 
                                AppRoutes.adminTicketDetails,
                                arguments: ticket,
                            ).then((_) => _loadTickets());
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
