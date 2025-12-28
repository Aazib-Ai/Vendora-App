import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/theme/app_colors.dart';
import 'package:vendora/core/theme/app_radius.dart';
import 'package:vendora/core/theme/app_typography.dart';
import 'package:vendora/features/admin/presentation/providers/admin_kyc_provider.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:intl/intl.dart';

class SellerKYCScreen extends StatefulWidget {
  const SellerKYCScreen({super.key});

  @override
  State<SellerKYCScreen> createState() => _SellerKYCScreenState();
}

class _SellerKYCScreenState extends State<SellerKYCScreen> {
  String _selectedFilter = 'Pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminKYCProvider>().loadUnverifiedSellers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seller Verification'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status tabs
          _buildStatusTabs(),
          // Sellers list
          Expanded(
            child: Consumer<AdminKYCProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadUnverifiedSellers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final sellers = _filterSellers(provider.unverifiedSellers);

                if (sellers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                        const SizedBox(height: 16),
                        const Text(
                          'No sellers to review',
                          style: AppTypography.headingMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All seller applications have been processed',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadUnverifiedSellers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sellers.length,
                    itemBuilder: (context, index) {
                      return _SellerCard(seller: sellers[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _StatusTab(
              label: 'Pending',
              count: _getCountForFilter('Pending'),
              isSelected: _selectedFilter == 'Pending',
              onTap: () => setState(() => _selectedFilter = 'Pending'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatusTab(
              label: 'Approved',
              count: _getCountForFilter('Approved'),
              isSelected: _selectedFilter == 'Approved',
              onTap: () => setState(() => _selectedFilter = 'Approved'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatusTab(
              label: 'Rejected',
              count: _getCountForFilter('Rejected'),
              isSelected: _selectedFilter == 'Rejected',
              onTap: () => setState(() => _selectedFilter = 'Rejected'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatusTab(
              label: 'All',
              count: context.watch<AdminKYCProvider>().unverifiedSellers.length,
              isSelected: _selectedFilter == 'All',
              onTap: () => setState(() => _selectedFilter = 'All'),
            ),
          ),
        ],
      ),
    );
  }

  List<Seller> _filterSellers(List<Seller> sellers) {
    if (_selectedFilter == 'All') return sellers;
    final filter = _selectedFilter.toLowerCase();
    final mappedStatus = _mapFilterToStatus(filter);
    return sellers.where((s) => s.status.toLowerCase() == mappedStatus).toList();
  }

  int _getCountForFilter(String filter) {
    final sellers = context.watch<AdminKYCProvider>().unverifiedSellers;
    if (filter == 'All') return sellers.length;
    final mappedStatus = _mapFilterToStatus(filter.toLowerCase());
    return sellers.where((s) => s.status.toLowerCase() == mappedStatus).length;
  }

  String _mapFilterToStatus(String filter) {
    switch (filter) {
      case 'pending':
        return 'unverified';
      case 'approved':
        return 'active';
      case 'rejected':
        return 'rejected';
      default:
        return filter;
    }
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.surface : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final Seller seller;

  const _SellerCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    seller.businessName.isNotEmpty 
                        ? seller.businessName[0].toUpperCase()
                        : '?',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.businessName,
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              seller.businessCategory,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Seller details
            _buildDetailRow('📅 Applied', DateFormat('MMM dd, yyyy').format(seller.createdAt)),
            const SizedBox(height: 8),
            _buildDetailRow('Category', seller.businessCategory),
            const SizedBox(height: 8),
            _buildDetailRow('WhatsApp', seller.whatsappNumber),
            
            if (seller.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Description',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                seller.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectionDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const Text('Reject'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Seller'),
        content: Text('Are you sure you want to approve ${seller.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<AdminKYCProvider>();
              final success = await provider.approveSeller(seller.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${seller.businessName} approved successfully'
                          : 'Failed to approve seller',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for rejecting ${seller.businessName}:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              final provider = context.read<AdminKYCProvider>();
              final success = await provider.rejectSeller(seller.id, reason);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${seller.businessName} rejected'
                          : 'Failed to reject seller',
                    ),
                    backgroundColor: success ? AppColors.info : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
