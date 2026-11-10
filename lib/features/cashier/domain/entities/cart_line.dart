import 'package:equatable/equatable.dart';
import '../../../addon/domain/entities/addon.dart';
import '../../../product/domain/entities/product.dart';

/// Entity baris item di dalam keranjang belanja.
/// Terdiri dari satu jenis produk, pilihan kombinasi add-on, dan jumlah qty.
/// Murni kode Dart (tanpa dependensi Flutter atau database).
class CartLine extends Equatable {
  final Product product;
  final List<Addon> selectedAddons;
  final int qty;

  const CartLine({
    required this.product,
    this.selectedAddons = const [],
    this.qty = 1,
  });

  /// Harga satuan baris: harga dasar produk ditambah seluruh harga add-on terpilih.
  int get unitPrice {
    final addonsPrice = selectedAddons.fold<int>(0, (sum, a) => sum + a.price);
    return product.price + addonsPrice;
  }

  /// Total harga baris = harga satuan dikali qty.
  int get subtotal => unitPrice * qty;

  /// Memeriksa apakah baris ini memiliki produk dan kombinasi add-on yang sama persis.
  /// Urutan pemilihan add-on tidak memengaruhi kesamaan kombinasi.
  bool hasSameCombination(Product otherProduct, List<Addon> otherAddons) {
    if (product.id != otherProduct.id) return false;

    final thisAddonIds = selectedAddons.map((a) => a.id).toSet();
    final otherAddonIds = otherAddons.map((a) => a.id).toSet();

    if (thisAddonIds.length != otherAddonIds.length) return false;
    return thisAddonIds.containsAll(otherAddonIds);
  }

  CartLine copyWith({
    Product? product,
    List<Addon>? selectedAddons,
    int? qty,
  }) {
    return CartLine(
      product: product ?? this.product,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      qty: qty ?? this.qty,
    );
  }

  @override
  List<Object?> get props => [product, selectedAddons, qty];
}

