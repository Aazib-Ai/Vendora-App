import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/search_bar.dart';
import 'package:vendora/models/demo_data.dart';

class ManageSellersScreen extends StatefulWidget {
  const ManageSellersScreen({super.key});

  @override
  State<ManageSellersScreen> createState() => _ManageSellersScreenState();
}

class _ManageSellersScreenState extends State<ManageSellersScreen> {
  String _selectedFilter = 'All Sellers';

  @override
  Widget build(BuildContext context) {
    final filteredSellers = _selectedFilter == 'All Sellers'
        ? demoSellers
        : demoSellers.where((s) => s.status == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Sellers'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _FilterTab(
                    label: 'All Sellers',
                    isSelected: _selectedFilter == 'All Sellers',
                    onTap: () => setState(() => _selectedFilter = 'All Sellers'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterTab(
                    label: 'Approved',
                    isSelected: _selectedFilter == 'Approved',
                    onTap: () => setState(() => _selectedFilter = 'Approved'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterTab(
                    label: 'Pending',
                    isSelected: _selectedFilter == 'Pending',
                    onTap: () => setState(() => _selectedFilter = 'Pending'),
                  ),
                ),
              ],
            ),
          ),
          // Sellers List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredSellers.length,
              itemBuilder: (context, index) {
                final seller = filteredSellers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: seller.profileImageUrl != null
                          ? AssetImage(seller.profileImageUrl!)
                          : null,
                      child: seller.profileImageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(seller.name),
                    subtitle: Text(seller.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 20),
                          ),
                          onPressed: () {
                            // Approve seller
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                          onPressed: () {
                            // Reject seller
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
