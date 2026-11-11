# Mini POS — Aplikasi Kasir Offline Mandiri

Aplikasi Point of Sale (POS) kasir mandiri yang dirancang untuk bisnis F&B dan retail skala kecil hingga menengah. Aplikasi ini berjalan **100% offline** di perangkat kasir tanpa memerlukan koneksi internet, dengan fokus utama pada kecepatan transaksi satu tangan (UX ergonomis), integritas data transaksi historis, dan arsitektur kode yang modular dan mudah diuji.

---

## Daftar Isi
- [Fitur Utama](#fitur-utama)
- [Cara Menjalankan Aplikasi](#cara-menjalankan-aplikasi)
- [Arsitektur Perangkat Lunak](#arsitektur-perangkat-lunak)
- [State Management](#state-management)
- [Struktur Database & Integritas Data](#struktur-database--integritas-data)
- [Alur Data Transaksi](#alur-data-transaksi)
- [Bonus yang Diselesaikan](#bonus-yang-diselesaikan)
- [Catatan Keterbatasan](#catatan-keterbatasan)

---

## Fitur Utama

### 1. Autentikasi & Sesi Kasir Lokal
- **Registrasi & Login:** Akun kasir disimpan secara lokal pada database SQLite.
- **Keamanan Password:** Password di-hash menggunakan algoritma PBKDF2/SHA-256 dengan *salt* acak unik per pengguna. Teks sandi asli tidak pernah tersimpan di database.
- **Sesi Persisten:** Sesi kasir tetap aktif saat aplikasi ditutup dan dibuka kembali. Tombol keluar (*Logout*) tersedia di tab Pengaturan.

### 2. Pengelolaan Master Data (CRUD)
- **Kategori Produk:** Pengelompokan produk dengan nama unik. Menghapus kategori tidak menghapus produk di dalamnya (beralih menjadi *Tanpa Kategori*).
- **Add-on / Topping:** Varian pelengkap produk (misalnya: *Extra Shot*, *Boba*, *Keju*) dengan harga tambahan dan pelacakan stok mandiri.
- **Produk dengan Foto Offline:** Produk memiliki harga, kategori, relasi ke banyak add-on, sisa stok, dan foto yang disimpan permanen di direktori dokumen internal aplikasi (tidak terhapus saat pembersihan cache sementara sistem).
- **Soft Delete:** Penghapusan produk dan add-on menandai status `is_active = 0` sehingga tidak lagi muncul di katalog kasir namun seluruh riwayat transaksi lama tetap utuh tanpa error *foreign key* atau nilai `null`.

### 3. Layar Kasir & Keranjang Belanja Ergonomis
- **Pencarian Real-Time:** Filter instan nama produk langsung saat mengetik dilengkapi tombol hapus teks satu ketukan.
- **Filter Kategori Satu Baris:** Chip kategori horizontal mendatar dengan chip *Semua* di awal.
- **Kartu Produk Informatif:** Foto dengan sudut membulat, label sisa stok, indikator peringatan oranye saat stok menipis ($\le 3$), status redup berlabel *Habis* saat stok 0, serta badge jumlah item yang sudah ada di keranjang.
- **Bottom Sheet Add-on:** Menampilkan nama produk, harga dasar, daftar pilihan topping dengan sisa stoknya, kalkulasi subtotal unit sementara, dan tombol tambah besar.
- **Keranjang Belanja:** Kontrol kuantitas (`+` dan `-`) dengan area sentuh ramah jempol minimal $48 \times 48\text{ dp}$, fitur geser baris (*swipe-to-dismiss*) untuk menghapus item, serta tombol kosongkan keranjang dengan konfirmasi.
- **Validasi Stok Bersama (Aturan B1):** Menolak penambahan jika kombinasi produk polos dan produk bervarian add-on melebihi sisa stok produk fisik atau sisa stok add-on terkait.

### 4. Pembayaran Tunai & Quick Cash
- **Kalkulasi Biaya Terproteksi (Aturan B4):** Subtotal, diskon (persen atau nominal), dan total tagihan dihitung secara otomatis. Diskon persen divalidasi dan di-clamp maksimal 100%, diskon nominal tidak boleh melebihi subtotal, dan total tagihan tidak pernah negatif.
- **Quick Cash (D3):** Tombol *Uang Pas* dan pecahan pembulatan nominal terdekat di atas total (10.000, 20.000, 50.000, 100.000 tanpa duplikat) yang mengisi uang diterima dalam satu ketukan.
- **Hitungan Kembalian:** Ditampilkan secara besar dan jelas dengan warna hijau saat uang mencukupi, atau indikator warna merah saat uang masih kurang.
- **Tombol Konfirmasi Mengambang:** Tombol bayar berada di bar bawah yang selalu terlihat dan tidak terhalang keyboard.

### 5. Struk Digital Penjualan
- **Gaya Kertas Kasir:** Tampilan struk kasir berlatar putih dengan font monospasi sistem, garis pemisah putus-putus (*dashed line*), dan perataan kiri-kanan rapi.
- **Snapshot Penuh (Aturan B2):** Seluruh data struk (nama toko, alamat toko, nama kasir, nama produk, harga satuan, dan add-on) dibaca murni dari tabel transaksi dan tabel snapshot tanpa join ke data master.
- **Akses Transaksi Baru:** Tombol yang mengosongkan keranjang belanja dan langsung membawa kasir kembali ke layar katalog produk siap melayani pelanggan berikutnya.

### 6. Laporan & Omzet Penjualan Offline
- **Ringkasan Kartu Metrik:** Menampilkan total pendapatan (omzet) dan total transaksi sukses.
- **Filter Tanggal Cepat (D2):** Pilihan rentang *Hari Ini* (bawaan), *7 Hari Terakhir*, *Bulan Ini*, dan *Rentang Kustom* menggunakan pemilih kalender tanggal.
- **Daftar Riwayat:** Transaksi terurut dari yang paling baru di atas. Mengetuk riwayat akan membuka tampilan struk digital transaksi bersangkutan.

### 7. Pengaturan Toko
- Form untuk mengubah nama toko dan alamat toko yang otomatis menjadi identitas header pada setiap struk transaksi baru.

---

## Cara Menjalankan Aplikasi

### Kebutuhan Lingkungan
- Flutter SDK versi 3.19.0 atau yang lebih baru (channel stable)
- Dart SDK versi 3.3.0 atau yang lebih baru
- Android Studio / VS Code dengan ekstensi Flutter
- Perangkat Android fisik atau Emulator (Android 8.0 Oreo / API level 26 ke atas)

### Langkah Pemasangan & Menjalankan

1. **Unduh repositori dan buka terminal:**
   ```bash
   git clone <url-repository>
   cd mini_pos
   ```

2. **Pasang seluruh dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan seluruh rangkaian tes otomatis:**
   ```bash
   flutter test
   ```
   *Seluruh 93 unit dan widget test akan dieksekusi untuk memverifikasi logika stok bersama, proteksi diskon, perhitungan Quick Cash, snapshotting, filter tanggal, dan state management.*

4. **Jalankan aplikasi di perangkat/emulator:**
   ```bash
   flutter run
   ```

5. **Membangun APK Rilis Offline:**
   ```bash
   flutter build apk --release
   ```
   Berkas APK hasil build berada di: `build/app/outputs/flutter-apk/app-release.apk`.

---

## Arsitektur Perangkat Lunak

Proyek ini menerapkan **Clean Architecture ringan dengan pendekatan berbasis fitur (*Feature-First*)**. Pendekatan ini memisahkan kode berdasarkan domain bisnis sehingga tiap fitur bersifat modular, mandiri, dan mudah dipahami.

```
lib/
├── app.dart                   # Root MaterialApp & Global BlocProviders
├── main.dart                  # Titik masuk utama aplikasi & inisialisasi GetIt
├── core/                      # Utilitas, tema, dan widget bersama
│   ├── database/              # SQLite database helper & skema tabel
│   ├── di/                    # Dependency injection (GetIt service locator)
│   ├── theme/                 # Tema Material 3, konstanta jarak & gaya teks
│   ├── utils/                 # Formatter Rupiah, hasher sandi, validator, penyimpanan gambar
│   └── widgets/               # Widget bersama (EmptyState, ErrorView, LoadingView, PriceText, dll)
└── features/                  # Modul fitur berbasis Clean Architecture
    ├── auth/                  # Fitur login, register, sesi kasir
    ├── category/              # Fitur master kategori produk
    ├── addon/                 # Fitur master add-on & topping
    ├── product/               # Fitur master produk & gambar offline
    ├── cashier/               # Fitur katalog kasir, keranjang, domain validasi stok, checkout
    ├── receipt/               # Fitur struk digital snapshot
    ├── report/                # Fitur laporan omzet & filter tanggal
    └── settings/              # Fitur profil kasir & pengaturan toko
```

### Lapisan (*Layer*) pada Setiap Fitur

Setiap folder fitur memiliki 3 lapisan dengan aturan ketergantungan searah:

1. **Domain Layer (`domain/`)**
   - Berisi *Entities*, *Contracts/Interfaces Repository*, dan *Pure Logic / Use Cases* (`cart_logic.dart`).
   - Murni kode Dart tanpa ketergantungan terhadap Flutter framework, widget, maupun SQLite.
   - Menjamin bahwa aturan bisnis kritis (seperti validasi stok dan proteksi diskon) dapat diuji 100% menggunakan unit test murni tanpa mock UI atau database.

2. **Data Layer (`data/`)**
   - Berisi *Models* (konversi JSON / Map SQLite), sumber data SQLite (`DatabaseHelper`), dan implementasi nyata dari kontrak repository (`*_repository_impl.dart`).
   - Bertanggung jawab melakukan query database, transaksi atomik, dan snapshot data.

3. **Presentation Layer (`presentation/`)**
   - Berisi *Cubit & State* untuk manajemen status, *Screens/Views*, dan *Widgets* spesifik fitur.
   - Hanya bertugas menampilkan data dan mengirimkan input kasir ke Cubit. Tidak ada logika bisnis di dalam widget.

### Aturan Ketergantungan
$$\text{Presentation Layer} \longrightarrow \text{Domain Layer} \longleftarrow \text{Data Layer}$$
Lapisan Presentation dan Data sama-sama bergantung pada Domain. Lapisan Domain berdiri sendiri dan tidak mengenal detail implementasi UI maupun database.

---

## State Management

Aplikasi menggunakan **Bloc / Cubit** dari package `flutter_bloc` bersama `equatable`.

### Alasan Pemilihan Cubit
1. **Predictable & Ringan:** Aliran state bersifat searah (*unidirectional data flow*). Setiap perubahan data memicu state baru yang *immutable*.
2. **Minim Boilerplate:** Berbeda dengan Bloc penuh yang memerlukan kelas *Event* untuk setiap aksi kecil, Cubit menggunakan pemanggilan method langsung (`cubit.addToCart()`, `cubit.loadReport()`) yang ringkas dan sangat cocok untuk aplikasi POS.
3. **Pemisahan Tanggung Jawab:** Setiap fitur memiliki Cubit sendiri (`AuthCubit`, `CategoryCubit`, `ProductCubit`, `AddonCubit`, `CartCubit`, `CheckoutCubit`, `ReceiptCubit`, `ReportCubit`, `SettingsCubit`).
4. **Kemudahan Pengujian:** State Cubit dapat diuji secara terisolasi tanpa memerlukan rendering UI Flutter (`bloc_test` / unit test).

---

## Struktur Database & Integritas Data

Database lokal menggunakan SQLite via package `sqflite` dengan penegakan relasi integritas:
```sql
PRAGMA foreign_keys = ON;
```

### Relasi Skema Tabel

```
+---------------+       +------------------+       +---------------+
|  categories   |       |     products     |       |    addons     |
+---------------+       +------------------+       +---------------+
| id (PK)       |<------| id (PK)          |------>| id (PK)       |
| name          |       | category_id (FK) |       | name          |
| is_active     |       | name             |       | price         |
+---------------+       | price, stock     |       | stock         |
                        | photo_path       |       | is_active     |
                        | is_active        |       +---------------+
                        +------------------+               |
                                 |                         |
                        +------------------+               |
                        |  product_addons  |               |
                        +------------------+               |
                        | product_id (FK)  |               |
                        | addon_id (FK)    |<--------------+
                        +------------------+
                                 |
+--------------------------------+--------------------------------+
|                                                                 |
v                                                                 v
+-----------------------+   1:N   +-----------------------+   1:N   +---------------------------+
|     transactions      |-------->|   transaction_items   |-------->|  transaction_item_addons  |
+-----------------------+         +-----------------------+         +---------------------------+
| id (PK)               |         | id (PK)               |         | id (PK)                   |
| cashier_name (SNAP)   |         | transaction_id (FK)   |         | transaction_item_id (FK)  |
| store_name (SNAP)     |         | product_name (SNAP)   |         | addon_name (SNAP)         |
| store_address (SNAP)  |         | unit_price (SNAP)     |         | unit_price (SNAP)         |
| subtotal, total       |         | qty                   |         | qty                       |
| discount_amount       |         +-----------------------+         +---------------------------+
| paid, change_amount   |
| created_at (INDEXED)  |
+-----------------------+
```

### Tiga Pilar Integritas Data

#### 1. Snapshot Data (Aturan B2)
Pada aplikasi kasir, data transaksi masa lalu **tidak boleh berubah** ketika master data disunting atau dihapus di masa depan.
- **Implementasi:** Tabel `transactions`, `transaction_items`, dan `transaction_item_addons` menduplikasi (*snapshot*) nama kasir, nama toko, alamat toko, nama produk, nama add-on, serta harga satuan saat transaksi terjadi.
- **Hasil:** Jika kasir menjual produk seharga Rp15.000, lalu besok pemilik toko menaikkan harga master menjadi Rp20.000 atau bahkan menghapus produk tersebut, struk transaksi lama dan laporan omzet tetap valid menampilkan harga Rp15.000.

#### 2. Soft Delete
- **Implementasi:** Tabel `products`, `categories`, dan `addons` memiliki kolom `is_active INTEGER NOT NULL DEFAULT 1`.
- **Hasil:** Saat produk atau add-on dihapus oleh pengguna, baris data tidak dihapus permanen (`DELETE`), melainkan diperbarui menjadi `is_active = 0`. Hal ini mencegah kegagalan relasi *Foreign Key Constraint* pada data transaksi historis sekaligus memastikan item terhapus tidak muncul di katalog kasir.

#### 3. Transaksi Atomik (Aturan B5)
Pengurangan stok dan pencatatan transaksi wajib memiliki sifat atomik (*all-or-nothing*):
- **Implementasi:** Seluruh operasi penyimpanan dibungkus dalam satu blok transaksi database:
  ```dart
  await db.transaction((txn) async {
    // 1. Validasi ulang stok terbaru dari database
    // 2. Simpan header transaksi (transactions)
    // 3. Simpan rincian item (transaction_items)
    // 4. Simpan rincian add-on (transaction_item_addons)
    // 5. Kurangi stok produk: UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?
    // 6. Kurangi stok add-on: UPDATE addons SET stock = stock - ? WHERE id = ? AND stock >= ?
    // Jika baris yang terpengaruh == 0 (stok mendadak habis), lemparkan Exception untuk rollback
  });
  ```
- **Hasil:** Jika terjadi kesalahan sistem atau kegagalan daya di tengah penyimpanan, seluruh operasi dibatalkan otomatis (*rollback*). Stok barang tidak akan pernah berkurang tanpa adanya catatan transaksi yang sah.

---

## Alur Data Transaksi

```
[Katalog Kasir]
       │
       ▼  (1 ketuk produk biasa / pilih topping pada bottom sheet)
[CartCubit] ──▶ Validasi stok bersama via CartLogic (Domain murni)
       │
       ▼  (Tekan tombol Bayar)
[PaymentScreen & CheckoutCubit]
       │
       ▼  (Input diskon & Quick Cash Uang Pas)
[Validasi Pembayaran] ──▶ Uang diterima >= Total Tagihan
       │
       ▼  (Tekan Konfirmasi Bayar)
[TransactionRepositoryImpl]
       │
       ▼  (db.transaction ACID di SQLite)
       ├── Validasi ulang stok
       ├── Insert header transaksi (Snapshot Kasir & Toko)
       ├── Insert item & add-on (Snapshot Nama & Harga)
       └── Pengurangan stok aman (WHERE stock >= ?)
       │
       ▼  (Berhasil disimpan)
[Clear Keranjang] ──▶ Buka [ReceiptScreen] (Membaca murni dari Snapshot)
```

---

## Bonus yang Diselesaikan

- **C3 — Cubit & Pemisahan UI dan Logika Bisnis:** Seluruh aturan perhitungan subtotal, validasi batas stok produk + add-on bersama, dan proteksi diskon diletakkan di kelas domain murni `CartLogic` dan diuji secara otomatis dengan 93 unit test.
- **C4 — SQLite, Skema Relasional, dan Transaksi Atomik:** Menggunakan skema relasional 9 tabel dengan *Foreign Keys*, indeks tanggal transaksi `idx_transactions_created_at`, mekanisme *snapshotting* data historis, serta transaksi database atomik untuk menjamin integritas data ACID.
- **C5 — Layout Responsif Tablet & Mobile:** Layout kasir otomatis menyesuaikan lebar layar perangkat (2 kolom untuk ponsel, 3–4 kolom adaptif untuk tablet) dengan pencegahan *overflow* pada layar kecil.
- **D2 — Filter Tanggal pada Laporan:** Fitur pemilihan rentang waktu cepat (*Hari Ini*, *7 Hari Terakhir*, *Bulan Ini*, dan *Rentang Kustom* pemilih kalender). Query langsung membaca data ISO 8601 di SQLite memanfaatkan indeks kolom waktu.
- **D3 — Pembayaran Cepat (Quick Cash):** Tombol *Uang Pas* dan pilihan pembulatan pecahan terdekat di atas nominal tagihan untuk mempercepat penyelesaian transaksi tunai kasir dalam 3 ketukan.

---

## Catatan Keterbatasan

1. **Aplikasi 100% Offline Mandiri:** Tidak menyediakan sinkronisasi ke server *cloud* dan tidak memerlukan izin jaringan internet (`android.permission.INTERNET` ditiadakan).
2. **Khusus Transaksi Tunai:** Sistem dirancang untuk pencatatan transaksi tunai (*cash-only POS*). Pembayaran melalui kartu kredit, debit, atau QRIS tidak dicakup.
3. **Single-Device Perangkat:** Data tersimpan secara lokal pada basis data perangkat masing-masing, bukan sistem kasir terdistribusi multi-cabang.
