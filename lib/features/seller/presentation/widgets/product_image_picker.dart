import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ProductImagePicker extends StatefulWidget {
  final List<dynamic> initialImages; // Can be File or String (URL)
  final Function(List<dynamic>) onImagesChanged;

  const ProductImagePicker({
    super.key,
    required this.initialImages,
    required this.onImagesChanged,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  late List<dynamic> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      final newFiles = result.paths.map((path) => File(path!)).toList();
      setState(() {
        _images.addAll(newFiles);
        widget.onImagesChanged(_images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      widget.onImagesChanged(_images);
    });
  }

  void _setPrimary(int index) {
    // Move the selected image to the first position
    setState(() {
      final image = _images.removeAt(index);
      _images.insert(0, image);
      widget.onImagesChanged(_images);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'First image will be the primary image. Drag to reorder.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _images.isEmpty
            ? _buildUploadButton()
            : ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _images.removeAt(oldIndex);
                    _images.insert(newIndex, item);
                    widget.onImagesChanged(_images);
                  });
                },
                children: [
                  for (int i = 0; i < _images.length; i++)
                    _buildImageTile(i, _images[i]),
                ],
              ),
        if (_images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add More Images'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Click to upload images',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index, dynamic image) {
    return Container(
      key: ValueKey(image),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: image is File
                  ? FileImage(image)
                  : NetworkImage(image as String) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          index == 0 ? 'Primary Image' : 'Image ${index + 1}',
          style: TextStyle(
            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
            color: index == 0 ? Colors.green : Colors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != 0)
              IconButton(
                icon: const Icon(Icons.star_border),
                tooltip: 'Set as Primary',
                onPressed: () => _setPrimary(index),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeImage(index),
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
