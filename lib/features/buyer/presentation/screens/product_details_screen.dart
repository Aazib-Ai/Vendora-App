import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendora/models/product.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/services/cart_service.dart';
import 'package:vendora/features/buyer/presentation/providers/review_provider.dart';
import 'package:vendora/features/buyer/presentation/screens/leave_review_screen.dart';
import 'package:vendora/features/buyer/presentation/widgets/product_reviews_list.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart' as auth;

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  bool expanded = false;
  int _currentImageIndex = 0;
  ProductVariant? _selectedVariant;

  // Computed properties based on selection
  double get _currentPrice => _selectedVariant?.price ?? widget.product.currentPrice;
  int get _currentStock => _selectedVariant?.stockQuantity ?? widget.product.stockQuantity;
  bool get _isLowStock => _currentStock > 0 && _currentStock < 5;
  bool get _isOutOfStock => _currentStock == 0;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      // Default to first variant if available, or force user to select
      // For better UX, let's auto-select the first in-stock variant if possible
      try {
        _selectedVariant = widget.product.variants.firstWhere((v) => v.stockQuantity > 0);
      } catch (_) {
        _selectedVariant = widget.product.variants.first;
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    // In a real app, you'd get this from the seller model linked to the product
    // For now, using a placeholder or the one from requirements if specified
    // Requirements say "Open WhatsApp with seller number"
    // Assuming we might need to fetch seller or it's part of product snapshot
    // Since Product model has sellerId but not full seller object here, 
    // we'll assume a number is available or use a placeholder for the UI task.
    // Ideally Product should have seller info. 
    // Checking Product model: it has sellerId. 
    // I will use a dummy number for now as I don't have Seller entity joined here yet.
    const number = "923001234567"; 
    final url = Uri.parse("https://wa.me/$number");
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(),
                          const SizedBox(height: 12),
                          _buildPriceRow(),
                          const SizedBox(height: 16),
                          if (widget.product.variants.isNotEmpty) _buildVariantSelector(),
                          if (widget.product.variants.isNotEmpty) const SizedBox(height: 16),
                          _buildStockIndicator(),
                          const SizedBox(height: 24),
                          _buildTrustBadges(),
                          const SizedBox(height: 24),
                          _buildDescription(),
                          const SizedBox(height: 24),
                          _buildSellerInfo(),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          // Review Button Check
                          Consumer<ReviewProvider>(
                            builder: (context, reviewProvider, _) {
                              return FutureBuilder<String?>(
                                future: () async {
                                  final user = context.read<auth.AuthProvider>().currentUser;
                                  if (user == null) return null;
                                  return reviewProvider.getReviewableOrderId(user.id, widget.product.id);
                                }(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LeaveReviewScreen(
                                                  product: widget.product,
                                                  orderId: snapshot.data!,
                                                ),
                                              ),
                                            ).then((_) {
                                              // Refresh reviews after return
                                              context.read<ReviewProvider>().loadProductReviews(widget.product.id);
                                            });
                                          },
                                          child: const Text("Write a Review"),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              );
                            },
                          ),
                          ProductReviewsList(productId: widget.product.id),
                          const SizedBox(height: 100), // Spacing for bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    final images = widget.product.images.isNotEmpty 
        ? widget.product.images.map((e) => e.url).toList() 
        : [widget.product.imageUrl ?? 'assets/images/placeholder.png']; // Fallback

    // If product.imageUrl exists and is not in images list (legacy support)
    if (widget.product.images.isEmpty && widget.product.imageUrl != null) {
        // handled above
    }

    return Stack(
      children: [
        Container(
          height: 360,
          width: double.infinity,
          decoration: BoxDecoration(
             color: Colors.grey.shade100,
          ),
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.asset( // Changed to Image.asset as per current data mock
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, _, __) => const Center(child: Icon(Icons.image_not_supported)),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
        if (images.length > 1)
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index ? Colors.black : Colors.grey.shade400,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
             RatingBarIndicator(
              rating: widget.product.rating,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "${widget.product.rating} (${widget.product.reviewCount} reviews)",
               style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_isLowStock)
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.orange.shade100,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   "Only $_currentStock left!",
                   style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                 ),
              ),
        if (_isOutOfStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Out of Stock",
                   style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
               "Product Details", 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
             Consumer<WishlistProvider>(
               builder: (context, wishlistProvider, _) {
                 final isWishlisted = wishlistProvider.isInWishlist(widget.product.id);
                 return IconButton(
                   icon: Icon(
                     isWishlisted ? Icons.favorite : Icons.favorite_border,
                     color: isWishlisted ? Colors.red : Colors.grey,
                     size: 28,
                   ),
                   onPressed: () {
                      final user = context.read<auth.AuthProvider>().currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Please login to use wishlist')),
                        );
                        return;
                      }
                      if (isWishlisted) {
                         wishlistProvider.removeFromWishlist(user.id, widget.product.id);
                      } else {
                         wishlistProvider.addToWishlist(user.id, widget.product);
                      }
                   },
                 );
               },
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "\$${_currentPrice.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black, // Primary color
          ),
        ),
        if (widget.product.discountPercentage != null && widget.product.discountPercentage! > 0)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              "\$${widget.product.basePrice.toStringAsFixed(2)}", // Show base price struck through
              style: TextStyle(
                fontSize: 16,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          if (widget.product.discountPercentage != null && widget.product.discountPercentage! > 0)
          Container(
             margin: const EdgeInsets.only(left: 12, bottom: 4),
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             decoration: BoxDecoration(
               color: Colors.red,
               borderRadius: BorderRadius.circular(4),
             ),
             child: Text(
               "-${widget.product.discountPercentage!.round()}%",
               style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
             ),
          ),
      ],
    );
  }

  Widget _buildVariantSelector() {
    // Group variants by type if we had type info, but here we just have a list of variants
    // Usually variants might be "Size" or "Color". 
    // The current ProductVariant model has fields like `size`, `color`.
    
    // We will build selectors for Size and Color.
    // unique sizes
    final sizes = widget.product.variants.map((v) => v.size).toSet().toList();
    // unique colors
    final colors = widget.product.variants.map((v) => v.color).toSet().toList();
    
    // This is a simplified selector that assumes full combination is unique or we are just filtering list
    // A proper implementation would filter valid combinations. 
    // For this task, let's just show chips for the actual variants since ProductVariant represents a SKU.
    
    // Let's refine: The user selects a SKU essentially. 
    // But usually UI separates Size and Color.
    // Let's Find the variant that matches selected color/size.
    
    // To keep it simple and robust: Display variants as clear options if they are few, 
    // or if we have size/color structure, use that.
    
    // Let's try to infer if we should show Size and Color picker.
    bool hasSizes = sizes.any((s) => s != null && s.isNotEmpty);
    bool hasColors = colors.any((c) => c != null && c.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSizes) ...[
          const Text("Size", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: sizes.where((s) => s != null).map((size) {
               final isSelected = _selectedVariant?.size == size;
               // Check availability for this size (simplistic, assumes size availability independent of color for now or just visual)
               // Better: check if ANY variant with this size has stock
               final isAvailable = widget.product.variants.any((v) => v.size == size && v.stockQuantity > 0);
               
               return ChoiceChip(
                 label: Text(size!),
                 selected: isSelected,
                 onSelected: isAvailable ? (selected) {
                   if (selected) {
                     // Find a variant with this size
                     final variant = widget.product.variants.firstWhere(
                       (v) => v.size == size && (v.color == _selectedVariant?.color || true),
                       orElse: () => widget.product.variants.firstWhere((v) => v.size == size),
                     );
                     setState(() {
                       _selectedVariant = variant;
                     });
                   }
                 } : null,
                 disabledColor: Colors.grey.shade200,
                 selectedColor: Colors.black,
                 labelStyle: TextStyle(color: isSelected ? Colors.white : (isAvailable ? Colors.black : Colors.grey)),
               );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (hasColors) ...[
          const Text("Color", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
           const SizedBox(height: 8),
           Wrap(
            spacing: 8,
             children: colors.where((c) => c != null).map((color) {
                final isSelected = _selectedVariant?.color == color;
                final isAvailable = widget.product.variants.any((v) => v.color == color && v.stockQuantity > 0);

                return ChoiceChip(
                  label: Text(color!),
                  selected: isSelected,
                  onSelected: isAvailable ? (selected) {
                    if (selected) {
                       final variant = widget.product.variants.firstWhere(
                        (v) => v.color == color && (v.size == _selectedVariant?.size || true),
                         orElse: () => widget.product.variants.firstWhere((v) => v.color == color),
                       );
                       setState(() => _selectedVariant = variant);
                    }
                  } : null,
                  selectedColor: Colors.black,
                  disabledColor: Colors.grey.shade200,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : (isAvailable ? Colors.black : Colors.grey)),
                );
             }).toList(),
           ),
        ]
      ],
    );
  }

  Widget _buildStockIndicator() {
     // Already handled in header for badges, but maybe logic for max quantity selector
     return Row(
       children: [
         const Text("Quantity", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
         const SizedBox(width: 16),
         Container(
           decoration: BoxDecoration(
             border: Border.all(color: Colors.grey.shade300),
             borderRadius: BorderRadius.circular(8),
           ),
           child: Row(
             children: [
               IconButton(
                 icon: const Icon(Icons.remove),
                 onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
               ),
               Text("$quantity", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
               IconButton(
                 icon: const Icon(Icons.add),
                 onPressed: (!_isOutOfStock && quantity < _currentStock) 
                    ? () => setState(() => quantity++) 
                    : null,
               ),
             ],
           ),
         ),
       ],
     );
  }

  Widget _buildTrustBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
       children: const [
         _TrustBadge(icon: Icons.local_shipping_outlined, label: "Free Shipping"),
         _TrustBadge(icon: Icons.verified_user_outlined, label: "Authentic"),
         _TrustBadge(icon: Icons.refresh_outlined, label: "Easy Returns"),
       ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          expanded ? widget.product.description : (widget.product.description.length > 150 ? "${widget.product.description.substring(0, 150)}..." : widget.product.description),
           style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
         if (widget.product.description.length > 150)
          GestureDetector(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                expanded ? "Show Less" : "Read More",
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.store)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Seller Name", style: TextStyle(fontWeight: FontWeight.bold)), // Placeholder
                  Text("Verified Seller", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
               OutlinedButton.icon(
                 onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text("WhatsApp"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isOutOfStock ? null : () {
             // Logic to add to cart
             // If variants exist, need to pass selected variant
             CartService.addToCart(widget.product, quantity, variant: _selectedVariant);
             Navigator.pushNamed(context, AppRoutes.cart);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isOutOfStock ? Colors.grey : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _isOutOfStock ? "Out of Stock" : "Add to Cart - \$${(_currentPrice * quantity).toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
