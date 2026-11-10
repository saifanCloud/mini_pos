import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../addon/domain/entities/addon.dart';
import '../../../addon/domain/repositories/addon_repository.dart';
import '../../../category/domain/repositories/category_repository.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/domain/repositories/product_repository.dart';
import 'cashier_state.dart';

/// Cubit untuk mengelola data katalog kasir, pencarian instan, dan filter kategori.
class CashierCubit extends Cubit<CashierState> {
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final AddonRepository _addonRepository;

  CashierCubit(
    this._productRepository,
    this._categoryRepository,
    this._addonRepository,
  ) : super(const CashierState());

  /// Memuat seluruh produk aktif, kategori, dan add-on dari database lokal.
  Future<void> loadData() async {
    try {
      emit(state.copyWith(status: CashierStatus.loading));

      final productsFuture = _productRepository.getProducts();
      final categoriesFuture = _categoryRepository.getCategories();
      final addonsFuture = _addonRepository.getAddons();

      final results = await Future.wait([
        productsFuture,
        categoriesFuture,
        addonsFuture,
      ]);

      final products = results[0] as List<Product>;
      final categories = results[1] as List<dynamic>;
      final addons = results[2] as List<Addon>;

      final addonMap = {for (final a in addons) a.id: a};

      emit(
        state.copyWith(
          status: CashierStatus.loaded,
          products: products,
          categories: categories.cast(),
          addonMap: addonMap,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CashierStatus.error,
          errorMessage: 'Gagal memuat katalog kasir: $e',
        ),
      );
    }
  }

  /// Mengubah kata kunci pencarian produk secara instan.
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Memilih kategori filter (null untuk chip "Semua").
  void selectCategory(int? categoryId) {
    if (categoryId == null) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategoryId: categoryId));
    }
  }

  /// Mengambil daftar objek entity [Addon] yang terhubung ke sebuah produk.
  List<Addon> getAddonsForProduct(Product product) {
    final List<Addon> list = [];
    for (final id in product.addonIds) {
      final addon = state.addonMap[id];
      if (addon != null && !addon.isDeleted) {
        list.add(addon);
      }
    }
    return list;
  }
}

