import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/models/demo_data.dart';
import 'package:vendora/models/product_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All Items";
  String searchQuery = "";
  int _currentIndex = 2;

  // Sorting mode
  String sortMode = "none";

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.buyerNotifications);

        break;

      case 1:
        Navigator.pushNamed(context, AppRoutes.cart);
        break;

      case 2:
        break;

      case 3:
        Navigator.pushNamed(context, AppRoutes.settings);
        break;

      case 4:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
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

              _filterOption("Price: Low → High", "low_high"),
              _filterOption("Price: High → Low", "high_low"),
              _filterOption("Newest First", "newest"),
              _filterOption("Oldest First", "oldest"),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() => sortMode = "none");
                  Navigator.pop(context);
                },
                child: const Text("Clear Filters"),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _filterOption(String label, String mode) {
    return ListTile(
      title: Text(label),
      trailing:
      sortMode == mode ? const Icon(Icons.check, color: Colors.black) : null,
      onTap: () {
        setState(() => sortMode = mode);
        Navigator.pop(context);
      },
    );
  }

  List<Product> _applySorting(List<Product> list) {
    switch (sortMode) {
      case "low_high":
        list.sort((a, b) => a.price.compareTo(b.price));
        break;

      case "high_low":
        list.sort((a, b) => b.price.compareTo(a.price));
        break;

      case "newest":
        list.sort((a, b) => b.id.compareTo(a.id)); // assuming higher id = newer
        break;

      case "oldest":
        list.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categoryTabs = categories;

    List<Product> filtered = demoProducts.where((p) {
      final matchesCategory =
          selectedCategory == "All Items" || p.category == selectedCategory;

      final matchesSearch = searchQuery.isEmpty
          ? true
          : p.name.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    filtered = _applySorting(filtered);

    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.buyer,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),

                // HEADER
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Hello, Welcome 👋",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Aryan Mirza",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage("assets/images/profile.png"),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // SEARCH + FILTER
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade600,
                              size: 22,
                            ),
                            hintText: "Search clothes...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // FILTER BUTTON
                    GestureDetector(
                      onTap: _openFilterSheet,
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

                const SizedBox(height: 16),

                // CATEGORY TABS
                SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = categoryTabs[index];
                      final isSelected = selectedCategory == cat;

                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedCategory = cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // PRODUCT GRID (bigger images + tighter spacing)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.56, // taller image
                  ),
                  itemBuilder: (context, index) {
                    final product = filtered[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                          arguments: product,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                product.imageUrl,
                                height: 210, // bigger images
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              product.name,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            Text(
                              product.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Text(
                                  product.formattedPrice,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 14),
                                Text(product.rating.toString(),
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
