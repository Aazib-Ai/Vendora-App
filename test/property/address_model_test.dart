import 'package:flutter_test/flutter_test.dart';
import 'package:vendora/models/address.dart';

void main() {
  group('Address Model Tests', () {
    test('Address serialization round-trip', () {
      final address = Address(
        id: '123',
        userId: 'user_123',
        label: 'Home',
        addressText: '123 Main St',
        latitude: 10.0,
        longitude: 20.0,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final json = address.toJson();
      final fromJson = Address.fromJson(json);

      expect(fromJson, equals(address));
    });

    test('Address copyWith', () {
      final address = Address(
        id: '123',
        userId: 'user_123',
        label: 'Home',
        addressText: '123 Main St',
        latitude: 10.0,
        longitude: 20.0,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final newAddress = address.copyWith(label: 'Work');
      expect(newAddress.label, 'Work');
      expect(newAddress.id, address.id);
    });
  });
}
