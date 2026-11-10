import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/image_storage.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../addon/presentation/cubit/addon_cubit.dart';
import '../../../addon/presentation/cubit/addon_state.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/cubit/category_cubit.dart';
import '../../../category/presentation/cubit/category_state.dart';
import '../../domain/entities/product.dart';
import '../cubit/product_cubit.dart';

/// Layar form untuk menambah atau mengubah data Produk.
class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  int? _selectedCategoryId;
  String? _photoPath; // nama file di dokumen aplikasi
  String? _originalPhotoPath; // untuk perbandingan jika diganti
  String? _resolvedPhotoFullPath;
  late final Set<int> _selectedAddonIds;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '',
    );

    _selectedCategoryId = p?.categoryId;
    _photoPath = p?.photoPath;
    _originalPhotoPath = p?.photoPath;
    _selectedAddonIds = Set<int>.from(p?.addonIds ?? []);

    if (_photoPath != null && _photoPath!.isNotEmpty) {
      _resolveInitialPhotoPath();
    }

    // Pastikan data kategori dan add-on termuat untuk dropdown & checklist
    context.read<CategoryCubit>().loadCategories();
    context.read<AddonCubit>().loadAddons();
  }

  Future<void> _resolveInitialPhotoPath() async {
    final full = await ImageStorage.fullPath(_photoPath);
    if (mounted) {
      setState(() {
        _resolvedPhotoFullPath = full;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Tutup bottom sheet
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (picked != null) {
        // Salin ke folder dokumen aplikasi dengan nama unik (B3 PRD)
        final savedFileName = await ImageStorage.saveImage(File(picked.path));
        final fullPath = await ImageStorage.fullPath(savedFileName);

        setState(() {
          _photoPath = savedFileName;
          _resolvedPhotoFullPath = fullPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Kamera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeri Foto'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Hapus Foto',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _photoPath = null;
                      _resolvedPhotoFullPath = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() == true) {
      final name = _nameController.text.trim();
      final price = int.parse(_priceController.text.trim());
      final stock = int.parse(_stockController.text.trim());
      final addonList = _selectedAddonIds.toList();

      final isEditing = widget.product != null;

      if (isEditing) {
        context.read<ProductCubit>().editProduct(
              product: Product(
                id: widget.product!.id,
                categoryId: _selectedCategoryId,
                name: name,
                price: price,
                stock: stock,
                photoPath: _photoPath,
                addonIds: addonList,
              ),
              addonIds: addonList,
              oldPhotoPath: _originalPhotoPath,
            );
      } else {
        context.read<ProductCubit>().addProduct(
              name: name,
              categoryId: _selectedCategoryId,
              price: price,
              stock: stock,
              photoPath: _photoPath,
              addonIds: addonList,
            );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Produk' : 'Tambah Produk Baru'),
        actions: [
          TextButton(
            onPressed: _onSavePressed,
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector Foto Produk
              Center(
                child: GestureDetector(
                  onTap: _showImageSourcePicker,
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildPhotoPreview(theme),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Ketuk untuk memilih foto (Kamera/Galeri)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Input Nama Produk
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  hintText: 'Contoh: Kopi Susu Aren, Roti Bakar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.coffee_outlined),
                ),
                validator: Validators.validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 3. Dropdown Kategori
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, catState) {
                  final categories = catState is CategoryLoaded
                      ? catState.categories
                      : <Category>[];

                  final bool hasCategory = _selectedCategoryId != null &&
                      categories.any((c) => c.id == _selectedCategoryId);
                  final int? effectiveValue =
                      hasCategory ? _selectedCategoryId : null;

                  return DropdownButtonFormField<int?>(
                    key: ValueKey(
                      'category_dropdown_${categories.length}_$effectiveValue',
                    ),
                    initialValue: effectiveValue,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tanpa Kategori'),
                      ),
                      ...categories.map(
                        (cat) => DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // 4. Input Harga Jual
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (Rp)',
                  hintText: 'Contoh: 15000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => Validators.validateNonNegativeInt(
                  v,
                  label: 'Harga jual',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 5. Input Stok
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stok Produk',
                  hintText: 'Contoh: 20',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                validator: (v) => Validators.validateNonNegativeInt(
                  v,
                  label: 'Stok',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // 6. Multi-select Add-on
              Text(
                'Pilihan Add-on / Topping',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add-on yang dicentang dapat dipilih kasir saat menjual produk ini.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddonSelection(theme),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: _onSavePressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Simpan Perubahan' : 'Tambah Produk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(ThemeData theme) {
    if (_resolvedPhotoFullPath != null &&
        File(_resolvedPhotoFullPath!).existsSync()) {
      return Image.file(
        File(_resolvedPhotoFullPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderPhoto(theme),
      );
    }
    return _buildPlaceholderPhoto(theme);
  }

  Widget _buildPlaceholderPhoto(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Tambah Foto',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAddonSelection(ThemeData theme) {
    return BlocBuilder<AddonCubit, AddonState>(
      builder: (context, addonState) {
        final addons = addonState is AddonLoaded ? addonState.addons : [];

        if (addons.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Belum ada add-on aktif. Anda dapat membuatnya di tab Add-on.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: addons.map((addon) {
              final isChecked = _selectedAddonIds.contains(addon.id);
              return CheckboxListTile(
                value: isChecked,
                title: Text(addon.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('+${RupiahFormatter.format(addon.price)} • Stok: ${addon.stock}'),
                activeColor: theme.colorScheme.primary,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedAddonIds.add(addon.id);
                    } else {
                      _selectedAddonIds.remove(addon.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
