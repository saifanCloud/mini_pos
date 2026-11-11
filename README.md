# Mini POS — Aplikasi Kasir Offline (Flutter)

Aplikasi Point of Sale (POS) mandiri untuk bisnis F&B dan retail yang berjalan **100% offline** di perangkat kasir menggunakan Flutter dan SQLite, tanpa koneksi internet maupun API eksternal.

---

## Ringkasan Fitur Utama

- **Autentikasi & Sesi Lokal:** Splash screen pengecekan sesi otomatis (`app_session`), register akun kasir, login offline dengan hash password (`SHA-256` + random salt), serta logout.
- **Master Data:** CRUD Kategori (dengan `ON DELETE SET NULL`), CRUD Produk (harga, stok, kategori, foto kamera/galeri persisten, relasi add-on, soft delete), dan CRUD Add-on / Topping (harga tambahan, stok terpisah, soft delete).
- **Layar Kasir Ergonomis:** Pencarian nama produk instan (real-time), filter chip kategori (`Semua` + daftar kategori), 1-ketuk untuk produk tanpa add-on, bottom sheet pemilihan add-on, serta pengelolaan keranjang (`+`/`-`, geser untuk hapus, kosongkan keranjang).
- **Pembayaran & Diskon:** Diskon persen (`0–100%`) atau nominal tetap (`0–subtotal`), input tunai, Quick Cash, perhitungan kembalian otomatis, dan penyimpanan transaksi secara atomik.
- **Struk Digital & Pengaturan Toko:** Preview struk digital setelah pembayaran dan dari riwayat transaksi, dilengkapi pengaturan nama serta alamat toko.
- **Laporan Penjualan Offline:** Ringkasan total omzet, jumlah transaksi sukses, riwayat transaksi (terbaru di atas), dan filter rentang tanggal.

---

## Arsitektur Proyek

Proyek ini menggunakan **Clean Architecture ringan berbasis fitur (feature-first)** agar kode modular, konsisten, dan memiliki pemisahan tanggung jawab yang jelas antara UI, logika bisnis, dan akses database.

```text
lib/
├── main.dart                     # Entry point & inisialisasi dependency injection
├── app.dart                      # MaterialApp, tema Material 3, dan Global BlocProviders
├── core/
│   ├── database/                 # database_helper.dart (SQLite DDL & PRAGMA foreign_keys)
│   ├── di/                       # injection.dart (GetIt service locator)
│   ├── theme/                    # Tema terpusat, spacing, dan text styles
│   ├── utils/                    # PasswordHasher, Validators, RupiahFormatter, ImageStorage
│   └── widgets/                  # Komponen UI reusable (PrimaryButton, PriceText, EmptyState, dll.)
└── features/
    ├── auth/                     # Splash, login, register, sesi lokal
    ├── category/                 # Master data kategori & shell tab Master Data
    ├── product/                  # Master data produk & foto offline persisten
    ├── addon/                    # Master data add-on / topping
    ├── cashier/                  # Katalog kasir, keranjang, validasi stok/diskon, checkout
    ├── receipt/                  # Struk digital dari snapshot transaksi
    ├── report/                   # Ringkasan omzet, riwayat transaksi, filter tanggal
    └── settings/                 # Pengaturan nama & alamat toko, profil kasir, logout
```

Setiap modul fitur dibagi ke dalam 3 layer dengan arah ketergantungan **presentation → domain ← data**:

1. **Domain Layer (`domain/`)**
   - Berisi **Entities**, **Repository Interfaces**, dan **Use Cases** (contoh: [`CartLogic`](lib/features/cashier/domain/usecases/cart_logic.dart) untuk validasi stok bersama dan proteksi diskon).
   - Murni Dart — tidak mengimpor Flutter maupun `sqflite`, sehingga logika kritis mudah diuji lewat unit test.
2. **Data Layer (`data/`)**
   - Berisi **Models** (mapping dari/ke `Map<String, dynamic>`) dan **Repository Implementations** yang mengakses SQLite melalui `DatabaseHelper`.
