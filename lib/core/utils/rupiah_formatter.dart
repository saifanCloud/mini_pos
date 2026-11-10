import 'package:intl/intl.dart';

/// Formatter untuk menampilkan angka sebagai mata uang Rupiah.
/// Semua harga disimpan sebagai INTEGER di database (tanpa desimal).
/// Contoh: formatRupiah(15000) → "Rp15.000"
class RupiahFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Format [amount] (dalam Rupiah) menjadi string "Rp15.000".
  static String format(int amount) => _formatter.format(amount);
}

