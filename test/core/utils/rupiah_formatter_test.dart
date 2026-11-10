import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/core/utils/rupiah_formatter.dart';

void main() {
  group('RupiahFormatter.format', () {
    test('nol → Rp0', () {
      expect(RupiahFormatter.format(0), 'Rp0');
    });

    test('1.000 → Rp1.000', () {
      expect(RupiahFormatter.format(1000), 'Rp1.000');
    });

    test('15.000 → Rp15.000', () {
      expect(RupiahFormatter.format(15000), 'Rp15.000');
    });

    test('100.000 → Rp100.000', () {
      expect(RupiahFormatter.format(100000), 'Rp100.000');
    });

    test('1.500.000 → Rp1.500.000', () {
      expect(RupiahFormatter.format(1500000), 'Rp1.500.000');
    });

    test('tidak mengandung desimal', () {
      final result = RupiahFormatter.format(15000);
      expect(result.contains(','), isFalse);
    });
  });
}