3. **Presentation Layer (`presentation/`)**
   - Berisi **Cubit**, **State**, **Screens**, dan **Widgets**. Widget hanya merender state dan memanggil aksi Cubit tanpa query database atau perhitungan bisnis langsung di UI.

---

## State Management

Aplikasi menggunakan **`flutter_bloc` (Cubit)** bersama **`equatable`** dan **`get_it`**:

| Cubit | Tanggung Jawab |
|---|---|
| `AuthCubit` | Pengecekan sesi lokal, login, register, dan logout |
| `CategoryCubit` | Memuat dan mengelola CRUD kategori |
| `AddonCubit` | Memuat dan mengelola CRUD add-on |
| `ProductCubit` | Memuat dan mengelola CRUD produk (termasuk pembersihan foto lama saat diganti) |
| `CashierCubit` | Memuat katalog aktif, pencarian real-time, filter kategori, dan lookup add-on produk |
| `CartCubit` | Mengelola item keranjang, penggabungan kombinasi add-on, dan validasi stok bersama via `CartLogic` |
| `CheckoutCubit` | Mengatur nominal bayar, rekomendasi Quick Cash, dan penyimpanan transaksi atomik |
| `ReceiptCubit` | Memuat detail transaksi snapshot untuk layar struk digital |
| `ReportCubit` | Memuat total omzet, jumlah transaksi, dan riwayat sesuai filter tanggal |
| `SettingsCubit` | Memuat dan memperbarui informasi toko (`store_settings`) |

**Alasan pemilihan Cubit:** Lebih ringkas dan mudah ditelusuri daripada BLoC penuh (tanpa boilerplate Event class), tetap menjaga pemisahan tegas antara UI dan business logic, serta menggunakan `Equatable` untuk perbandingan state yang prediktabel.

---

## Struktur Tabel Database (SQLite)

Seluruh data disimpan lokal di file `mini_pos.db` melalui [`DatabaseHelper`](lib/core/database/database_helper.dart) dengan `PRAGMA foreign_keys = ON` di `onConfigure`. Nominal harga/uang disimpan sebagai `INTEGER` dalam Rupiah, dan waktu disimpan dalam format teks ISO 8601.

| Tabel | Kolom Utama | Relasi & Catatan |
|---|---|---|
| `users` | `id`, `name`, `username` (`UNIQUE`), `password_hash`, `created_at` | Password disimpan dalam format `salt:sha256_hash` |
| `app_session` | `id` (`CHECK id = 1`), `user_id`, `logged_in_at` | Maksimal 1 sesi aktif; `FK user_id -> users(id) ON DELETE CASCADE` |
| `store_settings` | `id` (`CHECK id = 1`), `store_name`, `address` | Diisi default `"Toko Saya"` saat database dibuat |
| `categories` | `id`, `name` | Master kategori produk |
| `products` | `id`, `category_id`, `name`, `price`, `stock`, `photo_path`, `is_deleted` | `FK category_id -> categories(id) ON DELETE SET NULL`; soft delete (`is_deleted = 1`); `photo_path` hanya menyimpan nama file di dokumen aplikasi |
| `addons` | `id`, `name`, `price`, `stock`, `is_deleted` | Master add-on dengan stok terpisah & soft delete |
| `product_addons` | `product_id`, `addon_id` | Pivot many-to-many (`ON DELETE CASCADE`) |
| `transactions` | `id`, `cashier_id`, `cashier_name`, `store_name`, `store_address`, `subtotal`, `discount_type`, `discount_value`, `discount_amount`, `total`, `paid`, `change_amount`, `created_at` | Menyimpan snapshot kasir & toko; diindeks oleh `idx_transactions_created_at` |
| `transaction_items` | `id`, `transaction_id`, `product_id`, `product_name`, `unit_price`, `qty` | `FK transaction_id -> transactions(id) ON DELETE CASCADE`; menyimpan snapshot produk |
| `transaction_item_addons` | `id`, `transaction_item_id`, `addon_id`, `addon_name`, `unit_price`, `qty` | `FK transaction_item_id -> transaction_items(id) ON DELETE CASCADE`; menyimpan snapshot add-on |

