import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/core/theme/app_colors.dart';
import 'package:vendora/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:vendora/features/admin/presentation/providers/product_moderation_provider.dart';
import 'package:vendora/models/product.dart';
import 'package:vendora/core/widgets/search_bar.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  late ProductModerationProvider _provider;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _provider = ProductModerationProvider(
      productRepository: context.read<ProductRepository>(),
      adminRepository: AdminRepositoryImpl(),
    );
    _provider.loadAllProducts();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts() {
    List<Product> products;
    
    switch (_selectedFilter) {
      case 'Pending':
        products = _provider.pendingProducts;
        break;
      case 'Approved':
        products = _provider.approvedProducts;
        break;
      case 'Rejected':
        products = _provider.rejectedProducts;
        break;
      case 'Hidden':
        products = _provider.hiddenProducts;
        break;
      case 'Reported':
        products = _provider.reportedProducts;
        break;
      default:
        products = [
          ..._provider.pendingProducts,
          ..._provider.approvedProducts,
          ..._provider.rejectedProducts,
          ..._provider.hiddenProducts,
          ..._provider.reportedProducts,
        ];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Manage Products'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _provider.refresh(),
            ),
          ],
        ),
        body: Consumer<ProductModerationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && 
                provider.pendingProducts.isEmpty &&
                provider.approvedProducts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.error != null && 
                provider.pendingProducts.isEmpty &&
                provider.approvedProducts.isEmpty) {
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
                // Search and Filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomSearchBar(
                    hintText: 'Search Products...',
                    onFilterTap: () {},
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // Filter Tabs
                _buildFilterTabs(provider),
                const SizedBox(height: 16),
                // Products List
                Expanded(
                  child: _buildProductsList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTabs(ProductModerationProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterTab(
            label: 'All',
            count: provider.pendingCount + provider.approvedCount + 
                   provider.rejectedCount + provider.hiddenCount + provider.reportedCount,
            isSelected: _selectedFilter == 'All',
            onTap: () => setState(() => _selectedFilter = 'All'),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Pending',
            count: provider.pendingCount,
            isSelected: _selectedFilter == 'Pending',
            onTap: () => setState(() => _selectedFilter = 'Pending'),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Approved',
            count: provider.approvedCount,
            isSelected: _selectedFilter == 'Approved',
            onTap: () => setState(() => _selectedFilter = 'Approved'),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Rejected',
            count: provider.rejectedCount,
            isSelected: _selectedFilter == 'Rejected',
            onTap: () => setState(() => _selectedFilter = 'Rejected'),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Hidden',
            count: provider.hiddenCount,
            isSelected: _selectedFilter == 'Hidden',
            onTap: () => setState(() => _selectedFilter = 'Hidden'),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Reported',
            count: provider.reportedCount,
            isSelected: _selectedFilter == 'Reported',
            onTap: () => setState(() => _selectedFilter = 'Reported'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final products = _getFilteredProducts();

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductCard(
            product: product,
            onApprove: product.status == ProductStatus.pending 
                ? () => _showApprovalDialog(product)
                : null,
            onReject: product.status == ProductStatus.pending 
                ? () => _showRejectionDialog(product)
                : null,
            onHide: product.status == ProductStatus.approved && product.isActive
                ? () => _showHideDialog(product)
                : null,
            onUnhide: product.status == ProductStatus.approved && !product.isActive
                ? () => _showUnhideDialog(product)
                : null,
          );
        },
      ),
    );
  }

  void _showApprovalDialog(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Product'),
        content: Text('Are you sure you want to approve "${product.name}"?'),
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
              final success = await _provider.approveProduct(product.id);
              
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${product.name} approved successfully'
                          : (_provider.error ?? 'Failed to approve product'),
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

  void _showRejectionDialog(Product product) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for rejecting "${product.name}":'),
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
              final success = await _provider.rejectProduct(product.id, reason);
              
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${product.name} rejected'
                          : 'Failed to reject product',
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

  void _showHideDialog(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hide Product'),
        content: Text('Are you sure you want to hide "${product.name}"? This will remove it from search results.'),
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
              final success = await _provider.hideProduct(product.id);
              
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${product.name} hidden successfully'
                          : 'Failed to hide product',
                    ),
                    backgroundColor: success ? AppColors.info : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Hide'),
          ),
        ],
      ),
    );
  }

  void _showUnhideDialog(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unhide Product'),
        content: Text('Are you sure you want to restore "${product.name}"? This will make it visible in search results.'),
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
              final success = await _provider.unhideProduct(product.id);
              
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? '${product.name} restored successfully'
                          : 'Failed to restore product',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;

  const _ProductCard({
    required this.product,
    this.onApprove,
    this.onReject,
    this.onHide,
    this.onUnhide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 100,
              height: 120,
              color: Colors.grey[200],
              child: product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http')
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.image, color: Colors.grey),
                    )
                  : product.imageUrl.isNotEmpty
                      ? Image.asset(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image, color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (product.sellerName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Seller: ${product.sellerName}',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onApprove != null)
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
                if (onReject != null)
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
                if (onHide != null)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility_off, color: Colors.white, size: 20),
                    ),
                    onPressed: onHide,
                  ),
                if (onUnhide != null)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility, color: Colors.white, size: 20),
                    ),
                    onPressed: onUnhide,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;

    if (!product.isActive && product.status == ProductStatus.approved) {
      bgColor = Colors.grey[100]!;
      textColor = Colors.grey[700]!;
      label = 'Hidden';
    } else {
      switch (product.status) {
        case ProductStatus.pending:
          bgColor = Colors.orange[50]!;
          textColor = Colors.orange[700]!;
          label = 'Pending';
          break;
        case ProductStatus.approved:
          bgColor = Colors.green[50]!;
          textColor = Colors.green[700]!;
          label = 'Approved';
          break;
        case ProductStatus.rejected:
          bgColor = Colors.red[50]!;
          textColor = Colors.red[700]!;
          label = 'Rejected';
          break;
        case ProductStatus.reported:
          bgColor = Colors.purple[50]!;
          textColor = Colors.purple[700]!;
          label = 'Reported';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
