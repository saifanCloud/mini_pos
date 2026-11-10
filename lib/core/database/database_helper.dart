import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Satu-satunya titik akses ke database SQLite aplikasi.
/// Gunakan [DatabaseHelper.instance] di mana pun perlu query database.
class DatabaseHelper {
  static const _dbName = 'mini_pos.db';
  static const _dbVersion = 1;

  // Singleton: satu instance selama app berjalan, satu koneksi database.
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  /// Mengembalikan database yang sudah terbuka.
  /// Jika belum terbuka, buka terlebih dahulu (lazy init).
  Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// Aktifkan foreign key constraint sebelum transaksi apa pun dijalankan.
  /// Harus dilakukan di onConfigure, bukan di onCreate.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Buat semua tabel dan isi data bawaan saat database pertama kali dibuat.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_sqlUsers);
    await db.execute(_sqlAppSession);
    await db.execute(_sqlStoreSettings);
    await db.execute(_sqlCategories);
    await db.execute(_sqlProducts);
    await db.execute(_sqlAddons);
    await db.execute(_sqlProductAddons);
    await db.execute(_sqlTransactions);
    await db.execute(_sqlTransactionItems);
    await db.execute(_sqlTransactionItemAddons);
    await db.execute(_sqlIndexTransactions);

    // Data bawaan: satu baris store_settings (id = 1 dijaga oleh CHECK constraint).
    // Kasir bisa mengubah nilai ini lewat layar Pengaturan.
    await db.insert('store_settings', {
      'id': 1,
      'store_name': 'Toko Saya',
      'address': '',
    });
  }

  // ─── DDL — skema tabel sesuai PRD bagian 7 ──────────────────────────────────

  static const _sqlUsers = '''
    CREATE TABLE users (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      name           TEXT    NOT NULL,
      username       TEXT    NOT NULL UNIQUE,
      password_hash  TEXT    NOT NULL,
      created_at     TEXT    NOT NULL
    )
  ''';

  /// Hanya boleh ada satu sesi aktif (CHECK id = 1).
  /// ON DELETE CASCADE: sesi otomatis terhapus jika user dihapus.
  static const _sqlAppSession = '''
    CREATE TABLE app_session (
      id            INTEGER PRIMARY KEY CHECK (id = 1),
      user_id       INTEGER NOT NULL,
      logged_in_at  TEXT    NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  ''';

  /// Hanya boleh ada satu baris pengaturan toko (CHECK id = 1).
  /// Diisi bawaan di onCreate, diperbarui via UPDATE bukan INSERT.
  static const _sqlStoreSettings = '''
    CREATE TABLE store_settings (
      id          INTEGER PRIMARY KEY CHECK (id = 1),
      store_name  TEXT NOT NULL,
      address     TEXT
    )
  ''';

  static const _sqlCategories = '''
    CREATE TABLE categories (
      id    INTEGER PRIMARY KEY AUTOINCREMENT,
      name  TEXT NOT NULL
    )
  ''';

  /// photo_path: nama file saja (bukan path absolut) di folder dokumen app.
  /// is_deleted: soft delete — produk terhapus tetap ada di database agar
  /// riwayat transaksi tidak rusak (B2 PRD).
  static const _sqlProducts = '''
    CREATE TABLE products (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id  INTEGER,
      name         TEXT    NOT NULL,
      price        INTEGER NOT NULL CHECK (price >= 0),
      stock        INTEGER NOT NULL CHECK (stock >= 0),
      photo_path   TEXT,
      is_deleted   INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
    )
  ''';

  /// is_deleted: soft delete, sama seperti products.
  static const _sqlAddons = '''
    CREATE TABLE addons (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      name       TEXT    NOT NULL,
      price      INTEGER NOT NULL CHECK (price >= 0),
      stock      INTEGER NOT NULL CHECK (stock >= 0),
      is_deleted INTEGER NOT NULL DEFAULT 0
    )
  ''';

  /// Tabel pivot many-to-many: produk ↔ add-on.
  /// ON DELETE CASCADE: baris pivot ikut terhapus jika produk atau add-on dihapus.
  static const _sqlProductAddons = '''
    CREATE TABLE product_addons (
      product_id  INTEGER NOT NULL,
      addon_id    INTEGER NOT NULL,
      PRIMARY KEY (product_id, addon_id),
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
      FOREIGN KEY (addon_id)   REFERENCES addons(id)   ON DELETE CASCADE
    )
  ''';

  /// Kolom snapshot: cashier_name, store_name, store_address disalin saat
  /// transaksi disimpan sehingga perubahan master tidak mengubah riwayat (B2).
  static const _sqlTransactions = '''
    CREATE TABLE transactions (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      cashier_id       INTEGER,
      cashier_name     TEXT    NOT NULL,
      store_name       TEXT    NOT NULL,
      store_address    TEXT,
      subtotal         INTEGER NOT NULL,
      discount_type    TEXT,
      discount_value   INTEGER NOT NULL DEFAULT 0,
      discount_amount  INTEGER NOT NULL DEFAULT 0,
      total            INTEGER NOT NULL CHECK (total >= 0),
      paid             INTEGER NOT NULL,
      change_amount    INTEGER NOT NULL,
      created_at       TEXT    NOT NULL
    )
  ''';

  /// product_id disimpan sebagai referensi lunak TANPA foreign key.
  /// Kolom snapshot product_name dan unit_price menjamin riwayat tidak berubah
  /// meski produk dihapus atau harganya diubah (B2).
  static const _sqlTransactionItems = '''
    CREATE TABLE transaction_items (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id  INTEGER NOT NULL,
      product_id      INTEGER,
      product_name    TEXT    NOT NULL,
      unit_price      INTEGER NOT NULL,
      qty             INTEGER NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
    )
  ''';

  /// addon_id juga tanpa foreign key, alasan sama dengan product_id di atas.
  /// Kolom snapshot addon_name dan unit_price menjaga integritas riwayat.
  static const _sqlTransactionItemAddons = '''
    CREATE TABLE transaction_item_addons (
      id                   INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_item_id  INTEGER NOT NULL,
      addon_id             INTEGER,
      addon_name           TEXT    NOT NULL,
      unit_price           INTEGER NOT NULL,
      qty                  INTEGER NOT NULL,
      FOREIGN KEY (transaction_item_id) REFERENCES transaction_items(id) ON DELETE CASCADE
    )
  ''';

  /// Indeks pada created_at untuk mempercepat query laporan berdasarkan tanggal (D2).
  static const _sqlIndexTransactions = '''
    CREATE INDEX idx_transactions_created_at ON transactions(created_at)
  ''';
}
