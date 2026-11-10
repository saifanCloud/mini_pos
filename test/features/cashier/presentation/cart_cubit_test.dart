import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/addon/domain/entities/addon.dart';
import 'package:mini_pos/features/cashier/presentation/cubit/cart_cubit.dart';
import 'package:mini_pos/features/product/domain/entities/product.dart';

void main() {
  group('CartCubit Tests (Tahap 10 & Aturan B1)', () {
    late CartCubit cartCubit;

    const testProduct1 = Product(
      id: 1,
      name: 'Kopi Susu',
      price: 15000,
      stock: 2,
    );

    const testProduct2 = Product(
      id: 2,
      name: 'Roti Bakar',
      price: 12000,
      stock: 5,
    );

    const testAddon1 = Addon(
      id: 10,
      name: 'Extra Shot',
      price: 4000,
      stock: 2,
    );

    const testAddon2 = Addon(
      id: 20,
      name: 'Oat Milk',
      price: 6000,
      stock: 10,
    );

    setUp(() {
      cartCubit = CartCubit();
    });

    tearDown(() {
      cartCubit.close();
    });

    test('State awal keranjang adalah kosong', () {
      expect(cartCubit.state.cart.isEmpty, isTrue);
      expect(cartCubit.state.totalItems, 0);
      expect(cartCubit.state.subtotal, 0);
    });

    test('Menambah produk polos menambah total items dan subtotal dengan benar',
        () {
      final res = cartCubit.addToCart(testProduct1, []);

      expect(res.isValid, isTrue);
      expect(cartCubit.state.totalItems, 1);
      expect(cartCubit.state.lines.length, 1);
      expect(cartCubit.state.subtotal, 15000);
    });

    test('Menambah produk dengan kombinasi add-on sama menggabungkan baris',
        () {
      // Tambah item 1: Kopi + Extra Shot
      final res1 = cartCubit.addToCart(testProduct1, [testAddon1]);
      expect(res1.isValid, isTrue);

      // Tambah item 2: Kopi + Extra Shot lagi
      final res2 = cartCubit.addToCart(testProduct1, [testAddon1]);
      expect(res2.isValid, isTrue);

      // Baris tetap 1, qty menjadi 2
      expect(cartCubit.state.lines.length, 1);
      expect(cartCubit.state.lines.first.qty, 2);
      expect(cartCubit.state.totalItems, 2);
      expect(cartCubit.state.subtotal, (15000 + 4000) * 2);
    });

    test('Kombinasi add-on berbeda membuat baris terpisah', () {
      // 1 Kopi Susu polos
      cartCubit.addToCart(testProduct1, []);
      // 1 Kopi Susu + Extra Shot
      cartCubit.addToCart(testProduct1, [testAddon1]);

      expect(cartCubit.state.lines.length, 2);
      expect(cartCubit.state.totalItems, 2);
      expect(cartCubit.state.subtotal, 15000 + (15000 + 4000));
    });

    test(
        'Aturan B1: Stok produk 2 (1 polos + 1 extra shot), item ke-3 harus ditolak',
        () {
      // Unit 1: Kopi polos
      final res1 = cartCubit.addToCart(testProduct1, []);
      expect(res1.isValid, isTrue);

      // Unit 2: Kopi + Extra Shot (stok Kopi Susu terpakai = 2)
      final res2 = cartCubit.addToCart(testProduct1, [testAddon1]);
      expect(res2.isValid, isTrue);

      // Unit 3: Percobaan menambah Kopi Susu lagi harus ditolak
      final res3 = cartCubit.addToCart(testProduct1, []);
      expect(res3.isValid, isFalse);
      expect(res3.message, contains('Stok Kopi Susu'));

      // Total di keranjang tetap 2
      expect(cartCubit.state.totalItems, 2);
    });

    test('Aturan B1: Batas stok add-on bersama menolak jika add-on habis', () {
      // Extra Shot punya stok 2
      // Unit 1: Kopi + Extra Shot
      cartCubit.addToCart(testProduct1, [testAddon1]);
      // Unit 2: Roti + Extra Shot
      cartCubit.addToCart(testProduct2, [testAddon1]);

      // Percobaan Unit 3 dengan Extra Shot harus ditolak karena stok add-on = 2
      final res3 = cartCubit.addToCart(testProduct2, [testAddon1]);
      expect(res3.isValid, isFalse);
      expect(res3.message, contains('Stok add-on Extra Shot'));
    });

    test('incrementQty memvalidasi stok dan menolak jika stok habis', () {
      // Tambah 1 Kopi Susu (stok = 2)
      cartCubit.addToCart(testProduct1, []);

      // Naikkan ke 2 (sukses)
      final res1 = cartCubit.incrementQty(0);
      expect(res1.isValid, isTrue);
      expect(cartCubit.state.lines.first.qty, 2);

      // Naikkan ke 3 (gagal karena stok hanya 2)
      final res2 = cartCubit.incrementQty(0);
      expect(res2.isValid, isFalse);
      expect(cartCubit.state.lines.first.qty, 2);
    });

    test('decrementQty mengurangi kuantitas dan menghapus baris saat qty = 0',
        () {
      cartCubit.addToCart(testProduct2, [],); // qty = 1
      expect(cartCubit.state.lines.length, 1);

      // Kurangi saat qty = 1 -> baris dihapus
      cartCubit.decrementQty(0);
      expect(cartCubit.state.lines.isEmpty, isTrue);
      expect(cartCubit.state.totalItems, 0);
    });

    test('removeLine menghapus baris item spesifik', () {
      cartCubit.addToCart(testProduct1, []);
      cartCubit.addToCart(testProduct2, []);
      expect(cartCubit.state.lines.length, 2);

      cartCubit.removeLine(0);
      expect(cartCubit.state.lines.length, 1);
      expect(cartCubit.state.lines.first.product.id, testProduct2.id);
    });

    test('clearCart mengosongkan seluruh keranjang belanja', () {
      cartCubit.addToCart(testProduct1, []);
      cartCubit.addToCart(testProduct2, []);
      expect(cartCubit.state.isEmpty, isFalse);

      cartCubit.clearCart();
      expect(cartCubit.state.isEmpty, isTrue);
      expect(cartCubit.state.totalItems, 0);
      expect(cartCubit.state.subtotal, 0);
    });
  });
}

