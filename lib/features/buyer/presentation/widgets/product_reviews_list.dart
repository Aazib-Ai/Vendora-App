import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:vendora/features/buyer/presentation/providers/review_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductReviewsList extends StatefulWidget {
  final String productId;
  
  const ProductReviewsList({super.key, required this.productId});

  @override
  State<ProductReviewsList> createState() => _ProductReviewsListState();
}

class _ProductReviewsListState extends State<ProductReviewsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
           return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No reviews yet. Be the first to review!"),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.reviews.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final review = provider.reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                         RatingBarIndicator(
                          rating: review.rating.toDouble(),
                          itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                        const SizedBox(width: 8),
                         Text(
                          timeago.format(review.createdAt),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (review.comment != null && review.comment!.isNotEmpty)
                  Text(review.comment!),
                
                if (review.sellerReply != null && review.sellerReply!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12, left: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.lall(color: Colors.grey.shade300), // Typo check: Border.all
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Seller Reply:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(review.sellerReply!, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
