import 'package:flutter/material.dart';

/// Gaya teks standar untuk aplikasi kasir menggunakan font bawaan sistem.
class AppTextStyles {
  AppTextStyles._();

  /// Gaya harga besar (misal: Total tagihan pembayaran, total omzet)
  static const TextStyle priceLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  /// Gaya harga sedang (misal: Subtotal kartu produk, ringkasan keranjang)
  static const TextStyle priceMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
  );

  /// Gaya harga kecil (misal: Harga add-on, harga unit per item)
  static const TextStyle priceSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Judul section/bagian utama
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
  );

  /// Label tebal pada tombol atau form
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
  );

  /// Keterangan atau teks sekunder
  static const TextStyle secondaryText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
}

