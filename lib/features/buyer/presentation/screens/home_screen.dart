import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../models/product.dart';
import '../../../../models/category_model.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../providers/home_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/category_quick_access.dart';
import '../widgets/flash_deals_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(
        productRepository: context.read<ProductRepository>(),
        categoryRepository: context.read<CategoryRepository>(),
      )..loadInitialData(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  final ScrollController _scrollController = ScrollController();
  // removed _currentIndex as it's now handled by BuyerShellScreen

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HomeProvider>().loadMore();
    }
  }

  // removed _onNavTap

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
         // Create a wrapper to access provider in modal
         // IMPORTANT: We need to access the provider from the parent context
         // because the bottom sheet is in a different tree subtree.
         // However, since we wrapped HomeScreen with ChangeNotifierProvider, 
         // we might need to pass the provider instance or re-provide it.
         // A cleaner way is to pass the provider value.
         final homeProvider = Provider.of<HomeProvider>(context, listen: false);
         
         return ChangeNotifierProvider.value(
            value: homeProvider,
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) { 
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Sort By",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      _filterOption(
                        context, 
                        "Price: Low → High", 
                        ProductSortOption.priceAsc, 
                        provider
                      ),
                      _filterOption(
                        context, 
                        "Price: High → Low", 
                        ProductSortOption.priceDesc, 
                        provider
                      ),
                      _filterOption(
                        context, 
                        "Newest First", 
                        ProductSortOption.newest, 
                        provider
                      ),
                      _filterOption(
                        context, 
                        "Rating", 
                        ProductSortOption.rating, 
                        provider
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          provider.setSortOption(ProductSortOption.newest);
                          Navigator.pop(context);
                        },
                        child: const Text("Reset Filters"),
                      )
                    ],
                  ),
                );
              }
           ),
         );
      },
    );
  }

  Widget _filterOption(
    BuildContext context, 
    String label, 
    ProductSortOption option, 
    HomeProvider provider
  ) {
    final isSelected = provider.sortOption == option;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.black) : null,
      onTap: () {
        provider.setSortOption(option);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // AppColors.background
      // body handles the content
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<HomeProvider>().refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Header & Search
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // User Greeting
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final user = authProvider.currentUser;
                        return Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Hello, Welcome 👋",
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name ?? "Guest",
                                  style: const TextStyle(
                                    fontSize: 19, 
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.black,
                              backgroundImage: user?.profileImageUrl != null 
                                  ? NetworkImage(user!.profileImageUrl!) 
                                  : null,
                              child: user?.profileImageUrl == null
                                  ? Text(
                                      user?.name.isNotEmpty == true 
                                          ? user!.name[0].toUpperCase() 
                                          : "G",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (value) {
                                context.read<HomeProvider>().setSearchQuery(value);
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade600,
                                  size: 22,
                                ),
                                hintText: "Search products...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey.shade600),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _openFilterSheet(context),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tune, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),

              // 2. Sections (Banner, Categories, Flash Deals)
              // Only show these if not searching/filtering
              SliverToBoxAdapter(
                child: Consumer<HomeProvider>(
                  builder: (context, provider, _) {
                    if (provider.searchQuery.isNotEmpty || 
                        provider.selectedCategoryId != 'All Items') {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: HeroBannerCarousel(),
                        ),
                        const SizedBox(height: 25),
                        CategoryQuickAccess(
                          categories: provider.categories,
                          selectedCategoryId: provider.selectedCategoryId, // Updated to use ID
                          onCategorySelected: (categoryId) {
                             provider.setCategory(categoryId);
                          },
                        ),
                        if (provider.selectedCategoryId != 'All Items') ...[
                          const SizedBox(height: 20),
                          _buildCategoryHeader(context, provider),
                        ],
                        const SizedBox(height: 25),
                        const FlashDealsSection(),
                        const SizedBox(height: 25),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Popular Products",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    );
                  },
                ),
              ),

              // 3. Product Grid
              Consumer<HomeProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.products.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const SkeletonLoader(
                            width: double.infinity, height: 200
                          ),
                          childCount: 4,
                        ),
                      ),
                    );
                  }

                  if (provider.error != null && provider.products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: ErrorStateWidget(
                        message: provider.error!,
                        onRetry: () => provider.refresh(),
                      ),
                    );
                  }

                  if (provider.products.isEmpty) {
                     return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: Text("No products found")
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
// Adjusted aspect ratio to prevent overflow
                        childAspectRatio: 0.58,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = provider.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.productDetails,
                                arguments: product,
                              );
                            },
                            onQuickAddTap: () {
                              // TODO: Implement cart add
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Added to cart")),
                              );
                            },
                          );
                        },
                        childCount: provider.products.length,
                      ),
                    ),
                  );
                },
              ),

              // 4. Loading Indicator at bottom
              SliverToBoxAdapter(
                child: Consumer<HomeProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.products.isNotEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox(height: 40);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryHeader(BuildContext context, HomeProvider provider) {
    final category = provider.categories.firstWhere(
      (c) => c.id == provider.selectedCategoryId,
      orElse: () => Category(
        id: 'unknown',
        sellerId: '',
        name: 'Unknown Category',
        createdAt: DateTime.now(),
      ),
    );

    if (category.id == 'unknown') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (category.iconUrl != null && category.iconUrl!.isNotEmpty)
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(category.iconUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (category.productCount > 0)
                Text(
                  '${category.productCount} Items',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
