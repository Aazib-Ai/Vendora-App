import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../models/product.dart';
import '../../../../core/routes/app_routes.dart';

class FlashDealsSection extends StatefulWidget {
  const FlashDealsSection({super.key});

  @override
  State<FlashDealsSection> createState() => _FlashDealsSectionState();
}

class _FlashDealsSectionState extends State<FlashDealsSection> {
  late DateTime _endTime;
  late Timer _timer;
  Duration _timeLeft = Duration.zero;
  
  // Real data from database
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _endTime = DateTime.now().add(const Duration(hours: 2, minutes: 45, seconds: 30));
    _startTimer();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<ProductRepository>();
      final result = await repository.getProducts(
        page: 1,
        limit: 5, // Get 5 products for flash deals
        sortBy: ProductSortOption.rating, // Show top-rated products
      );

      result.fold(
        (failure) {
          setState(() {
            _error = 'Failed to load deals';
            _isLoading = false;
          });
        },
        (products) {
          setState(() {
            _products = products;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load deals';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(_endTime)) {
        timer.cancel();
        setState(() => _timeLeft = Duration.zero);
      } else {
        setState(() => _timeLeft = _endTime.difference(now));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Don't show section if no products
    if (!_isLoading && _products.isEmpty && _error == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Flash Deals ⚡',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5), // Soft red background
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCCCC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // Navigate to see all deals
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 270, // Increased height to prevent overflow
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), // Add vertical padding for shadow
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _buildLoadingCard(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), // Add vertical padding for shadow
      scrollDirection: Axis.horizontal,
      itemCount: _products.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return _buildDealCard(_products[index]);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 100, color: Colors.grey.shade100),
                const SizedBox(height: 6),
                Container(height: 14, width: 60, color: Colors.grey.shade100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Product product) {
    // Calculate a simulated discount (20% off for flash deals)
    final originalPrice = (product.basePrice * 1.25).round();
    final discountPercent = 20;
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: product,
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                            )
                          : Image.asset(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                  ),
                  // Discount Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           product.category.toUpperCase(),
                           style: const TextStyle(
                             fontSize: 9, 
                             color: Colors.grey,
                             fontWeight: FontWeight.bold
                           ),
                           maxLines: 1,
                         ),
                         const SizedBox(height: 2),
                         Text(
                           product.name,
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(
                             fontWeight: FontWeight.w600,
                             fontSize: 13,
                             height: 1.2,
                           ),
                         ),
                       ],
                     ),
                     
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Text(
                               product.formattedPrice,
                               style: const TextStyle(
                                 fontWeight: FontWeight.bold,
                                 color: AppColors.primary,
                                 fontSize: 15,
                               ),
                             ),
                             const SizedBox(width: 6),
                             Text(
                               'Rs.$originalPrice',
                               style: TextStyle(
                                 fontSize: 11,
                                 decoration: TextDecoration.lineThrough,
                                 color: Colors.grey.shade400,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 6),
                         // Progress bar for "Sold" - based on stock
                         Row(
                           children: [
                             Expanded(
                               child: Stack(
                                 children: [
                                   Container(
                                     height: 4,
                                     width: double.infinity,
                                     decoration: BoxDecoration(
                                       color: Colors.grey.shade200,
                                       borderRadius: BorderRadius.circular(2),
                                     ),
                                   ),
                                   Container(
                                     height: 4,
                                     width: (130 - (product.stockQuantity * 2.0)).clamp(20.0, 100.0),
                                     decoration: BoxDecoration(
                                       gradient: const LinearGradient(
                                          colors: [AppColors.accent, Color(0xFFFF8A65)]
                                       ),
                                       borderRadius: BorderRadius.circular(2),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                             const SizedBox(width: 6),
                             const Text(
                               'Sold',
                               style: TextStyle(fontSize: 9, color: Colors.grey),
                             )
                           ],
                         ),
                       ],
                     ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
