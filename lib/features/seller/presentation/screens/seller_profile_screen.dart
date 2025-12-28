import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/theme/app_colors.dart';
import 'package:vendora/features/seller/presentation/providers/seller_dashboard_provider.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import '../../../../core/widgets/animated_button.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _whatsappController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final seller = context.read<SellerDashboardProvider>().currentSeller;
    _nameController = TextEditingController(text: seller?.businessName ?? '');
    _descController = TextEditingController(text: seller?.description ?? '');
    _whatsappController = TextEditingController(text: seller?.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<SellerDashboardProvider>();
    final currentSeller = provider.currentSeller;

    if (currentSeller != null) {
      final updatedSeller = currentSeller.copyWith(
        businessName: _nameController.text,
        description: _descController.text,
        whatsappNumber: _whatsappController.text,
      );

      final repository = context.read<SellerRepository>();
      final result = await repository.updateSellerProfile(updatedSeller);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${failure.message}')),
            );
          }
        },
        (seller) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context);
          }
        },
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.chat),
                  helperText: 'Include country code (e.g., +1234567890)',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                text: 'Save Changes',
                onPressed: _isLoading ? () {} : _saveProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showSignOutDialog(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }
}
