import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/admin/presentation/providers/dispute_provider.dart';
import 'package:vendora/models/dispute.dart';

/// Detailed dispute view with evidence display and resolution actions
class DisputeDetailsScreen extends StatefulWidget {
  final String disputeId;

  const DisputeDetailsScreen({
    super.key,
    required this.disputeId,
  });

  @override
  State<DisputeDetailsScreen> createState() => _DisputeDetailsScreenState();
}

class _DisputeDetailsScreenState extends State<DisputeDetailsScreen> {
  final TextEditingController _resolutionController = TextEditingController();
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisputeProvider>().selectDispute(widget.disputeId);
    });
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Details'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DisputeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedDispute == null) {
            return const Center(child: CircularProgressIndicator());
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
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.selectDispute(widget.disputeId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final dispute = provider.selectedDispute;
          if (dispute == null) {
            return const Center(child: Text('Dispute not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(theme, dispute),
                const SizedBox(height: 24),
                _buildPartiesSection(theme, dispute),
                const SizedBox(height: 24),
                _buildEvidenceSection(theme, dispute),
                const SizedBox(height: 24),
                if (dispute.status != DisputeStatus.resolved &&
                    dispute.status != DisputeStatus.rejected)
                  _buildResolutionSection(theme, dispute),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme, Dispute dispute) {
    final daysOld = DateTime.now().difference(dispute.createdAt).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dispute Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusChip(dispute.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.event,
              label: 'Created',
              value: '$daysOld day(s) ago',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.receipt_long,
              label: 'Order ID',
              value: dispute.orderId.substring(0, 12) + '...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartiesSection(ThemeData theme, Dispute dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parties Involved',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Buyer',
              value: dispute.buyerId,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.store_outlined,
              label: 'Seller',
              value: dispute.sellerId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection(ThemeData theme, Dispute dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidence',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Buyer's evidence
            Text(
              'Buyer\'s Claim',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason: ${dispute.reason}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dispute.buyerDescription,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (dispute.buyerEvidence.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Evidence files: ${dispute.buyerEvidence.length} item(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seller's response
            Text(
              'Seller\'s Response',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dispute.sellerResponse ?? 'No response yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: dispute.sellerResponse == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: dispute.sellerResponse == null
                      ? Colors.grey.shade600
                      : null,
                ),
              ),
            ),

            // Admin resolution if exists
            if (dispute.adminResolution != null) ...[
              const SizedBox(height: 16),
              Text(
                'Admin Resolution',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  dispute.adminResolution!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionSection(ThemeData theme, Dispute dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resolve Dispute',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _resolutionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                hintText: 'Enter your decision and reasoning...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isResolving
                        ? null
                        : () => _showConfirmationDialog(
                              context,
                              'Refund Buyer',
                              'This will refund the buyer and cancel the order. Are you sure?',
                              () => _resolveRefundBuyer(dispute.id),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Refund Buyer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isResolving
                        ? null
                        : () => _showConfirmationDialog(
                              context,
                              'Release to Seller',
                              'This will release the funds to the seller. Are you sure?',
                              () => _resolveReleaseSeller(dispute.id),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Release Seller'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(DisputeStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case DisputeStatus.open:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = 'PENDING';
        break;
      case DisputeStatus.underReview:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        text = 'UNDER REVIEW';
        break;
      case DisputeStatus.resolved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = 'RESOLVED';
        break;
      case DisputeStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = 'REJECTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveRefundBuyer(String disputeId) async {
    if (_resolutionController.text.trim().isEmpty) {
      _showSnackBar('Please enter resolution notes', isError: true);
      return;
    }

    setState(() => _isResolving = true);

    final success = await context.read<DisputeProvider>().refundBuyer(
          disputeId,
          _resolutionController.text.trim(),
        );

    setState(() => _isResolving = false);

    if (success) {
      _showSnackBar('Dispute resolved - Buyer refunded');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      final errorMessage =
          context.read<DisputeProvider>().errorMessage ?? 'Failed to resolve';
      _showSnackBar(errorMessage, isError: true);
    }
  }

  Future<void> _resolveReleaseSeller(String disputeId) async {
    if (_resolutionController.text.trim().isEmpty) {
      _showSnackBar('Please enter resolution notes', isError: true);
      return;
    }

    setState(() => _isResolving = true);

    final success = await context.read<DisputeProvider>().releaseSeller(
          disputeId,
          _resolutionController.text.trim(),
        );

    setState(() => _isResolving = false);

    if (success) {
      _showSnackBar('Dispute resolved - Funds released to seller');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      final errorMessage =
          context.read<DisputeProvider>().errorMessage ?? 'Failed to resolve';
      _showSnackBar(errorMessage, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
