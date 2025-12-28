import 'package:flutter/material.dart' hide Category;
import '../../../../core/theme/app_colors.dart';

import '../../../../models/category_model.dart';

class CategoryQuickAccess extends StatelessWidget {
  final List<Category> categories;
  final String selectedCategoryId; // ID of selected category
  final Function(String) onCategorySelected;

  const CategoryQuickAccess({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Icons mapping for fallback - demo categories keys
    final Map<String, IconData> categoryFallbackIcons = {
      'Clothes': Icons.checkroom,
      'Shoes': Icons.snowshoeing,
      'Watches': Icons.watch,
      'Jewelry': Icons.diamond,
      'Electronics': Icons.smartphone,
      'Home': Icons.chair,
      'Books': Icons.menu_book,
    };

    // Include 'All Items' as the first option if not present
    final allItemsSelected = selectedCategoryId == 'All Items';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // TextButton(
              //   onPressed: () {},
              //   child: const Text('See All'),
              // ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            // +1 for "All Items"
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryItem(
                  name: 'All Items',
                  icon: Icons.grid_view,
                  isSelected: allItemsSelected,
                  onTap: () => onCategorySelected('All Items'),
                );
              }

              final category = categories[index - 1];
              final isSelected = category.id == selectedCategoryId;
              
              // Determine icon
              Widget iconWidget;
              if (category.iconUrl != null && category.iconUrl!.isNotEmpty) {
                iconWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    category.iconUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                     categoryFallbackIcons[category.name] ?? Icons.category,
                     color: isSelected ? Colors.white : AppColors.primary,
                     size: 28,
                    ),
                  ),
                );
              } else {
                 iconWidget = Icon(
                   categoryFallbackIcons[category.name] ?? Icons.category,
                   color: isSelected ? Colors.white : AppColors.primary,
                   size: 28,
                 );
              }

              return _buildCategoryItem(
                name: category.name,
                iconWidget: iconWidget,
                isSelected: isSelected,
                onTap: () => onCategorySelected(category.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem({
    required String name,
    IconData? icon,
    Widget? iconWidget,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: isSelected ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: iconWidget ?? Icon(
                icon ?? Icons.category,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
