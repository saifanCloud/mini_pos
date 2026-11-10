import 'dart:math' as math;
import '../../../addon/domain/entities/addon.dart';
import '../../../product/domain/entities/product.dart';
import '../entities/cart_line.dart';
import '../entities/discount.dart';

/// Hasil validasi stok bersama sebelum item dimasukkan atau ditambah di keranjang.
class StockValidationResult {
  final bool isValid;
  final String? message;

  const StockValidationResult({
    required this.isValid,
    this.message,
  });

  const StockValidationResult.valid()
      : isValid = true,
        message = null;

  const StockValidationResult.invalid(String this.message) : isValid = false;
}

/// Kumpulan fungsi murni untuk seluruh logika bisnis keranjang belanja dan transaksi.
/// Tidak mengimpor Flutter atau database (murni Dart) agar mudah dites (B1 & B4 PRD).
class CartLogic {
  /// Menghitung akumulasi kuantitas produk yang sudah terpakai di seluruh baris keranjang,
  /// apa pun kombinasi add-on-nya (B1 PRD).
  static int produkTerpakai(List<CartLine> lines, int productId) {
    return lines
        .where((line) => line.product.id == productId)
        .fold<int>(0, (sum, line) => sum + line.qty);
  }

  /// Menghitung akumulasi kuantitas add-on yang sudah terpakai di seluruh baris keranjang,
  /// di semua produk (B1 PRD).
  static int addonTerpakai(List<CartLine> lines, int addonId) {
    return lines
        .where((line) => line.selectedAddons.any((a) => a.id == addonId))
        .fold<int>(0, (sum, line) => sum + line.qty);
  }

  /// Memvalidasi apakah penambahan [count] unit produk dan add-on terpilih diizinkan
  /// berdasarkan batas sisa stok bersama (B1 PRD).
  static StockValidationResult canAddUnit({
    required List<CartLine> lines,
    required Product product,
    List<Addon> selectedAddons = const [],
    int count = 1,
  }) {
    // 1. Validasi stok produk bersama
    final usedProduct = produkTerpakai(lines, product.id);
    if (usedProduct + count > product.stock) {
      final remaining = product.stock - usedProduct;
      final msg = remaining <= 0
          ? 'Stok ${product.name} sudah habis di keranjang'
          : 'Stok ${product.name} tinggal $remaining';
      return StockValidationResult.invalid(msg);
    }

    // 2. Validasi stok add-on bersama untuk setiap add-on yang dipilih
    for (final addon in selectedAddons) {
      final usedAddon = addonTerpakai(lines, addon.id);
      if (usedAddon + count > addon.stock) {
        final remaining = addon.stock - usedAddon;
        final msg = remaining <= 0
            ? 'Stok add-on ${addon.name} sudah habis di keranjang'
            : 'Stok add-on ${addon.name} tinggal $remaining';
        return StockValidationResult.invalid(msg);
      }
    }

    return const StockValidationResult.valid();
  }

  /// Menambah atau menggabungkan baris item ke keranjang (F6 PRD).
  /// - Produk dan kombinasi add-on yang sama persis digabung dan menaikkan qty.
  /// - Kombinasi berbeda menjadi baris terpisah baru.
  static List<CartLine> addOrMergeLine(
    List<CartLine> lines,
    Product product,
    List<Addon> selectedAddons, {
    int qty = 1,
  }) {
    final updated = List<CartLine>.from(lines);
    final existingIndex = updated.indexWhere(
      (line) => line.hasSameCombination(product, selectedAddons),
    );

    if (existingIndex >= 0) {
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(qty: current.qty + qty);
    } else {
      updated.add(
        CartLine(
          product: product,
          selectedAddons: selectedAddons,
          qty: qty,
        ),
      );
    }

    return List.unmodifiable(updated);
  }

  /// Mengubah jumlah qty pada baris index tertentu.
  /// Jika [newQty] <= 0, baris tersebut dihapus dari keranjang.
  static List<CartLine> updateLineQty(
    List<CartLine> lines,
    int index,
    int newQty,
  ) {
    if (index < 0 || index >= lines.length) return lines;

    final updated = List<CartLine>.from(lines);
    if (newQty <= 0) {
      updated.removeAt(index);
    } else {
      updated[index] = updated[index].copyWith(qty: newQty);
    }

    return List.unmodifiable(updated);
  }

  /// Menghitung total subtotal dari seluruh baris keranjang belanja.
  static int calculateSubtotal(List<CartLine> lines) {
    return lines.fold<int>(0, (sum, line) => sum + line.subtotal);
  }

  /// Menghitung diskon dan total pembayaran akhir dengan proteksi ganda (B4 PRD).
  /// - Diskon persen di-clamp antara 0 dan 100%.
  /// - Diskon nominal di-clamp antara 0 dan subtotal.
  /// - Total akhir = max(0, subtotal - diskon), tidak pernah bernilai negatif.
  static CheckoutTotals calculateTotals(
    int subtotal, {
    DiscountType? discountType,
    int discountValue = 0,
  }) {
    if (subtotal <= 0 || discountType == null || discountValue <= 0) {
      return CheckoutTotals(
        subtotal: math.max(0, subtotal),
        discountType: discountType,
        discountValue: discountValue,
        discountAmount: 0,
        total: math.max(0, subtotal),
      );
    }

    int discountAmount = 0;

    switch (discountType) {
      case DiscountType.percent:
        // Clamp persen 0..100
        final safePercent = discountValue.clamp(0, 100);
        discountAmount = (subtotal * safePercent / 100).round();
        break;

      case DiscountType.fixed:
        // Clamp nominal 0..subtotal
        discountAmount = discountValue.clamp(0, subtotal);
        break;
    }

    // Total akhir tidak pernah negatif (B4 PRD)
    final total = math.max(0, subtotal - discountAmount);

    return CheckoutTotals(
      subtotal: subtotal,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      total: total,
    );
  }

  /// Validasi nilai diskon yang dimasukkan kasir untuk menampilkan pesan error di UI (B4 PRD).
  static String? validateDiscount(
    int subtotal, {
    DiscountType? discountType,
    int discountValue = 0,
  }) {
    if (discountType == null) return null;

    if (discountType == DiscountType.percent) {
      if (discountValue < 0 || discountValue > 100) {
        return 'Diskon persen harus antara 0 dan 100';
      }
    } else if (discountType == DiscountType.fixed) {
      if (discountValue < 0) {
        return 'Diskon tidak boleh negatif';
      }
      if (discountValue > subtotal) {
        return 'Diskon tidak boleh melebihi subtotal';
      }
    }

    return null;
  }
}

