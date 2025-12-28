import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/core/theme/app_colors.dart';
import 'package:vendora/features/admin/presentation/providers/admin_seller_provider.dart';
import 'package:vendora/models/seller_model.dart';

class ManageSellersScreen extends StatefulWidget {
  const ManageSellersScreen({super.key});

  @override
  State<ManageSellersScreen> createState() => _ManageSellersScreenState();
}

class _ManageSellersScreenState extends State<ManageSellersScreen> {
  late AdminSellerProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = AdminSellerProvider(context.read<SellerRepository>());
    _provider.loadSellers();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Manage Sellers'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _provider.refresh(),
            ),
          ],
        ),
        body: Consumer<AdminSellerProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.allSellers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.error != null && provider.allSellers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Filter Tabs
                _buildFilterTabs(provider),
                // Sellers List
                Expanded(
                  child: _buildSellersList(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTabs(AdminSellerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _FilterTab(
              label: 'All Sellers',
              count: provider.totalCount,
              isSelected: provider.selectedFilter == 'All',
              onTap: () => provider.setFilter('All'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterTab(
              label: 'Approved',
              count: provider.approvedCount,
              isSelected: provider.selectedFilter == 'active',
              onTap: () => provider.setFilter('active'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterTab(
              label: 'Pending',
              count: provider.pendingCount,
              isSelected: provider.selectedFilter == 'unverified',
              onTap: () => provider.setFilter('unverified'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterTab(
              label: 'Suspended',
              count: provider.suspendedCount,
              isSelected: provider.selectedFilter == 'suspended',
              onTap: () => provider.setFilter('suspended'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellersList(AdminSellerProvider provider) {
    final sellers = provider.sellers;

    if (sellers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No sellers found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sellers.length,
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return _SellerCard(
            seller: seller,
            onApprove: () => _showApprovalDialog(seller),
            onReject: () => _showRejectionDialog(seller),
            onSuspend: () => _showSuspensionDialog(seller),
            onReactivate: () => _showReactivationDialog(seller),
          );
        },
      ),
    );
  }

  void _showApprovalDialog(Seller seller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Seller'),
        content: Text('Are you sure you want to approve ${seller.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture messenger before closing dialog
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              final success = await _provider.approveSeller(seller.id);
              
              if (mounted) {
                messenger.showSnackBar(
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


  void _showRejectionDialog(Seller seller) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              // Capture messenger before potential Dialog close
              final messenger = ScaffoldMessenger.of(context);
              
              if (reason.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              
              Navigator.pop(dialogContext);
              final success = await _provider.rejectSeller(seller.id, reason);
              
              if (mounted) {
                messenger.showSnackBar(
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

  void _showSuspensionDialog(Seller seller) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suspend Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for suspending ${seller.businessName}:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter suspension reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              
              if (reason.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a suspension reason'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              
              Navigator.pop(dialogContext);
              final success = await _provider.suspendSeller(seller.id, reason);
              
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${seller.businessName} suspended'
                          : 'Failed to suspend seller',
                    ),
                    backgroundColor: success ? AppColors.warning : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showReactivationDialog(Seller seller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reactivate Seller'),
        content: Text('Are you sure you want to reactivate ${seller.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              final success = await _provider.reactivateSeller(seller.id);
              
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${seller.businessName} reactivated successfully'
                          : 'Failed to reactivate seller',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }
}


class _SellerCard extends StatelessWidget {
  final Seller seller;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  const _SellerCard({
    required this.seller,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = seller.status.toLowerCase() == 'active' || 
                       seller.status.toLowerCase() == 'approved';
    final isPending = seller.status.toLowerCase() == 'pending' || 
                      seller.status.toLowerCase() == 'unverified';
    final isSuspended = seller.status.toLowerCase() == 'suspended';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                seller.businessName.isNotEmpty 
                    ? seller.businessName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seller.businessName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seller.businessCategory,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isApproved 
                          ? Colors.green[50] 
                          : isPending 
                              ? Colors.orange[50]
                              : isSuspended
                                  ? Colors.amber[50]
                                  : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      seller.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: isApproved 
                            ? Colors.green[700] 
                            : isPending 
                                ? Colors.orange[700]
                                : isSuspended
                                    ? Colors.amber[900]
                                    : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons based on status
            if (isPending) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                onPressed: onApprove,
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
                onPressed: onReject,
              ),
            ] else if (isApproved) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block, color: Colors.white, size: 20),
                ),
                onPressed: onSuspend,
                tooltip: 'Suspend Seller',
              ),
            ] else if (isSuspended) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
                onPressed: onReactivate,
                tooltip: 'Reactivate Seller',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rejected',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
