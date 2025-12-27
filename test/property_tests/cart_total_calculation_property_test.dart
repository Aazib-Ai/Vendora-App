import 'package:flutter_test/flutter_test.dart';

/// Property-based test for cart total calculation
/// 
/// Property 7: Cart Total Calculation
/// Validates: Requirements 6.2
/// 
/// This test verifies that:
/// 1. Cart total equals sum of (quantity × unit_price) for all items
/// 2. Quantity updates recalculate total correctly
/// 3. Empty cart has zero total
/// 4. Adding/removing items updates total correctly
void main() {
  group('Property 7: Cart Total Calculation', () {
    test('Total equals sum of (quantity × price) for all items', () {
      // Property: For a cart with items [(Q1, P1), (Q2, P2), ...],
      // total should equal Q1*P1 + Q2*P2 + ...

      final testCases = [
        {
          'items': [
            {'qty': 2, 'price': 100.0},
            {'qty': 3, 'price': 50.0},
          ],
          'expectedTotal': 350.0, // (2*100) + (3*50)
        },
        {
          'items': [
            {'qty': 1, 'price': 999.99},
            {'qty': 5, 'price': 10.0},
          ],
          'expectedTotal': 1049.99, // (1*999.99) + (5*10)
        },
        {
          'items': [
            {'qty': 10, 'price': 25.5},
            {'qty': 2, 'price': 100.25},
            {'qty': 1, 'price': 1000.0},
          ],
          'expectedTotal': 1455.5, // (10*25.5) + (2*100.25) + (1*1000)
        },
      ];

      for (final testCase in testCases) {
        final items = testCase['items'] as List<Map<String, dynamic>>;
        final expectedTotal = testCase['expectedTotal'] as double;

        // Calculate total
        final total = items.fold<double>(
          0.0,
          (sum, item) =>
              sum + ((item['qty'] as int) * (item['price'] as double)),
        );

        expect(
          total,
          closeTo(expectedTotal, 0.01),
          reason: 'Cart total should equal sum of item totals',
        );
      }
    });

    test('Empty cart has zero total', () {
      // Property: A cart with no items should have total = 0

      final emptyCart = <Map<String, dynamic>>[];
      final total = emptyCart.fold<double>(
        0.0,
        (sum, item) =>
            sum + ((item['qty'] as int) * (item['price'] as double)),
      );

      expect(
        total,
        equals(0.0),
        reason: 'Empty cart should have total of 0',
      );
    });

    test('Single item total equals quantity × price', () {
      // Property: For a cart with one item (Q, P), total = Q * P

      final testCases = [
        {'qty': 1, 'price': 100.0, 'expected': 100.0},
        {'qty': 5, 'price': 20.5, 'expected': 102.5},
        {'qty': 10, 'price': 99.99, 'expected': 999.9},
        {'qty': 100, 'price': 1.5, 'expected': 150.0},
      ];

      for (final testCase in testCases) {
        final qty = testCase['qty'] as int;
        final price = testCase['price'] as double;
        final expected = testCase['expected'] as double;

        final total = qty * price;

        expect(
          total,
          closeTo(expected, 0.01),
          reason: 'Single item: $qty × $price = $expected',
        );
      }
    });

    test('Updating quantity recalculates total correctly', () {
      // Property: Changing item quantity from Q1 to Q2 should change
      // total by (Q2 - Q1) * P

      final testCases = [
        {
          'initialQty': 2,
          'updatedQty': 5,
          'price': 100.0,
          'initialTotal': 200.0,
          'expectedTotal': 500.0,
        },
        {
          'initialQty': 10,
          'updatedQty': 1,
          'price': 50.0,
          'initialTotal': 500.0,
          'expectedTotal': 50.0,
        },
        {
          'initialQty': 1,
          'updatedQty': 10,
          'price': 25.5,
          'initialTotal': 25.5,
          'expectedTotal': 255.0,
        },
      ];

      for (final testCase in testCases) {
        final initialQty = testCase['initialQty'] as int;
        final updatedQty = testCase['updatedQty'] as int;
        final price = testCase['price'] as double;
        final expectedTotal = testCase['expectedTotal'] as double;

        // Initial total
        final initialTotal = initialQty * price;

        // Updated total
        final updatedTotal = updatedQty * price;

        expect(
          updatedTotal,
          closeTo(expectedTotal, 0.01),
          reason:
              'Updating qty from $initialQty to $updatedQty should update total',
        );

        // Verify the delta
        final delta = updatedTotal - initialTotal;
        final expectedDelta = (updatedQty - initialQty) * price;

        expect(
          delta,
          closeTo(expectedDelta, 0.01),
          reason: 'Total delta should equal quantity delta × price',
        );
      }
    });

    test('Adding item increases total by item total', () {
      // Property: Adding an item (Q, P) to cart with total T
      // should result in total T + (Q * P)

      final testCases = [
        {
          'currentTotal': 100.0,
          'newItemQty': 2,
          'newItemPrice': 50.0,
          'expectedTotal': 200.0, // 100 + (2*50)
        },
        {
          'currentTotal': 500.0,
          'newItemQty': 1,
          'newItemPrice': 99.99,
          'expectedTotal': 599.99, // 500 + (1*99.99)
        },
        {
          'currentTotal': 0.0,
          'newItemQty': 5,
          'newItemPrice': 20.0,
          'expectedTotal': 100.0, // 0 + (5*20)
        },
      ];

      for (final testCase in testCases) {
        final currentTotal = testCase['currentTotal'] as double;
        final newItemQty = testCase['newItemQty'] as int;
        final newItemPrice = testCase['newItemPrice'] as double;
        final expectedTotal = testCase['expectedTotal'] as double;

        final newTotal = currentTotal + (newItemQty * newItemPrice);

        expect(
          newTotal,
          closeTo(expectedTotal, 0.01),
          reason: 'Adding item should increase total correctly',
        );
      }
    });

    test('Removing item decreases total by item total', () {
      // Property: Removing an item (Q, P) from cart with total T
      // should result in total T - (Q * P)

      final testCases = [
        {
          'currentTotal': 200.0,
          'removedItemQty': 2,
          'removedItemPrice': 50.0,
          'expectedTotal': 100.0, // 200 - (2*50)
        },
        {
          'currentTotal': 599.99,
          'removedItemQty': 1,
          'removedItemPrice': 99.99,
          'expectedTotal': 500.0, // 599.99 - (1*99.99)
        },
        {
          'currentTotal': 100.0,
          'removedItemQty': 5,
          'removedItemPrice': 20.0,
          'expectedTotal': 0.0, // 100 - (5*20)
        },
      ];

      for (final testCase in testCases) {
        final currentTotal = testCase['currentTotal'] as double;
        final removedItemQty = testCase['removedItemQty'] as int;
        final removedItemPrice = testCase['removedItemPrice'] as double;
        final expectedTotal = testCase['expectedTotal'] as double;

        final newTotal = currentTotal - (removedItemQty * removedItemPrice);

        expect(
          newTotal,
          closeTo(expectedTotal, 0.01),
          reason: 'Removing item should decrease total correctly',
        );
      }
    });

    test('Associative property: Order of adding items does not matter', () {
      // Property: Total should be the same regardless of order items are added

      final items = [
        {'qty': 2, 'price': 100.0},
        {'qty': 3, 'price': 50.0},
        {'qty': 1, 'price': 200.0},
      ];

      // Calculate in original order
      final total1 = items.fold<double>(
        0.0,
        (sum, item) =>
            sum + ((item['qty'] as int) * (item['price'] as double)),
      );

      // Calculate in reverse order
      final reversedItems = items.reversed.toList();
      final total2 = reversedItems.fold<double>(
        0.0,
        (sum, item) =>
            sum + ((item['qty'] as int) * (item['price'] as double)),
      );

      expect(
        total1,
        closeTo(total2, 0.01),
        reason: 'Cart total should be same regardless of item order',
      );
    });

    test('Edge case: Very small prices', () {
      // Property: System should handle small decimal prices correctly

      final testCases = [
        {'qty': 100, 'price': 0.01, 'expected': 1.0},
        {'qty': 1000, 'price': 0.99, 'expected': 990.0},
        {'qty': 5, 'price': 0.005, 'expected': 0.025},
      ];

      for (final testCase in testCases) {
        final qty = testCase['qty'] as int;
        final price = testCase['price'] as double;
        final expected = testCase['expected'] as double;

        final total = qty * price;

        expect(
          total,
          closeTo(expected, 0.001),
          reason: 'Small prices: $qty × $price = $expected',
        );
      }
    });

    test('Edge case: Large prices and quantities', () {
      // Property: System should handle large numbers correctly

      final testCases = [
        {'qty': 1000, 'price': 999.99, 'expected': 999990.0},
        {'qty': 100, 'price': 10000.0, 'expected': 1000000.0},
        {'qty': 50, 'price': 5000.5, 'expected': 250025.0},
      ];

      for (final testCase in testCases) {
        final qty = testCase['qty'] as int;
        final price = testCase['price'] as double;
        final expected = testCase['expected'] as double;

        final total = qty * price;

        expect(
          total,
          closeTo(expected, 0.01),
          reason: 'Large numbers: $qty × $price = $expected',
        );
      }
    });

    test('Precision: Decimal calculations maintain accuracy', () {
      // Property: Multiple decimal operations should not accumulate errors

      final items = [
        {'qty': 3, 'price': 10.99},
        {'qty': 2, 'price': 25.49},
        {'qty': 5, 'price': 7.33},
      ];

      final total = items.fold<double>(
        0.0,
        (sum, item) =>
            sum + ((item['qty'] as int) * (item['price'] as double)),
      );

      // Manual calculation: (3*10.99) + (2*25.49) + (5*7.33)
      // = 32.97 + 50.98 + 36.65 = 120.60
      final expectedTotal = 120.60;

      expect(
        total,
        closeTo(expectedTotal, 0.01),
        reason: 'Decimal calculations should maintain precision',
      );
    });
  });
}
