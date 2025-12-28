import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/features/cart/presentation/providers/cart_provider.dart';
import 'package:vendora/models/cart_item_model.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart' as auth;

class CartScreen extends StatefulWidget {
  final bool isTab;
  const CartScreen({super.key, this.isTab = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  void _loadCart() {
    final user = context.read<auth.AuthProvider>().currentUser;
    if (user != null) {
      context.read<CartProvider>().loadCart(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.isTab ? null : InkWell(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
        ),
        automaticallyImplyLeading: !widget.isTab,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          "My Cart",
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if(cartProvider.error != null) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(cartProvider.error!, style: const TextStyle(color: Colors.red)),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: _loadCart, child: const Text('Retry'))
                ],
              ),
            );
          }

          if (cartProvider.items.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("Your cart is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Start shopping to see items here", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadCart(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return _CartItemWidget(item: item);
                    },
                  ),
                ),
              ),
              _buildCheckoutSection(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coupon Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter Coupon Code',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                 TextButton(
                  onPressed: () {},
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Order Summary
          _priceRow("Subtotal (${provider.itemCount} items)", provider.subtotal),
          _priceRow("Shipping Fee", 0), // hardcoded for now
          _priceRow("Discount", 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, thickness: 1),
          ),
          _priceRow("Total", provider.cartTotal, bold: true),
          const SizedBox(height: 16),

          // PROCEED BUTTON
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
               boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                   // Navigate to checkout
                   Navigator.pushNamed(context, AppRoutes.checkout);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Proceed to Checkout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Optional arrow
                       const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: bold ? Colors.black : Colors.grey[700],
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              )),
          Text(
            value == 0 && label == "Shipping Fee" ? "FREE" : "PKR ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: value == 0 && label == "Shipping Fee" ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;

  const _CartItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                        ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                         context.read<CartProvider>().removeFromCart(item.id);
                      },
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Variant placeholder if we had it
                // Text("Size: M | Color: Blue", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PKR ${item.unitPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    
                    // Quantity Control
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _qtyButton(Icons.remove, () {
                            if (item.quantity > 1) {
                              context.read<CartProvider>().updateQuantity(item.id, item.quantity - 1);
                            } else {
                              context.read<CartProvider>().removeFromCart(item.id);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "${item.quantity}",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          _qtyButton(Icons.add, () {
                             context.read<CartProvider>().updateQuantity(item.id, item.quantity + 1);
                          }),
                        ],
                      ),
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

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          // border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, size: 16, color: Colors.black),
      ),
    );
  }
}
