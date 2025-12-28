import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/category_model.dart';
import '../providers/category_provider.dart';
import '../providers/seller_dashboard_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  String searchQuery = "";
  final TextEditingController _nameController = TextEditingController();
  bool _isLoadingSeller = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadCategories();
  }

  Future<void> _initializeAndLoadCategories() async {
    final dashboardProvider = context.read<SellerDashboardProvider>();
    
    // If seller is not loaded, load it using auth provider's user ID
    if (dashboardProvider.currentSeller == null) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        setState(() => _isLoadingSeller = true);
        await dashboardProvider.loadDashboardData(userId);
        setState(() => _isLoadingSeller = false);
      }
    }
    
    _loadCategories();
  }

  void _loadCategories() {
    final sellerId = context.read<SellerDashboardProvider>().currentSeller?.id;
    if (sellerId != null) {
      context.read<CategoryProvider>().loadCategories(sellerId);
    }
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Category?"),
        content: Text("Are you sure you want to delete '${category.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<CategoryProvider>().deleteCategory(category.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category deleted')),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCategoryModal({Category? category}) {
    final bool isEditing = category != null;
    File? selectedImage;
    String? existingIconUrl = category?.iconUrl;

    if (isEditing) {
      _nameController.text = category.name;
    } else {
      _nameController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text(isEditing ? "Edit Category" : "Add New Category", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                
                // Category Icon Picker
                const Text("Category Icon (Optional)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (pickedFile != null) {
                      setModalState(() {
                        selectedImage = File(pickedFile.path);
                        existingIconUrl = null; // Clear existing URL when new image selected
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : existingIconUrl != null && existingIconUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(existingIconUrl!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade500),
                                  const SizedBox(height: 4),
                                  Text("Add Icon", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildModalTextField("Category Name", _nameController, "e.g. Electronics"),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter a category name')),
                      );
                      return;
                    }

                    final sellerId = this.context.read<SellerDashboardProvider>().currentSeller?.id;
                    if (sellerId == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Error: Seller profile not loaded. Please go back and try again.')),
                      );
                      Navigator.pop(modalContext);
                      return;
                    }

                    // Store values before closing modal
                    final name = _nameController.text.trim();
                    final imageFile = selectedImage;
                    final categoryProvider = this.context.read<CategoryProvider>();
                    
                    Navigator.pop(modalContext);

                    bool success;
                    if (isEditing) {
                      success = await categoryProvider.updateCategory(
                        id: category.id,
                        name: name,
                        iconUrl: existingIconUrl,
                      );
                    } else {
                      success = await categoryProvider.addCategory(
                        sellerId: sellerId,
                        name: name,
                        iconFile: imageFile,
                      );
                    }

                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text(isEditing ? 'Category updated' : 'Category created')),
                        );
                      } else {
                        final error = categoryProvider.error ?? 'Unknown error';
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Failed: $error')),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? "Update Category" : "Create Category", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Manage Categories", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search categories...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoadingSeller
                  ? const Center(child: CircularProgressIndicator())
                  : Consumer<CategoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.categories.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          TextButton(onPressed: _loadCategories, child: const Text('Retry')),
                        ],
                      ),
                    );
                  }

                  final filteredCategories = provider.categories.where((c) {
                    return c.name.toLowerCase().contains(searchQuery.toLowerCase());
                  }).toList();

                  if (filteredCategories.isEmpty) {
                    return const Center(
                      child: Text("No categories yet. Tap + to add one!", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return _categoryListItem(category);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showCategoryModal(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _categoryListItem(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800], 
              shape: BoxShape.circle,
              image: category.iconUrl != null && category.iconUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(category.iconUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: category.iconUrl == null || category.iconUrl!.isEmpty
                ? const Icon(Icons.category_outlined, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${category.productCount} Items",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit_note, color: Colors.white, size: 22),
                      onPressed: () => _showCategoryModal(category: category),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
                      onPressed: () => _confirmDelete(category),
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
}