import 'package:equatable/equatable.dart';
import '../../../addon/domain/entities/addon.dart';
import '../../../category/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';

enum CashierStatus { initial, loading, loaded, error }

/// State untuk layar kasir (katalog produk, filter, dan pencarian).
class CashierState extends Equatable {
  final CashierStatus status;
  final List<Product> products;
  final List<Category> categories;
  final Map<int, Addon> addonMap;
  final String searchQuery;
  final int? selectedCategoryId; // null berarti chip "Semua"
  final String? errorMessage;

  const CashierState({
    this.status = CashierStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.addonMap = const {},
    this.searchQuery = '',
    this.selectedCategoryId,
    this.errorMessage,
  });

  /// Daftar produk terfilter secara real-time berdasarkan pencarian nama
  /// dan pemilihan filter kategori (keduanya bisa dipakai bersamaan).
  List<Product> get filteredProducts {
    return products.where((product) {
      final matchesCategory = selectedCategoryId == null ||
          product.categoryId == selectedCategoryId;
      final matchesQuery = searchQuery.trim().isEmpty ||
          product.name
              .toLowerCase()
              .contains(searchQuery.trim().toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  CashierState copyWith({
    CashierStatus? status,
    List<Product>? products,
    List<Category>? categories,
    Map<int, Addon>? addonMap,
    String? searchQuery,
    int? selectedCategoryId,
    bool clearCategory = false,
    String? errorMessage,
  }) {
    return CashierState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      addonMap: addonMap ?? this.addonMap,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        categories,
        addonMap,
        searchQuery,
        selectedCategoryId,
        errorMessage,
      ];
}

