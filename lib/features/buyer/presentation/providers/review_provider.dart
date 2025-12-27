import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/review_repository.dart';
import 'package:vendora/models/review.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewRepository _reviewRepository;
  
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewProvider(this._reviewRepository);

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _reviewRepository.getProductReviews(productId);

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (reviews) {
        _reviews = reviews;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> submitReview(Review review) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _reviewRepository.submitReview(review);

    return result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (newReview) {
        _reviews.insert(0, newReview); // Add to top
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }
  
  Future<String?> getReviewableOrderId(String userId, String productId) async {
      final result = await _reviewRepository.getReviewableOrderId(userId, productId);
      return result.fold(
          (l) => null,
          (r) => r
      );
  }
}
