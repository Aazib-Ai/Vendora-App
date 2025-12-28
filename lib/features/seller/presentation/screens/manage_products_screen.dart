import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../core/data/repositories/seller_repository.dart';
import '../../../../models/product.dart';
import '../../../../../models/product.dart'; // Import for ProductStatus enum if needed
import '../../../../models/seller_model.dart';
import '../screens/add_edit_product_screen.dart';
import '../providers/product_form_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  String searchQuery = "";
  String _sortOption = "Name";
  late Future<Seller?> _sellerFuture;
  
  @override
  void initState() {
    super.initState();
    _loadSeller();
  }
  
  void _loadSeller() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      // Fetch the seller record to get the actual seller_id
      _sellerFuture = context.read<SellerRepository>().getCurrentSeller(userId).then((result) {
        return result.fold(
          (failure) => throw Exception(failure.message),
          (seller) => seller,
        );
      });
    } else {
      _sellerFuture = Future.value(null);
    }
  }
  
  void _navigateToAddEdit(Product? product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (context) => ProductFormProvider(
            productRepository: context.read<ProductRepository>(),
            // Assuming imageUploadService is available in context or locator
            // For now, we might need to pass it or grab from repository if exposed
            // In a real app, using GetIt or Provider for this service is better
            imageUploadService: Provider.of(context, listen: false), 
          ),
          child: AddEditProductScreen(product: product),
        ),
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Product?"),
        content: Text("Are you sure you want to delete '${product.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              final repo = context.read<ProductRepository>();
              final result = await repo.deleteProduct(product.id);
              
              if (mounted) {
                result.fold(
                  (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${failure.message}')),
                  ),
                  (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProductRepository>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manage Products",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortOption,
                      icon: const Icon(Icons.sort),
                      items: [
                        'Name',
                        'Price: Low to High',
                        'Price: High to Low',
                        'Stock: Low to High',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _sortOption = newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<Seller?>(
                future: _sellerFuture,
                builder: (context, sellerSnapshot) {
                  if (sellerSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (sellerSnapshot.hasError) {
                    return Center(child: Text('Error: ${sellerSnapshot.error}'));
                  }
                  
                  final seller = sellerSnapshot.data;
                  if (seller == null) {
                    return const Center(child: Text('Seller profile not found. Please contact support.'));
                  }
                  
                  // Now we have the actual seller_id, use it for the products stream
                  return StreamBuilder<List<Product>>(
                    stream: repo.watchSellerProducts(seller.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      
                      final products = snapshot.data ?? [];
                      
                      if (products.isEmpty) {
                         return const Center(child: Text('No products found. Add one!'));
                      }

                      final filteredProducts = products.where((p) {
                        final query = searchQuery.toLowerCase();
                        return p.name.toLowerCase().contains(query);
                      }).toList();

                      // Sort products
                      filteredProducts.sort((a, b) {
                        switch (_sortOption) {
                          case 'Name':
                            return a.name.compareTo(b.name);
                          case 'Price: Low to High':
                            return a.basePrice.compareTo(b.basePrice);
                          case 'Price: High to Low':
                            return b.basePrice.compareTo(a.basePrice);
                          case 'Stock: Low to High':
                            return a.stockQuantity.compareTo(b.stockQuantity); // Requirements 16.5
                          default:
                            return 0;
                        }
                      });

                      return ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _productListItem(product);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _navigateToAddEdit(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _productListItem(Product product) {
    Color statusColor;
    switch (product.status) {
      case ProductStatus.approved:
        statusColor = Colors.green;
        break;
      case ProductStatus.pending:
        statusColor = Colors.orange;
        break;
      case ProductStatus.rejected:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Get primary image
    final imageUrl = product.images.isNotEmpty 
        ? product.images.firstWhere((i) => i.isPrimary, orElse: () => product.images.first).url 
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
              image: imageUrl.isNotEmpty ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: imageUrl.isEmpty 
                ? const Icon(Icons.image, color: Colors.white24) 
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      product.status.name.toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  product.categoryId ?? 'Uncategorized',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PKR ${product.basePrice}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_note, color: Colors.white),
                          onPressed: () => _navigateToAddEdit(product),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: Colors.redAccent),
                          onPressed: () => _confirmDelete(product),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
