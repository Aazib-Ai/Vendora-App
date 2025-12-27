import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/admin/presentation/providers/dispute_provider.dart';
import 'package:vendora/features/admin/presentation/screens/dispute_details_screen.dart';
import 'package:vendora/features/admin/presentation/widgets/dispute_card.dart';
import 'package:vendora/models/dispute.dart';

/// Main Dispute Center screen for admins
/// Lists disputes with status filtering and navigation to details
class DisputeCenterScreen extends StatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  State<DisputeCenterScreen> createState() => _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends State<DisputeCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DisputeStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Fetch disputes on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisputeProvider>().fetchDisputes();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = null; // All
            break;
          case 1:
            _selectedStatus = DisputeStatus.open; // Pending
            break;
          case 2:
            _selectedStatus = DisputeStatus.underReview; // Escalated
            break;
          case 3:
            _selectedStatus = DisputeStatus.resolved; // Resolved
            break;
        }
      });
      context.read<DisputeProvider>().fetchDisputes(status: _selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Center'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Escalated'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Consumer<DisputeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.disputes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchDisputes(
                      status: _selectedStatus,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.disputes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No disputes found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedStatus == null
                        ? 'All disputes will appear here'
                        : 'No ${_getStatusLabel(_selectedStatus!)} disputes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchDisputes(status: _selectedStatus),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.disputes.length,
              itemBuilder: (context, index) {
                final dispute = provider.disputes[index];
                return DisputeCard(
                  dispute: dispute,
                  onTap: () => _navigateToDetails(dispute.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetails(String disputeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisputeDetailsScreen(disputeId: disputeId),
      ),
    );
  }

  String _getStatusLabel(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return 'pending';
      case DisputeStatus.underReview:
        return 'escalated';
      case DisputeStatus.resolved:
        return 'resolved';
      case DisputeStatus.rejected:
        return 'rejected';
    }
  }
}
