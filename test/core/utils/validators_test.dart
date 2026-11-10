import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/core/utils/validators.dart';

void main() {
  group('Validators.validateName', () {
    test('null → error', () => expect(Validators.validateName(null), isNotNull));
    test('kosong → error', () => expect(Validators.validateName(''), isNotNull));
    test('spasi saja → error', () => expect(Validators.validateName('   '), isNotNull));
    test('valid → null', () => expect(Validators.validateName('Budi'), isNull));
  });

  group('Validators.validateUsername', () {
    test('kosong → error', () => expect(Validators.validateUsername(''), isNotNull));
    test('kurang 4 karakter → error', () => expect(Validators.validateUsername('abc'), isNotNull));
    test('mengandung spasi → error', () => expect(Validators.validateUsername('budi santoso'), isNotNull));
    test('tepat 4 karakter → null', () => expect(Validators.validateUsername('budi'), isNull));
    test('valid tanpa spasi → null', () => expect(Validators.validateUsername('kasir01'), isNull));
  });

  group('Validators.validatePassword', () {
    test('kosong → error', () => expect(Validators.validatePassword(''), isNotNull));
    test('kurang 6 karakter → error', () => expect(Validators.validatePassword('12345'), isNotNull));
    test('tepat 6 karakter → null', () => expect(Validators.validatePassword('123456'), isNull));
    test('lebih dari 6 karakter → null', () => expect(Validators.validatePassword('password123'), isNull));
  });

  group('Validators.validatePasswordConfirm', () {
    test('tidak sama → error', () {
      expect(Validators.validatePasswordConfirm('berbeda', 'asli'), isNotNull);
    });
    test('kosong → error', () {
      expect(Validators.validatePasswordConfirm('', 'asli'), isNotNull);
    });
    test('sama persis → null', () {
      expect(Validators.validatePasswordConfirm('password123', 'password123'), isNull);
    });
  });

  group('Validators.validateNonNegativeInt', () {
    test('kosong → error', () => expect(Validators.validateNonNegativeInt(''), isNotNull));
    test('bukan angka → error', () => expect(Validators.validateNonNegativeInt('abc'), isNotNull));
    test('negatif → error', () => expect(Validators.validateNonNegativeInt('-1'), isNotNull));
    test('nol → null', () => expect(Validators.validateNonNegativeInt('0'), isNull));
    test('positif → null', () => expect(Validators.validateNonNegativeInt('1000'), isNull));
  });

  group('Validators.validateDiscountPercent', () {
    test('kosong → error', () => expect(Validators.validateDiscountPercent(''), isNotNull));
    test('negatif → error', () => expect(Validators.validateDiscountPercent('-1'), isNotNull));
    test('lebih dari 100 → error', () => expect(Validators.validateDiscountPercent('101'), isNotNull));
    test('nol → null', () => expect(Validators.validateDiscountPercent('0'), isNull));
    test('100 → null', () => expect(Validators.validateDiscountPercent('100'), isNull));
    test('50 → null', () => expect(Validators.validateDiscountPercent('50'), isNull));
  });

  group('Validators.validateDiscountFixed', () {
    const subtotal = 50000;
    test('kosong → error', () => expect(Validators.validateDiscountFixed('', subtotal), isNotNull));
    test('negatif → error', () => expect(Validators.validateDiscountFixed('-1', subtotal), isNotNull));
    test('melebihi subtotal → error', () {
      expect(Validators.validateDiscountFixed('50001', subtotal), isNotNull);
    });
    test('nol → null', () => expect(Validators.validateDiscountFixed('0', subtotal), isNull));
    test('sama dengan subtotal → null', () {
      expect(Validators.validateDiscountFixed('50000', subtotal), isNull);
    });
    test('di bawah subtotal → null', () {
      expect(Validators.validateDiscountFixed('10000', subtotal), isNull);
    });
  });
}

