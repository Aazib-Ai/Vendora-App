import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/buyer/presentation/providers/address_provider.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/features/cart/presentation/providers/cart_provider.dart';
import 'package:vendora/features/buyer/presentation/providers/checkout_provider.dart';
import 'package:vendora/features/buyer/presentation/screens/address_book_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<AddressProvider>().loadAddresses(userId);
      }
    });
  }

  void _placeOrder() async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final addressProvider = context.read<AddressProvider>();
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    final user = authProvider.currentUser;
    final address = addressProvider.selectedAddress;
    final cartItems = cartProvider.items;

    if (user == null) return;

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address')),
      );
      return;
    }

    final order = await checkoutProvider.placeOrder(
      userId: user.id,
      address: address,
      cartItems: cartItems,
    );

    if (order != null && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.orderComplete,
        (route) => false,
      );
    } else if (checkoutProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${checkoutProvider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer3<AddressProvider, CartProvider, CheckoutProvider>(
        builder: (context, addressProv, cartProv, checkoutProv, child) {
          if (checkoutProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STEP 1: Delivery Address
                const Text(
                  'Shipping Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (addressProv.selectedAddress != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      addressProv.selectedAddress!.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(addressProv.selectedAddress!.addressText),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddressBookScreen(),
                                ),
                              );
                            },
                            child: Text(addressProv.selectedAddress == null
                                ? 'Select Address'
                                : 'Change Address'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // STEP 2: Payment Method
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: CheckoutProvider.paymentMethods.map((method) {
                      return RadioListTile<String>(
                        title: Text(method),
                        value: method,
                        groupValue: checkoutProv.paymentMethod,
                        onChanged: (value) {
                          if (value != null) {
                            checkoutProv.setPaymentMethod(value);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // STEP 3: Order Summary
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal (${cartProv.items.length} items)',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text('\$${cartProv.cartTotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text('Shipping Fee', style: TextStyle(color: Colors.grey[600])),
                             const Text('\$0.00'), // Free shipping for now or calc?
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${cartProv.cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
