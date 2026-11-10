import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/addon/domain/entities/addon.dart';
import 'package:mini_pos/features/cashier/domain/entities/cart.dart';
import 'package:mini_pos/features/cashier/domain/entities/cart_line.dart';
import 'package:mini_pos/features/cashier/domain/entities/discount.dart';
import 'package:mini_pos/features/cashier/domain/usecases/cart_logic.dart';
import 'package:mini_pos/features/product/domain/entities/product.dart';

void main() {
  group('CartLogic - Validasi Stok Bersama (B1 PRD)', () {
    const kopiSusu = Product(
      id: 1,
      name: 'Kopi Susu',
      price: 15000,
      stock: 2, // Batas stok produk = 2
    );

    const rotiBakar = Product(
      id: 2,
      name: 'Roti Bakar',
      price: 20000,
      stock: 10,
    );

    const extraShot = Addon(
      id: 101,
      name: 'Extra Shot',
      price: 5000,
      stock: 5,
    );

    const keju = Addon(
      id: 102,
      name: 'Keju',
      price: 3000,
      stock: 2, // Batas stok add-on = 2
    );

    test(
        'Kasus Kritis B1: Stok Kopi Susu 2, tambah 1 polos + 1 dengan Extra Shot, item ke-3 ditolak',
        () {
      List<CartLine> lines = [];

      // 1. Tambah 1 Kopi Susu polos (qty = 1)
      final check1 = CartLogic.canAddUnit(
        lines: lines,
        product: kopiSusu,
        selectedAddons: [],
      );
      expect(check1.isValid, isTrue);
      lines = CartLogic.addOrMergeLine(lines, kopiSusu, []);

      expect(CartLogic.produkTerpakai(lines, kopiSusu.id), equals(1));

      // 2. Tambah 1 Kopi Susu + Extra Shot (qty = 1)
      final check2 = CartLogic.canAddUnit(
        lines: lines,
        product: kopiSusu,
        selectedAddons: [extraShot],
      );
      expect(check2.isValid, isTrue);
      lines = CartLogic.addOrMergeLine(lines, kopiSusu, [extraShot]);

      // Total stok Kopi Susu terpakai = 2
      expect(CartLogic.produkTerpakai(lines, kopiSusu.id), equals(2));
      expect(CartLogic.addonTerpakai(lines, extraShot.id), equals(1));

      // 3. Percobaan menambah Kopi Susu ke-3 (baik polos maupun dengan add-on) harus DITOLAK
      final check3 = CartLogic.canAddUnit(
        lines: lines,
        product: kopiSusu,
        selectedAddons: [],
      );
      expect(check3.isValid, isFalse);
      expect(check3.message, contains('Stok Kopi Susu sudah habis di keranjang'));

      final check3WithAddon = CartLogic.canAddUnit(
        lines: lines,
        product: kopiSusu,
        selectedAddons: [extraShot],
      );
      expect(check3WithAddon.isValid, isFalse);
    });

    test('Batas stok add-on bersama lintas produk ditolak saat melebihi stok add-on', () {
      List<CartLine> lines = [];

      // Add-on Keju stok = 2
      // 1. Tambah Kopi Susu + Keju (qty = 1)
      final check1 = CartLogic.canAddUnit(
        lines: lines,
        product: kopiSusu,
        selectedAddons: [keju],
      );
      expect(check1.isValid, isTrue);
      lines = CartLogic.addOrMergeLine(lines, kopiSusu, [keju]);

      // 2. Tambah Roti Bakar + Keju (qty = 1)
      final check2 = CartLogic.canAddUnit(
        lines: lines,
        product: rotiBakar,
        selectedAddons: [keju],
      );
      expect(check2.isValid, isTrue);
      lines = CartLogic.addOrMergeLine(lines, rotiBakar, [keju]);

      // Keju sudah terpakai 2 (1 di kopi, 1 di roti)
      expect(CartLogic.addonTerpakai(lines, keju.id), equals(2));

      // 3. Tambah Roti Bakar + Keju lagi -> harus ditolak karena stok Keju habis
      // (meskipun stok Roti Bakar masih ada 10)
      final check3 = CartLogic.canAddUnit(
        lines: lines,
        product: rotiBakar,
        selectedAddons: [keju],
      );
      expect(check3.isValid, isFalse);
      expect(check3.message, contains('Stok add-on Keju sudah habis di keranjang'));

      // Namun Roti Bakar polos masih bisa ditambah
      final checkRotiPolos = CartLogic.canAddUnit(
        lines: lines,
        product: rotiBakar,
        selectedAddons: [],
      );
      expect(checkRotiPolos.isValid, isTrue);
    });
  });

  group('CartLogic - Penggabungan Baris & Subtotal (F6 PRD)', () {
    const productA = Product(
      id: 1,
      name: 'Produk A',
      price: 10000,
      stock: 100,
    );

    const addon1 = Addon(id: 1, name: 'Topping 1', price: 2000, stock: 50);
    const addon2 = Addon(id: 2, name: 'Topping 2', price: 3000, stock: 50);

    test('Produk dan kombinasi add-on yang sama digabung dan menambah qty', () {
      List<CartLine> lines = [];

      // Tambah Produk A + Topping 1
      lines = CartLogic.addOrMergeLine(lines, productA, [addon1]);
      expect(lines.length, equals(1));
      expect(lines.first.qty, equals(1));

      // Tambah Produk A + Topping 1 lagi -> baris tetap 1, qty menjadi 2
      lines = CartLogic.addOrMergeLine(lines, productA, [addon1]);
      expect(lines.length, equals(1));
      expect(lines.first.qty, equals(2));

      // Tambah Produk A + [Topping 2, Topping 1] (urutan terbalik tetap kombinasi sama)
      lines = CartLogic.addOrMergeLine(lines, productA, [addon1, addon2]);
      expect(lines.length, equals(2));

      lines = CartLogic.addOrMergeLine(lines, productA, [addon2, addon1]);
      expect(lines.length, equals(2)); // digabung ke baris kedua
      expect(lines[1].qty, equals(2));
    });

    test('Hitungan subtotal baris dan keranjang dengan add-on', () {
      // Baris 1: Produk A (10.000) + Topping 1 (2.000) * 2 = 24.000
      final line1 = CartLine(
        product: productA,
        selectedAddons: const [addon1],
        qty: 2,
      );
      expect(line1.unitPrice, equals(12000));
      expect(line1.subtotal, equals(24000));

      // Baris 2: Produk A (10.000) + Topping 1 (2.000) + Topping 2 (3.000) * 3 = 45.000
      final line2 = CartLine(
        product: productA,
        selectedAddons: const [addon1, addon2],
        qty: 3,
      );
      expect(line2.unitPrice, equals(15000));
      expect(line2.subtotal, equals(45000));

      final cart = Cart(lines: [line1, line2]);
      expect(cart.totalItems, equals(5));
      expect(cart.subtotal, equals(69000));
      expect(CartLogic.calculateSubtotal([line1, line2]), equals(69000));
    });

    test('Update qty menjadi 0 menghapus baris dari keranjang', () {
      final line1 = CartLine(product: productA, qty: 2);
      final line2 = CartLine(product: productA, selectedAddons: const [addon1], qty: 1);
      List<CartLine> lines = [line1, line2];

      // Kurangi baris pertama menjadi 1
      lines = CartLogic.updateLineQty(lines, 0, 1);
      expect(lines[0].qty, equals(1));

      // Set qty baris pertama menjadi 0 -> baris terhapus
      lines = CartLogic.updateLineQty(lines, 0, 0);
      expect(lines.length, equals(1));
      expect(lines[0].selectedAddons, equals([addon1]));
    });
  });

  group('CartLogic - Proteksi Diskon & Kalkulasi Total (B4 PRD)', () {
    const subtotal = 100000;

    test('Diskon persen normal terhitung benar', () {
      final totals = CartLogic.calculateTotals(
        subtotal,
        discountType: DiscountType.percent,
        discountValue: 10, // 10%
      );

      expect(totals.subtotal, equals(100000));
      expect(totals.discountAmount, equals(10000));
      expect(totals.total, equals(90000));
    });

    test('Diskon persen 150% dibatasi/clamp maksimal 100% dan validator menolak', () {
      // Validator menolak input > 100
      final validationMsg = CartLogic.validateDiscount(
        subtotal,
        discountType: DiscountType.percent,
        discountValue: 150,
      );
      expect(validationMsg, isNotNull);
      expect(validationMsg, contains('antara 0 dan 100'));

      // Kalkulasi meng-clamp aman jika input lolos
      final totals = CartLogic.calculateTotals(
        subtotal,
        discountType: DiscountType.percent,
        discountValue: 150,
      );
      expect(totals.discountAmount, equals(100000)); // di-clamp 100%
      expect(totals.total, equals(0)); // tidak pernah negatif
    });

    test('Diskon nominal lebih besar dari subtotal di-clamp dan validator menolak', () {
      // Diskon Rp120.000 pada subtotal Rp100.000
      final validationMsg = CartLogic.validateDiscount(
        subtotal,
        discountType: DiscountType.fixed,
        discountValue: 120000,
      );
      expect(validationMsg, isNotNull);
      expect(validationMsg, contains('tidak boleh melebihi subtotal'));

      // Kalkulasi meng-clamp diskon maksimal sebesar subtotal
      final totals = CartLogic.calculateTotals(
        subtotal,
        discountType: DiscountType.fixed,
        discountValue: 120000,
      );
      expect(totals.discountAmount, equals(100000));
      expect(totals.total, equals(0));
    });

    test('Diskon nominal negatif ditolak oleh validator dan di-clamp', () {
      final validationMsg = CartLogic.validateDiscount(
        subtotal,
        discountType: DiscountType.fixed,
        discountValue: -5000,
      );
      expect(validationMsg, isNotNull);

      final totals = CartLogic.calculateTotals(
        subtotal,
        discountType: DiscountType.fixed,
        discountValue: -5000,
      );
      expect(totals.discountAmount, equals(0));
      expect(totals.total, equals(100000));
    });

    test('Total tidak pernah negatif dalam kondisi apa pun', () {
      final totals = CartLogic.calculateTotals(
        50000,
        discountType: DiscountType.fixed,
        discountValue: 999999,
      );

      expect(totals.total, isNonNegative);
      expect(totals.total, equals(0));
    });
  });
}

