import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/common/providers/proposal_provider.dart';
import 'package:vendora/models/proposal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({super.key});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Load proposals
    Future.microtask(() {
       context.read<ProposalProvider>().loadActiveProposals();
    });
  }

  void _startAutoScroll(int itemCount) {
    _timer?.cancel(); // Cancel existing timer if any
    if (itemCount <= 1) return; // No auto-scroll for single item

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_currentPage < itemCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleAction(Proposal proposal) {
    if (proposal.actionType == 'route' && proposal.actionValue != null) {
      Navigator.pushNamed(context, proposal.actionValue!);
    } else if (proposal.actionType == 'url' && proposal.actionValue != null) {
       // TODO: Launch URL
       // launchUrl(Uri.parse(proposal.actionValue!));
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Opening ${proposal.actionValue}')),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProposalProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.proposals.isEmpty) {
          return const SkeletonLoader(width: double.infinity, height: 200);
        }

        if (provider.error != null && provider.proposals.isEmpty) {
           return Container(
             height: 200,
             decoration: BoxDecoration(
               color: Colors.grey[200],
               borderRadius: BorderRadius.circular(20),
             ),
             child: const Center(child: Text('Failed to load banners')),
           );
        }

        final banners = provider.proposals;

        if (banners.isEmpty) {
          return const SizedBox.shrink(); 
        }

        // Restart scroll if count changed (e.g. initial load)
        if (_timer == null || !_timer!.isActive) {
           _startAutoScroll(banners.length);
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  // Parse color
                  Color bgColor = AppColors.primary;
                  try {
                    if (banner.bgColor.startsWith('0x')) {
                       bgColor = Color(int.parse(banner.bgColor));
                    } else {
                       bgColor = Color(int.parse('0xFF${banner.bgColor.replaceAll('#', '')}'));
                    }
                  } catch (_) {}

                  return GestureDetector(
                    onTap: () => _handleAction(banner),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5), // Spacing
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: bgColor,
                      ),
                      child: Stack(
                        children: [
                          // Background Image (if needed, or just color)
                          // Using simple circle decoration as per original design logic
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Opacity(
                              opacity: 0.2,
                              child: const CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          
                          // Actual Image (if provided and valid URL)
                          if (banner.imageUrl.isNotEmpty)
                             Positioned.fill(
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(20),
                                 child: Opacity(
                                   opacity: 0.3, // Blend with color, or remove opacity to show full image
                                   child: Image.network(
                                     banner.imageUrl,
                                     fit: BoxFit.cover,
                                     errorBuilder: (_,__,___) => const SizedBox.shrink(),
                                   ),
                                 ),
                               ),
                             ),

                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    banner.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _handleAction(banner),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: bgColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  child: Text(banner.buttonText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
