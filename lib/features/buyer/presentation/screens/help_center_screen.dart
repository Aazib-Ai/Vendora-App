import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/search_bar.dart';
import 'package:vendora/models/demo_data.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    // REAL-TIME FILTER
    final filtered = helpTopics.where((topic) {
      final q = query.toLowerCase();
      return topic["question"]!.toLowerCase().contains(q) ||
          topic["answer"]!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help Center'),
        elevation: 0,
      ),

      body: Column(
        children: [
          // ---------------------------------------
          // 🔍 SEARCH BAR (uses your own component)
          // ---------------------------------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchBar(
              hintText: 'Search for help...',
              onChanged: (value) {
                setState(() => query = value);
              },
            ),
          ),

          // ---------------------------------------
          // 📌 HELP TOPICS LIST
          // ---------------------------------------
          Expanded(
            child: filtered.isEmpty
                ? const Center(
              child: Text(
                "No results found.",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['question']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['answer']!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
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
