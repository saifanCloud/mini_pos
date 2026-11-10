import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/addon.dart';
import '../cubit/addon_cubit.dart';
import '../cubit/addon_state.dart';

/// Tab tampilan daftar dan pengelolaan CRUD Add-on / Topping.
class AddonTabView extends StatefulWidget {
  const AddonTabView({super.key});

  @override
  State<AddonTabView> createState() => _AddonTabViewState();
}

class _AddonTabViewState extends State<AddonTabView> {
  @override
  void initState() {
    super.initState();
    context.read<AddonCubit>().loadAddons();
  }

  void _showAddonDialog({Addon? addon}) {
    final isEditing = addon != null;
    final nameController = TextEditingController(text: addon?.name ?? '');
    final priceController = TextEditingController(
      text: addon != null ? addon.price.toString() : '',
    );
    final stockController = TextEditingController(
      text: addon != null ? addon.stock.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isEditing ? 'Ubah Add-on' : 'Tambah Add-on'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input Nama
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Add-on / Topping',
                    hintText: 'Contoh: Extra Shot, Keju, Boba',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Input Harga Tambahan
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Harga Tambahan (Rp)',
                    hintText: 'Contoh: 3000',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.validateNonNegativeInt(
                    v,
                    label: 'Harga tambahan',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Input Stok
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    hintText: 'Contoh: 50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.validateNonNegativeInt(
                    v,
                    label: 'Stok',
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final name = nameController.text.trim();
                final price = int.parse(priceController.text.trim());
                final stock = int.parse(stockController.text.trim());

                Navigator.pop(dialogCtx);
                if (isEditing) {
                  context.read<AddonCubit>().editAddon(
                        Addon(
                          id: addon.id,
                          name: name,
                          price: price,
                          stock: stock,
                        ),
                      );
                } else {
                  context.read<AddonCubit>().addAddon(
                        name: name,
                        price: price,
                        stock: stock,
                      );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Addon addon) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Add-on?'),
        content: Text(
          'Add-on "${addon.name}" akan dihapus dari daftar kasir.\n\n'
          'Sesuai ketentuan, data transaksi lama yang memuat add-on ini akan tetap tersimpan aman (soft delete).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AddonCubit>().deleteAddon(addon.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AddonCubit, AddonState>(
      listener: (context, state) {
        if (state is AddonFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AddonLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final addons = state is AddonLoaded ? state.addons : <Addon>[];

        if (addons.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.extension_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Add-on',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan topping atau varian tambahan yang dapat dipilih kasir saat transaksi.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddonDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Add-on'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final addon = addons[index];
              final isOutOfStock = addon.stock <= 0;

              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isOutOfStock
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.extension_rounded,
                      color: isOutOfStock
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          addon.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Habis',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${RupiahFormatter.format(addon.price)}  •  Stok: ${addon.stock}',
                      style: TextStyle(
                        color: isOutOfStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Ubah Add-on',
                        onPressed: () => _showAddonDialog(addon: addon),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        tooltip: 'Hapus Add-on',
                        onPressed: () => _showDeleteConfirmation(addon),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddonDialog(),
            tooltip: 'Tambah Add-on',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

