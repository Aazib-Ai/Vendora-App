import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/theme/app_colors.dart';
import 'package:vendora/features/admin/presentation/providers/admin_kyc_provider.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:intl/intl.dart';

class SellerDetailsDialog extends StatefulWidget {
  final Seller seller;

  const SellerDetailsDialog({super.key, required this.seller});

  @override
  State<SellerDetailsDialog> createState() => _SellerDetailsDialogState();
}

class _SellerDetailsDialogState extends State<SellerDetailsDialog> {
  final _reasonController = TextEditingController();
  bool _showRejectReason = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminKYCProvider>();
    final seller = widget.seller;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seller Verification',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow('Business Name', seller.businessName),
            _buildDetailRow('Category', seller.businessCategory),
            _buildDetailRow('WhatsApp', seller.whatsappNumber),
            _buildDetailRow('Description', seller.description),
            _buildDetailRow('Applied On', DateFormat.yMMMd().format(seller.createdAt)),
            const SizedBox(height: 24),
            if (_showRejectReason) ...[
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showRejectReason = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (_reasonController.text.isEmpty) return;
                            final success = await provider.rejectSeller(
                              seller.id,
                              _reasonController.text,
                            );
                            if (mounted && success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Seller rejected')),
                              );
                            }
                          },
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Confirm Rejection'),
                  ),
                ],
              ),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => setState(() => _showRejectReason = true),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            final success = await provider.approveSeller(seller.id);
                            if (mounted && success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Seller approved')),
                              );
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
