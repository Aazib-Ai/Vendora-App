import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vendora/core/data/repositories/cart_repository.dart';
import 'package:vendora/features/cart/presentation/providers/cart_provider.dart';
import 'package:vendora/models/cart_item_model.dart';
import 'package:vendora/core/errors/failures.dart';

// Generate mock using mockito
@GenerateMocks([ICartRepository])
import 'cart_logic_test.mocks.dart';

void main() {
  group('CartItem Serialization', () {
    test('should correctly serialize and deserialize CartItem', () {
      final now = DateTime.now();
      final item = CartItem(
        id: '1',
        userId: 'user1',
        productId: 'prod1',
        productName: 'Test Product',
        quantity: 2,
        unitPrice: 100.0,
        imageUrl: 'http://test.com/image.jpg',
        createdAt: now,
      );

      final json = item.toJson();
      final fromJson = CartItem.fromJson(json);

      expect(fromJson, equals(item));
      // Compare truncated dates to handle microsecond precision differences in some environments if needed
      // But Equatable should handle equality if deserialization logic is correct and preserves precision or parses equivalent string
    });

    test('should calculate total correctly', () {
      final item = CartItem(
        id: '1',
        userId: 'user1',
        productId: 'prod1',
        productName: 'Test Product',
        quantity: 3,
        unitPrice: 50.0,
        createdAt: DateTime.now(),
      );

      expect(item.total, 150.0);
    });
  });

  group('CartProvider Logic', () {
    late CartProvider provider;
    late MockICartRepository mockRepo;

    setUp(() {
      mockRepo = MockICartRepository();
      provider = CartProvider(mockRepo);
    });

    final testItem = CartItem(
      id: '1',
      userId: 'user1',
      productId: 'prod1',
      productName: 'Test Product',
      quantity: 1,
      unitPrice: 100.0,
      createdAt: DateTime.now(),
    );

    test('loadCart should update items list on success', () async {
      when(mockRepo.getCartItems('user1'))
          .thenAnswer((_) async => Right([testItem]));

      await provider.loadCart('user1');

      expect(provider.items.length, 1);
      expect(provider.items.first, testItem);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('loadCart should update error on failure', () async {
      when(mockRepo.getCartItems('user1'))
          .thenAnswer((_) async => const Left(ServerFailure('Error')));

      await provider.loadCart('user1');

      expect(provider.items, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, 'Error');
    });

    test('updateQuantity should update item in list', () async {
      // First populate
      when(mockRepo.getCartItems('user1'))
          .thenAnswer((_) async => Right([testItem]));
      await provider.loadCart('user1');

      final updatedItem = testItem.copyWith(quantity: 2);
      when(mockRepo.updateCartItem(cartItemId: '1', quantity: 2))
          .thenAnswer((_) async => Right(updatedItem));

      await provider.updateQuantity('1', 2);

      expect(provider.items.first.quantity, 2);
      expect(provider.cartTotal, 200.0);
    });

    test('removeFromCart should remove item from list', () async {
      // First populate
      when(mockRepo.getCartItems('user1'))
          .thenAnswer((_) async => Right([testItem]));
      await provider.loadCart('user1');

      when(mockRepo.removeCartItem('1'))
          .thenAnswer((_) async => const Right(null));

      await provider.removeFromCart('1');

      expect(provider.items, isEmpty);
      expect(provider.itemCount, 0);
    });
  });
}
