import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/image_storage.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_state.dart';

/// Cubit untuk mengelola state dan operasi CRUD produk.
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;

  ProductCubit(this._productRepository) : super(ProductInitial());

  /// Muat daftar semua produk aktif.
  Future<void> loadProducts({int? categoryId}) async {
    emit(ProductLoading());
    try {
      final list = await _productRepository.getProducts(categoryId: categoryId);
      emit(ProductLoaded(list));
    } catch (e) {
      emit(ProductFailure(_cleanErrorMessage(e)));
    }
  }

  /// Tambah produk baru dengan relasi add-on.
  Future<void> addProduct({
    required String name,
    int? categoryId,
    required int price,
    required int stock,
    String? photoPath,
    List<int> addonIds = const [],
  }) async {
    try {
      await _productRepository.createProduct(
        name: name,
        categoryId: categoryId,
        price: price,
        stock: stock,
        photoPath: photoPath,
        addonIds: addonIds,
      );
      await loadProducts();
    } catch (e) {
      emit(ProductFailure(_cleanErrorMessage(e)));
      final list = await _productRepository.getProducts();
      emit(ProductLoaded(list));
    }
  }

  /// Perbarui produk. Jika foto diganti, hapus file foto lama (B3 PRD).
  Future<void> editProduct({
    required Product product,
    List<int>? addonIds,
    String? oldPhotoPath,
  }) async {
    try {
      // Jika foto diganti dengan foto baru, hapus foto lama dari penyimpanan (B3 PRD)
      if (oldPhotoPath != null &&
          oldPhotoPath.isNotEmpty &&
          oldPhotoPath != product.photoPath) {
        await ImageStorage.deleteImage(oldPhotoPath);
      }

      await _productRepository.updateProduct(
        product,
        addonIds: addonIds,
      );
      await loadProducts();
    } catch (e) {
      emit(ProductFailure(_cleanErrorMessage(e)));
      final list = await _productRepository.getProducts();
      emit(ProductLoaded(list));
    }
  }

  /// Hapus produk (soft delete).
  Future<void> deleteProduct(int id) async {
    try {
      await _productRepository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      emit(ProductFailure(_cleanErrorMessage(e)));
      final list = await _productRepository.getProducts();
      emit(ProductLoaded(list));
    }
  }

  String _cleanErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}

