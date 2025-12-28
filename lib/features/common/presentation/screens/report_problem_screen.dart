import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/support_ticket_model.dart';
import '../providers/support_provider.dart';
import '../../../../services/image_upload_service.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      if (_selectedImages.length + pickedFiles.length > 5) {
        if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only attach up to 5 images.')),
        );
        return;
      }
      
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to report a problem.')),
      );
      return;
    }

    setState(() {
        _isUploadingImages = true;
    });

    List<String> imageUrls = [];
    if (_selectedImages.isNotEmpty) {
       try {
           final imageUploadService = context.read<IImageUploadService>();
           for (var imageFile in _selectedImages) {
                // Upload image logic. Assuming a method like uploadImage exists.
                // Since I checked Main.dart and it provides IImageUploadService (R2ImageUploadService).
                // I need to check the interface of IImageUploadService.
                // Assuming uploadImage(File file, String folder) -> String url
                // Arguments are named: file, bucket, path
                final urlResult = await imageUploadService.uploadImage(
                  file: imageFile, 
                  bucket: 'support', 
                  path: 'tickets'
                );
                
                urlResult.fold(
                  (failure) => throw Exception(failure.message),
                  (url) => imageUrls.add(url),
                );
           }
       } catch (e) {
           setState(() {
               _isUploadingImages = false;
           });
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload images: $e')),
           );
           return;
       }
    }

    setState(() {
        _isUploadingImages = false;
    });

    try {
      await context.read<SupportProvider>().submitTicket(
            userId: userId,
            type: TicketType.report_problem,
            subject: _subjectController.text.trim(),
            message: _descriptionController.text.trim(),
            images: imageUrls.isNotEmpty ? imageUrls : null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully! Thank you for your feedback.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
            final isLoading = provider.isLoading || _isUploadingImages;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Something went wrong?',
                    style: AppTypography.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please describe the issue in detail so we can fix it as soon as possible.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Issue Subject',
                      hintText: 'e.g., App crashes on login',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe what happened...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Screenshots (Optional)',
                    style: AppTypography.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedImages.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                entry.value,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_selectedImages.length < 5)
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Icon(Icons.add_a_photo, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
