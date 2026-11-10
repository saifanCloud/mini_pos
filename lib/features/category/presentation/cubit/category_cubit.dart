import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

/// Cubit untuk mengelola state dan operasi CRUD kategori.
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryCubit(this._categoryRepository) : super(CategoryInitial());

  /// Muat daftar semua kategori.
  Future<void> loadCategories() async {
    emit(CategoryLoading());
    try {
      final list = await _categoryRepository.getCategories();
      emit(CategoryLoaded(list));
    } catch (e) {
      emit(CategoryFailure(_cleanErrorMessage(e)));
    }
  }

  /// Tambah kategori baru.
  Future<void> addCategory(String name) async {
    try {
      await _categoryRepository.createCategory(name);
      await loadCategories();
    } catch (e) {
      emit(CategoryFailure(_cleanErrorMessage(e)));
      // Kembalikan ke daftar sebelumnya jika ada
      final list = await _categoryRepository.getCategories();
      emit(CategoryLoaded(list));
    }
  }

  /// Perbarui nama kategori.
  Future<void> editCategory(Category category) async {
    try {
      await _categoryRepository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      emit(CategoryFailure(_cleanErrorMessage(e)));
      final list = await _categoryRepository.getCategories();
      emit(CategoryLoaded(list));
    }
  }

  /// Hapus kategori.
  Future<void> deleteCategory(int id) async {
    try {
      await _categoryRepository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      emit(CategoryFailure(_cleanErrorMessage(e)));
      final list = await _categoryRepository.getCategories();
      emit(CategoryLoaded(list));
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

