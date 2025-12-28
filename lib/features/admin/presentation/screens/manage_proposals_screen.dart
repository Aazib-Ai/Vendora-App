import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/common/providers/proposal_provider.dart';
import 'package:vendora/models/proposal.dart';

class ManageProposalsScreen extends StatefulWidget {
  const ManageProposalsScreen({super.key});

  @override
  State<ManageProposalsScreen> createState() => _ManageProposalsScreenState();
}

class _ManageProposalsScreenState extends State<ManageProposalsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProposalProvider>().loadAllProposals(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banners'),
        backgroundColor: const Color(0xFF1A1A2E), // Admin theme color
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.editProposal);
        },
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ProposalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.allProposals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.allProposals.isEmpty) {
            return const Center(child: Text('No banners found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.allProposals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final proposal = provider.allProposals[index];
              return _ProposalCard(proposal: proposal);
            },
          );
        },
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;

  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    // Parse color string (0xFF...)
    Color bgColor = Colors.grey;
    try {
      if (proposal.bgColor.startsWith('0x')) {
         bgColor = Color(int.parse(proposal.bgColor));
      } else {
         bgColor = Color(int.parse('0xFF${proposal.bgColor.replaceAll('#', '')}'));
      }
    } catch (_) {}

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(proposal.imageUrl),
              fit: BoxFit.cover,
              onError: (_, __) {},
            ),
          ),
        ),
        title: Text(
          proposal.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(proposal.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: proposal.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                proposal.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: proposal.isActive ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.editProposal,
                  arguments: proposal,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, proposal),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Proposal proposal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProposalProvider>().deleteProposal(proposal.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
