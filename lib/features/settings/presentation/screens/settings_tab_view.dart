import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

/// Tampilan Tab Pengaturan (F10 PRD).
/// Mengelola informasi toko (nama dan alamat untuk struk) serta profil kasir dan logout.
class SettingsTabView extends StatefulWidget {
  const SettingsTabView({super.key});

  @override
  State<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends State<SettingsTabView> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsCubit>().loadSettings();
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.loaded) {
          _storeNameController.text = state.settings.storeName;
          _addressController.text = state.settings.address ?? '';
        } else if (state.status == SettingsStatus.success) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengaturan toko berhasil disimpan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == SettingsStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state.status == SettingsStatus.saving;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profil Pengguna & Kasir
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          currentUser?.name.isNotEmpty == true
                              ? currentUser!.name[0].toUpperCase()
                              : 'K',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? 'Kasir',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${currentUser?.username ?? 'user'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Form Pengaturan Toko (F10 PRD)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Pengaturan Toko',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nama dan alamat toko ini akan otomatis dicetak pada struk transaksi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: 24),

                        // Nama Toko
                        TextFormField(
                          controller: _storeNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Toko *',
                            hintText: 'Contoh: Kopi Nusantara',
                            prefixIcon: const Icon(Icons.business_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama toko wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Alamat Toko
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Alamat Toko (Opsional)',
                            hintText: 'Contoh: Jl. Sudirman No. 10, Jakarta Pusat',
                            prefixIcon: const Icon(Icons.place_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Simpan
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSaving ? null : _saveSettings,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Tombol Logout
              FilledButton.tonalIcon(
                onPressed: () => _confirmLogout(context),
                icon: Icon(Icons.logout, color: theme.colorScheme.error),
                label: Text(
                  'Keluar Akun (Logout)',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _saveSettings() {
    if (_formKey.currentState?.validate() == true) {
      context.read<SettingsCubit>().saveStoreSettings(
            storeName: _storeNameController.text,
            address: _addressController.text,
          );
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi kasir saat ini?',
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
              context.read<AuthCubit>().logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
