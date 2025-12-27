import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendora/core/utils/commission_calculator.dart';

void main() {
  group('CommissionCalculator Property Tests', () {
    test('Property 4: Commission Calculation Accuracy', () {
      final random = Random();
      const int iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random gross amount between 0 and 1,000,000 with 2 decimal places
        final double gross = (random.nextDouble() * 1000000).truncateToDouble() / 100 + 
                             (random.nextInt(100) / 100);
        
        final result = CommissionCalculator.calculate(gross);

        // 1. Commission should be approx 10%
        final expectedCommission = double.parse((gross * 0.10).toStringAsFixed(2));
        expect(result.commission, expectedCommission, 
            reason: 'Commission for $gross should be $expectedCommission');

        // 2. Net should be approx 90%
        final expectedNet = double.parse((gross * 0.90).toStringAsFixed(2));
        // Note: floating point math might cause slight mismatch if we just subtract.
        // The implementation does: net = double.parse((gross - commission).toStringAsFixed(2));
        // So we expect: net + commission == gross (roughly, with rounding)
        
        // Let's verify sum matches gross within minimal epsilon (0.01 potentially)
        // Actually, logic: net = gross - commission. So net + commission SHOULD be exactly equal to gross 
        // IF we didn't round intermediate steps logic?
        // Logic: commission = rounded(gross * 0.1). net = rounded(gross - commission).
        // So net + commission = rounded(gross - commission) + commission = gross + error.
        // Wait: result.net = (gross - commission). So result.net + result.commission is mathematically === gross (if parsing doesn't mess it up).
        // Let's check floating point epsilon.
        
        expect((result.net + result.commission).toStringAsFixed(2), gross.toStringAsFixed(2),
            reason: 'Net + Commission must equal Gross');
            
        // 3. Non-negative
        expect(result.commission, greaterThanOrEqualTo(0));
        expect(result.net, greaterThanOrEqualTo(0));
      }
    });

    test('Throws error for negative amount', () {
      expect(() => CommissionCalculator.calculate(-10.0), throwsArgumentError);
    });
  });
}
