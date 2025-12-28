import 'package:flutter/material.dart';
import 'package:vendora/models/product.dart';

/// Dialog to show complete product details for moderation
/// Displays all images, description, specifications, variants, and seller info
class ProductDetailsDialog extends StatelessWidget {
  final Product product;

  const ProductDetailsDialog({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Images
                  if (product.images.isNotEmpty) ...[
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        itemBuilder: (context, index) {
                          final image = product.images[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image.url,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Basic Info
                  _InfoRow(
                    label: 'Seller ID',
                    value: product.sellerId,
                  ),
                  if (product.categoryId != null)
                    _InfoRow(
                      label: 'Category ID',
                      value: product.categoryId!,
                    ),
                  _InfoRow(
                    label: 'Price',
                    value: 'PKR ${product.basePrice.toStringAsFixed(0)}',
                  ),
                  if (product.discountPercentage != null)
                    _InfoRow(
                      label: 'Discount',
                      value: '${product.discountPercentage}%',
                    ),
                  _InfoRow(
                    label: 'Stock',
                    value: '${product.stockQuantity} units',
                  ),
                  _InfoRow(
                    label: 'Status',
                    value: product.status.name.toUpperCase(),
                  ),
                  _InfoRow(
                    label: 'Active',
                    value: product.isActive ? 'Yes' : 'No',
                  ),
                  _InfoRow(
                    label: 'Average Rating',
                    value: product.averageRating.toStringAsFixed(1),
                  ),
                  _InfoRow(
                    label: 'Reviews',
                    value: '${product.reviewCount}',
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Specifications
                  if (product.specifications.isNotEmpty) ...[
                    const Text(
                      'Specifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...product.specifications.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  // Variants
                  if (product.variants.isNotEmpty) ...[
                    const Text(
                      'Variants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...product.variants.map((variant) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SKU: ${variant.sku}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (variant.size != null)
                                Text('Size: ${variant.size}'),
                              if (variant.color != null)
                                Text('Color: ${variant.color}'),
                              if (variant.material != null)
                                Text('Material: ${variant.material}'),
                              Text('Price: PKR ${variant.price.toStringAsFixed(0)}'),
                              Text(
                                'Stock: ${variant.stockQuantity} units',
                                style: TextStyle(
                                  color: variant.stockQuantity < 5
                                      ? Colors.orange
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
