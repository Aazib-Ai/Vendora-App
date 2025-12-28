import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/widgets/error_state_widget.dart';
import 'package:vendora/core/widgets/product_card.dart';
import 'package:vendora/core/widgets/skeleton_loader.dart';
import 'package:vendora/models/category_model.dart';
import 'package:vendora/models/product.dart';
import 'package:vendora/features/buyer/presentation/providers/home_provider.dart' show ProductSortOption;

class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts(initial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _products.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final repo = context.read<ProductRepository>();
      final result = await repo.getProducts(
        category: widget.category.id,
        page: _page,
        limit: _limit,
        onlyActive: true,
        onlyApproved: true,
        sortBy: ProductSortOption.newest,
      );
      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
        (items) {
          setState(() {
            _products.addAll(items);
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load products';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _page += 1;
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts(initial: true);
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, __) => const SkeletonLoader(width: double.infinity, height: 200),
        itemCount: 6,
      );
    }

    if (_error != null && _products.isEmpty) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: () => _loadProducts(initial: true),
      );
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = _products[index];
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Added to cart")),
                    );
                  },
                );
              },
              childCount: _products.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

