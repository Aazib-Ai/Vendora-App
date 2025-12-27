import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:vendora/features/admin/presentation/providers/product_moderation_provider.dart';
import 'package:vendora/features/admin/presentation/widgets/product_details_dialog.dart';
import 'package:vendora/models/product.dart';

/// Product Moderation Screen for admin users
/// Displays products in tabs based on status (Pending, Approved, Rejected, Hidden)
/// Allows admins to approve, reject, or hide products
/// Requirements: 8.4, 8.7
class ProductModerationScreen extends StatefulWidget {
  const ProductModerationScreen({super.key});

  @override
  State<ProductModerationScreen> createState() =>
      _ProductModerationScreenState();
}

class _ProductModerationScreenState extends State<ProductModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load products on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductModerationProvider>().loadAllProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductModerationProvider(
        productRepository: ProductRepository(),
        adminRepository: AdminRepositoryImpl(),
      )..loadAllProducts(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Product Moderation'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Implement filter
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Consumer<ProductModerationProvider>(
              builder: (context, provider, _) {
                return Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: [
                      Tab(
                        text: 'Pending',
                        icon: Badge(
                          label: Text('${provider.pendingCount}'),
                          child: const Icon(Icons.pending),
                        ),
                      ),
                      Tab(
                        text: 'Approved',
                        icon: Badge(
                          label: Text('${provider.approvedCount}'),
                          child: const Icon(Icons.check_circle),
                        ),
                      ),
                      Tab(
                        text: 'Rejected',
                        icon: Badge(
                          label: Text('${provider.rejectedCount}'),
                          child: const Icon(Icons.cancel),
                        ),
                      ),
                      Tab(
                        text: 'Hidden',
                        icon: Badge(
                          label: Text('${provider.hiddenCount}'),
                          child: const Icon(Icons.visibility_off),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        body: Consumer<ProductModerationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(provider.error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProductList(
                    products: provider.pendingProducts,
                    status: 'pending',
                  ),
                  _ProductList(
                    products: provider.approvedProducts,
                    status: 'approved',
                  ),
                  _ProductList(
                    products: provider.rejectedProducts,
                    status: 'rejected',
                  ),
                  _ProductList(
                    products: provider.hiddenProducts,
                    status: 'hidden',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final String status;

  const _ProductList({
    required this.products,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status} products',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCard(
          product: products[index],
          status: status,
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String status;

  const _ProductCard({
    required this.product,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.primaryImageUrl != null &&
                          product.primaryImageUrl!.isNotEmpty
                      ? Image.network(
                          product.primaryImageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 50),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
                        ),
                ),
                const SizedBox(width: 16),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seller ID: ${product.sellerId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (product.categoryId != null)
                        Text(
                          'Category: ${product.categoryId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: Rs ${product.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Stock: ${product.stockQuantity} units',
                        style: TextStyle(
                          fontSize: 14,
                          color: product.stockQuantity < 5
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Description:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.description.length > 150
                  ? '${product.description.substring(0, 150)}...'
                  : product.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ProductDetailsDialog(product: product),
                );
              },
              child: const Text('View Full Details'),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = context.read<ProductModerationProvider>();

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _approveProduct(context, provider),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _rejectProduct(context, provider),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (status == 'approved') {
      return ElevatedButton.icon(
        onPressed: () => _hideProduct(context, provider),
        icon: const Icon(Icons.visibility_off),
        label: const Text('Hide Product'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      );
    } else if (status == 'hidden') {
      return ElevatedButton.icon(
        onPressed: () => _unhideProduct(context, provider),
        icon: const Icon(Icons.visibility),
        label: const Text('Unhide Product'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _approveProduct(
    BuildContext context,
    ProductModerationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Product'),
        content: Text('Approve "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.approveProduct(product.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product approved successfully')),
        );
      }
    }
  }

  Future<void> _rejectProduct(
    BuildContext context,
    ProductModerationProvider provider,
  ) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "${product.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.rejectProduct(
        product.id,
        reasonController.text,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product rejected')),
        );
      }
    }
  }

  Future<void> _hideProduct(
    BuildContext context,
    ProductModerationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide Product'),
        content: Text('Hide "${product.name}" from search results?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Hide'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.hideProduct(product.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product hidden successfully')),
        );
      }
    }
  }

  Future<void> _unhideProduct(
    BuildContext context,
    ProductModerationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unhide Product'),
        content: Text('Make "${product.name}" visible again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unhide'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.unhideProduct(product.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product unhidden successfully')),
        );
      }
    }
  }
}
