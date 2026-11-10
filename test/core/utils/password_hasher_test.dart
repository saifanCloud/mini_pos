import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/core/utils/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hash tidak menyimpan password dalam teks asli', () {
      const password = 'rahasia123';
      final hashed = PasswordHasher.hash(password);
      expect(hashed, isNot(contains(password)));
    });

    test('format hasil hash adalah salt:hash (mengandung titik dua)', () {
      final hashed = PasswordHasher.hash('password');
      final parts = hashed.split(':');
      expect(parts.length, 2);
      expect(parts[0], isNotEmpty); // salt
      expect(parts[1], isNotEmpty); // hash
    });

    test('verify mengembalikan true untuk password yang benar', () {
      const password = 'password123';
      final stored = PasswordHasher.hash(password);
      expect(PasswordHasher.verify(password, stored), isTrue);
    });

    test('verify mengembalikan false untuk password yang salah', () {
      final stored = PasswordHasher.hash('password123');
      expect(PasswordHasher.verify('passwordSalah', stored), isFalse);
    });

    test('dua hash dari password yang sama menghasilkan nilai berbeda (salt acak)', () {
      const password = 'sama';
      final hash1 = PasswordHasher.hash(password);
      final hash2 = PasswordHasher.hash(password);
      expect(hash1, isNot(equals(hash2)));
    });

    test('verify mengembalikan false untuk stored yang tidak valid', () {
      expect(PasswordHasher.verify('password', 'formatTidakValid'), isFalse);
      expect(PasswordHasher.verify('password', ''), isFalse);
    });
  });
}