### Catatan Desain Integritas Data
- **Immutability Riwayat (Snapshot & Soft Delete):** `product_id` dan `addon_id` pada `transaction_items` dan `transaction_item_addons` sengaja **tidak menggunakan foreign key**, sedangkan penghapusan master memakai `is_deleted = 1`. Nama dan harga disalin saat transaksi disimpan sehingga perubahan harga atau penghapusan master tidak mengubah struk lama maupun laporan.
- **Validasi Stok Bersama (`CartLogic`):** Akumulasi pemakaian stok produk dihitung lintas semua baris keranjang terlepas dari variasi add-on-nya (`produkTerpakai`), dan pemakaian stok add-on dihitung lintas semua produk (`addonTerpakai`).
- **Transaksi Atomik (`TransactionRepositoryImpl`):** Penyimpanan header transaksi, item, add-on, validasi ulang stok terbaru, dan pengurangan stok (`UPDATE ... SET stock = stock - ? WHERE id = ? AND stock >= ?`) dibungkus dalam satu `db.transaction(...)`. Jika salah satu langkah gagal, seluruh perubahan di-rollback otomatis.
- **Foto Offline Persisten (`ImageStorage`):** Foto dari kamera/galeri disalin ke subfolder `product_photos/` di `getApplicationDocumentsDirectory()` agar tidak hilang saat cache sistem dibersihkan, dan foto lama dihapus saat diganti.

---

## Fitur Bonus yang Diimplementasikan

1. **State Management dengan Cubit (`flutter_bloc`) & GetIt (Bagian C.3):** Pemisahan jelas antara UI, Cubit, dan layer domain/data.
2. **SQLite Relasional & Transaksi Atomik (Bagian C.4):** Skema relasional 10 tabel dengan foreign key terkonfigurasi dan pengurangan stok atomik.
3. **Filter Tanggal pada Laporan Penjualan (Bagian D.2):** Pilihan cepat **Hari ini**, **7 Hari Terakhir**, **Bulan Ini**, dan rentang **Kustom** (`showDateRangePicker`) dengan indeks `created_at`.
4. **Quick Cash pada Pembayaran (Bagian D.3):** Tombol **Uang Pas** serta hingga 3 rekomendasi nominal pembulatan terdekat di atas total tagihan (`Rp10.000`, `Rp20.000`, `Rp50.000`, `Rp100.000`).
5. **Indikator Stok Menipis / Habis (Bagian D.3):** Penanda visual stok menipis (`stok <= 3`) dan label `Habis` (`stok == 0`) pada kartu produk kasir maupun daftar add-on.
6. **Grid Kasir Adaptif (Bagian C.5 - Parsial):** Menggunakan `LayoutBuilder` untuk menyesuaikan jumlah kolom produk berdasarkan lebar layar (2 kolom di mobile, 3 kolom di layar `>= 600dp`, dan 4 kolom di layar `>= 840dp`).

---

## Cara Menjalankan & Menguji

### Prasyarat
- Flutter SDK `3.47.9` (atau versi stable kompatibel) dengan Dart `^3.13.7`
- Android SDK / Emulator atau perangkat fisik Android

### Langkah Menjalankan
```bash
# 1. Pasang dependencies
flutter pub get

# 2. Jalankan static analysis
flutter analyze

# 3. Jalankan seluruh unit & widget test (95 test)
flutter test

# 4. Jalankan aplikasi di perangkat/emulator
flutter run

# 5. Build APK Release (output: build/app/outputs/flutter-apk/app-release.apk)
flutter build apk --release
```

---

## Catatan Keterbatasan

- Fokus desain utama adalah perangkat **mobile**; pada layar lebar/tablet, grid katalog sudah beradaptasi menjadi 3–4 kolom namun panel keranjang masih menggunakan bottom bar & modal bottom sheet (belum menggunakan tampilan 2-panel berdampingan).
- Fitur **cetak printer thermal Bluetooth (ESC/POS)**, **grafik/chart laporan**, dan **Hold / Save Bill** berada di luar ruang lingkup implementasi saat ini.
- Konfigurasi `buildTypes.release` pada Android saat ini menggunakan debug signing config bawaan Flutter agar APK release dapat langsung di-build dan diuji secara lokal.
