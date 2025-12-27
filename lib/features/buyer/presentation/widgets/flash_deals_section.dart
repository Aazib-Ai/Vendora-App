import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FlashDealsSection extends StatefulWidget {
  const FlashDealsSection({super.key});

  @override
  State<FlashDealsSection> createState() => _FlashDealsSectionState();
}

class _FlashDealsSectionState extends State<FlashDealsSection> {
  // Hardcoded end time for demo: 2 hours from now
  late DateTime _endTime;
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _endTime = DateTime.now().add(const Duration(hours: 2, minutes: 45, seconds: 30));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(_endTime)) {
        timer.cancel();
        setState(() => _timeLeft = Duration.zero);
      } else {
        setState(() => _timeLeft = _endTime.difference(now));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Flash Deals ⚡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(_timeLeft),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace', // Monospaced for stable width
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('See All'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Demo items
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildDealCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDealCard(int index) {
    // Demo data
    final deals = [
      {'name': 'Linen Chair', 'price': '321', 'oldPrice': '500', 'image': 'assets/images/chair1.png'},
      {'name': 'Pearl Lamp', 'price': '191', 'oldPrice': '250', 'image': 'assets/images/lamp.png'},
      {'name': 'Modern Sofa', 'price': '899', 'oldPrice': '1200', 'image': 'assets/images/sofa.png'},
    ];

    final deal = deals[index % deals.length];

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Image.asset(
                  deal['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Info
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   deal['name']!,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: const TextStyle(fontWeight: FontWeight.w600),
                 ),
                 const SizedBox(height: 4),
                 Row(
                   children: [
                     Text(
                       '\$${deal['price']}',
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         color: AppColors.accent,
                       ),
                     ),
                     const SizedBox(width: 6),
                     Text(
                       '\$${deal['oldPrice']}',
                       style: TextStyle(
                         fontSize: 12,
                         decoration: TextDecoration.lineThrough,
                         color: Colors.grey.shade500,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 // Progress bar for "Sold"
                 Stack(
                   children: [
                     Container(
                       height: 4,
                       width: double.infinity,
                       decoration: BoxDecoration(
                         color: Colors.grey.shade200,
                         borderRadius: BorderRadius.circular(2),
                       ),
                     ),
                     Container(
                       height: 4,
                       width: 80, // Random progress
                       decoration: BoxDecoration(
                         color: AppColors.accent,
                         borderRadius: BorderRadius.circular(2),
                       ),
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
