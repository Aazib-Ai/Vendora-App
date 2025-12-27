import 'package:flutter_test/flutter_test.dart';
import 'package:vendora/models/order.dart';

/// **Feature: vendora-backend-enhancement, Property 2: Order State Machine Transitions**
/// **Validates: Requirements 7.3, 7.4, 7.5, 7.6**
/// 
/// This test validates that the order state machine enforces valid
/// state transitions and rejects invalid ones.
void main() {
  group('Order State Machine', () {
    test('pending can transition to processing', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.pending,
          OrderStatus.processing,
        ),
        isTrue,
      );
    });

    test('pending can transition to cancelled', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.pending,
          OrderStatus.cancelled,
        ),
        isTrue,
      );
    });

    test('pending cannot transition to shipped', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.pending,
          OrderStatus.shipped,
        ),
        isFalse,
      );
    });

    test('pending cannot transition to delivered', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.pending,
          OrderStatus.delivered,
        ),
        isFalse,
      );
    });

    test('processing can transition to shipped', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.processing,
          OrderStatus.shipped,
        ),
        isTrue,
      );
    });

    test('processing can transition to cancelled', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.processing,
          OrderStatus.cancelled,
        ),
        isTrue,
      );
    });

    test('processing cannot transition to pending', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.processing,
          OrderStatus.pending,
        ),
        isFalse,
      );
    });

    test('processing cannot transition to delivered', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.processing,
          OrderStatus.delivered,
        ),
        isFalse,
      );
    });

    test('shipped can transition to delivered', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.shipped,
          OrderStatus.delivered,
        ),
        isTrue,
      );
    });

    test('shipped cannot transition to any other status', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.shipped,
          OrderStatus.pending,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.shipped,
          OrderStatus.processing,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.shipped,
          OrderStatus.cancelled,
        ),
        isFalse,
      );
    });

    test('delivered is a terminal state - no transitions allowed', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.delivered,
          OrderStatus.pending,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.delivered,
          OrderStatus.processing,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.delivered,
          OrderStatus.shipped,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.delivered,
          OrderStatus.cancelled,
        ),
        isFalse,
      );
    });

    test('cancelled is a terminal state - no transitions allowed', () {
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.cancelled,
          OrderStatus.pending,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.cancelled,
          OrderStatus.processing,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.cancelled,
          OrderStatus.shipped,
        ),
        isFalse,
      );
      expect(
        OrderStateMachine.canTransition(
          OrderStatus.cancelled,
          OrderStatus.delivered,
        ),
        isFalse,
      );
    });

    test('transition returns new status for valid transitions', () {
      final result = OrderStateMachine.transition(
        OrderStatus.pending,
        OrderStatus.processing,
      );
      expect(result, equals(OrderStatus.processing));
    });

    test('transition returns null for invalid transitions', () {
      final result = OrderStateMachine.transition(
        OrderStatus.pending,
        OrderStatus.delivered,
      );
      expect(result, isNull);
    });

    test('getAvailableTransitions returns correct options for pending', () {
      final transitions =
          OrderStateMachine.getAvailableTransitions(OrderStatus.pending);
      expect(transitions, contains(OrderStatus.processing));
      expect(transitions, contains(OrderStatus.cancelled));
      expect(transitions.length, equals(2));
    });

    test('getAvailableTransitions returns correct options for processing', () {
      final transitions =
          OrderStateMachine.getAvailableTransitions(OrderStatus.processing);
      expect(transitions, contains(OrderStatus.shipped));
      expect(transitions, contains(OrderStatus.cancelled));
      expect(transitions.length, equals(2));
    });

    test('getAvailableTransitions returns correct options for shipped', () {
      final transitions =
          OrderStateMachine.getAvailableTransitions(OrderStatus.shipped);
      expect(transitions, contains(OrderStatus.delivered));
      expect(transitions.length, equals(1));
    });

    test('getAvailableTransitions returns empty for terminal states', () {
      expect(
        OrderStateMachine.getAvailableTransitions(OrderStatus.delivered),
        isEmpty,
      );
      expect(
        OrderStateMachine.getAvailableTransitions(OrderStatus.cancelled),
        isEmpty,
      );
    });

    test('Order.canCancel is true for pending orders', () {
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.pending,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        createdAt: DateTime.now(),
      );
      expect(order.canCancel, isTrue);
    });

    test('Order.canCancel is true for processing orders', () {
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.processing,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        createdAt: DateTime.now(),
      );
      expect(order.canCancel, isTrue);
    });

    test('Order.canCancel is false for shipped orders', () {
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.shipped,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        createdAt: DateTime.now(),
      );
      expect(order.canCancel, isFalse);
    });

    test('Order.canDispute is true for recently delivered orders', () {
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.delivered,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        deliveredAt: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(order.canDispute, isTrue);
    });

    test('Order.canDispute is false for orders delivered more than 7 days ago',
        () {
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.delivered,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        deliveredAt: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      );
      expect(order.canDispute, isFalse);
    });

    test('Order.canTransitionTo works correctly', () {
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.pending,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        createdAt: DateTime.now(),
      );
      expect(order.canTransitionTo(OrderStatus.processing), isTrue);
      expect(order.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(order.canTransitionTo(OrderStatus.shipped), isFalse);
      expect(order.canTransitionTo(OrderStatus.delivered), isFalse);
    });
  });
}
