import 'package:flutter/foundation.dart';
import 'package:vendora/features/admin/domain/entities/admin_analytics_data.dart';
import 'package:vendora/features/admin/domain/entities/commission_data.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';

enum AnalyticsDateRange {
  last7Days,
  last30Days,
  last90Days,
  custom,
}

enum AnalyticsState {
  initial,
  loading,
  loaded,
  error,
}

class AdminAnalyticsProvider extends ChangeNotifier {
  final IAdminRepository _repository;

  AdminAnalyticsProvider(this._repository);

  AnalyticsState _state = AnalyticsState.initial;
  AnalyticsDateRange _selectedRange = AnalyticsDateRange.last30Days;
  AdminAnalyticsData? _analyticsData;
  CommissionData? _commissionData;
  String? _errorMessage;

  AnalyticsState get state => _state;
  AnalyticsDateRange get selectedRange => _selectedRange;
  AdminAnalyticsData? get analyticsData => _analyticsData;
  CommissionData? get commissionData => _commissionData;
  String? get errorMessage => _errorMessage;

  DateTime get startDate {
    final now = DateTime.now();
    switch (_selectedRange) {
      case AnalyticsDateRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case AnalyticsDateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case AnalyticsDateRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case AnalyticsDateRange.custom:
        // For custom, use last 30 days as default
        return now.subtract(const Duration(days: 30));
    }
  }

  DateTime get endDate => DateTime.now();

  void setDateRange(AnalyticsDateRange range) {
    _selectedRange = range;
    notifyListeners();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    _state = AnalyticsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch analytics data
      final analyticsResult = await _repository.getAnalyticsData(
        startDate: startDate,
        endDate: endDate,
      );

      analyticsResult.fold(
        (failure) {
          _state = AnalyticsState.error;
          _errorMessage = failure.toString();
        },
        (data) {
          _analyticsData = data;
        },
      );

      // Fetch commission data
      if (_state != AnalyticsState.error) {
        final commissionResult = await _repository.getCommissionTracking(
          startDate: startDate,
          endDate: endDate,
        );

        commissionResult.fold(
          (failure) {
            _state = AnalyticsState.error;
            _errorMessage = failure.toString();
          },
          (data) {
            _commissionData = data;
            _state = AnalyticsState.loaded;
          },
        );
      }
    } catch (e) {
      _state = AnalyticsState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchAnalytics();
  }
}
