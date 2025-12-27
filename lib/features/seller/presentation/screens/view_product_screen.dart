import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/product_card.dart';
import 'package:vendora/core/widgets/search_bar.dart';
import 'package:vendora/models/demo_data.dart';

class ViewProductScreen extends StatelessWidget {
  const ViewProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Products'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchBar(
              hintText: 'Search products...',
              onFilterTap: () {},
            ),
          ),
          // Products List
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: demoProducts.length,
              itemBuilder: (context, index) {
                final product = demoProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // Navigate to product details/edit
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

