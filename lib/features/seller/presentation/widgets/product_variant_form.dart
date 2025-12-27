import 'package:flutter/material.dart';

class ProductVariantForm extends StatefulWidget {
  final List<Map<String, dynamic>> initialVariants;
  final Function(List<Map<String, dynamic>>) onVariantsChanged;

  const ProductVariantForm({
    super.key,
    required this.initialVariants,
    required this.onVariantsChanged,
  });

  @override
  State<ProductVariantForm> createState() => _ProductVariantFormState();
}

class _ProductVariantFormState extends State<ProductVariantForm> {
  late List<Map<String, dynamic>> _variants;

  @override
  void initState() {
    super.initState();
    _variants = List.from(widget.initialVariants);
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'sku': '',
        'size': '',
        'color': '',
        'material': '',
        'price': 0.0,
        'stock_quantity': 0,
      });
      widget.onVariantsChanged(_variants);
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      widget.onVariantsChanged(_variants);
    });
  }

  void _updateVariant(int index, String key, dynamic value) {
    setState(() {
      _variants[index][key] = value;
      widget.onVariantsChanged(_variants);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Variants',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addVariant,
              icon: const Icon(Icons.add),
              label: const Text('Add Variant'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('No variants added. Add one to manage stock.'),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _variants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildVariantCard(index, _variants[index]),
          ),
      ],
    );
  }

  Widget _buildVariantCard(int index, Map<String, dynamic> variant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Variant #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeVariant(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Size',
                  value: variant['size'],
                  onChanged: (v) => _updateVariant(index, 'size', v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Color',
                  value: variant['color'],
                  onChanged: (v) => _updateVariant(index, 'color', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Price',
                  value: variant['price'].toString(),
                  isNumber: true,
                  onChanged: (v) => _updateVariant(index, 'price', double.tryParse(v) ?? 0.0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Stock',
                  value: variant['stock_quantity'].toString(),
                  isNumber: true,
                  onChanged: (v) => _updateVariant(index, 'stock_quantity', int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'SKU (Optional)',
            value: variant['sku'] ?? '',
            onChanged: (v) => _updateVariant(index, 'sku', v),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    bool isNumber = false,
  }) {
    return TextFormField(
      initialValue: value == '0' || value == '0.0' ? '' : value,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
