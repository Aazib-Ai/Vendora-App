import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../models/product.dart';
import '../providers/product_form_provider.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/product_variant_form.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product; // If null, creating new product

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _discountController;
  late TextEditingController _categoryController; // Simple text for now, should be dropdown
  
  DateTime? _discountValidUntil;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p?.basePrice.toString() ?? '');
    _stockController = TextEditingController(text: p?.stockQuantity.toString() ?? '');
    _discountController = TextEditingController(text: p?.discountPercentage?.toString() ?? '');
    _categoryController = TextEditingController(text: p?.categoryId ?? '');
    _discountValidUntil = p?.discountValidUntil;

    // Initialize provider if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductFormProvider>(context, listen: false);
      provider.reset();
      if (p != null) {
        provider.initializeForEdit(p);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _discountValidUntil ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _discountValidUntil = picked);
    }
  }

  void _save(ProductFormProvider provider) {
    if (_formKey.currentState!.validate()) {
      if (provider.images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least one image')),
        );
        return;
      }

      // Get actual seller ID from AuthProvider
      final sellerId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (sellerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in')),
        );
        return;
      }

      provider.saveProduct(
        sellerId: sellerId,
        productId: widget.product?.id,
        name: _nameController.text,
        description: _descController.text,
        categoryId: _categoryController.text,
        basePrice: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        discountPercentage: double.tryParse(_discountController.text),
        discountValidUntil: _discountValidUntil,
      ).then((_) {
        if (provider.status == ProductFormStatus.success) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(widget.product == null ? 'Product Created!' : 'Product Updated!')),
           );
        } else if (provider.status == ProductFormStatus.error) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(provider.errorMessage ?? 'Error saving product')),
           );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductFormProvider>(context);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: provider.status == ProductFormStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- IMAGES ---
                    ProductImagePicker(
                      initialImages: provider.images,
                      onImagesChanged: provider.setImages,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- BASIC DETAILS ---
                    const Text('Basic Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category ID (Placeholder)', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- PRICING & INVENTORY ---
                    const Text('Pricing & Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Base Price', prefixText: 'Rs ', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Total Stock', border: OutlineInputBorder()),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null) return 'Invalid number';
                              if (n < 0) return 'Cannot be negative'; // Requirement 16.2
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                     const SizedBox(height: 16),
                     Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Discount %', suffixText: '%', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Discount Valid Until',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _discountValidUntil != null
                                    ? "${_discountValidUntil!.day}/${_discountValidUntil!.month}/${_discountValidUntil!.year}"
                                    : 'Select Date',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- VARIANTS ---
                    ProductVariantForm(
                      initialVariants: provider.variants,
                      onVariantsChanged: provider.setVariants,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _save(provider),
                        child: Text(
                          isEditing ? 'Update Product' : 'Create Product',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
