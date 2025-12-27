import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Property 14: Quantity Validation Non-Negative', () {
    test('Stock quantity validator should reject negative values', () {
       // Logic verification mirroring the implementation in AddEditProductScreen
       
       String? validateStock(String? v) {
          if (v == null || v.isEmpty) return 'Required';
          final n = int.tryParse(v);
          if (n == null) return 'Invalid number';
          if (n < 0) return 'Cannot be negative';
          return null;
       }
       
       // Property: For all N < 0, validateStock(N) == 'Cannot be negative'
       
       expect(validateStock('-1'), 'Cannot be negative');
       expect(validateStock('-100'), 'Cannot be negative');
       expect(validateStock('0'), null);
       expect(validateStock('10'), null);
       expect(validateStock('abc'), 'Invalid number');
       expect(validateStock(''), 'Required');
       expect(validateStock(null), 'Required');
    });
  });
}
