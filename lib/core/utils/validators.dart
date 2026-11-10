/// Kumpulan fungsi validasi input aplikasi.
/// Semua fungsi kembalikan String pesan error (Indonesia) jika tidak valid,
/// atau null jika valid — cocok langsung dipakai sebagai validator di TextFormField.
class Validators {
  /// Nama tidak boleh kosong.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }

  /// Username minimal 4 karakter dan tidak boleh mengandung spasi.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 4) {
      return 'Username minimal 4 karakter';
    }
    if (value.contains(' ')) {
      return 'Username tidak boleh mengandung spasi';
    }
    return null;
  }

  /// Password minimal 6 karakter.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Konfirmasi password harus sama persis dengan [password].
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Konfirmasi password tidak sama';
    }
    return null;
  }

  /// Nilai harus berupa bilangan bulat tidak negatif (untuk harga dan stok).
  static String? validateNonNegativeInt(String? value, {String label = 'Nilai'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label tidak boleh kosong';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$label harus berupa bilangan bulat';
    }
    if (parsed < 0) {
      return '$label tidak boleh negatif';
    }
    return null;
  }

  /// Diskon persen harus bilangan antara 0 dan 100 (inklusif).
  /// Sesuai B4 PRD: validasi di UI dan di fungsi perhitungan.
  static String? validateDiscountPercent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Diskon tidak boleh kosong';
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Diskon harus berupa angka';
    }
    if (parsed < 0 || parsed > 100) {
      return 'Diskon persen harus antara 0 dan 100';
    }
    return null;
  }

  /// Diskon nominal tidak boleh negatif dan tidak boleh melebihi [subtotal].
  /// Sesuai B4 PRD: total tidak pernah negatif.
  static String? validateDiscountFixed(String? value, int subtotal) {
    if (value == null || value.trim().isEmpty) {
      return 'Diskon tidak boleh kosong';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Diskon harus berupa bilangan bulat';
    }
    if (parsed < 0) {
      return 'Diskon tidak boleh negatif';
    }
    if (parsed > subtotal) {
      return 'Diskon tidak boleh melebihi subtotal';
    }
    return null;
  }
}

