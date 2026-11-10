import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utilitas penyimpanan foto produk secara persisten di perangkat.
///
/// Sesuai B3 PRD:
/// - Foto disalin ke folder dokumen aplikasi (bukan cache) agar tetap ada
///   setelah app ditutup, direstart, atau cache dibersihkan.
/// - Hanya nama file (bukan path absolut) yang disimpan ke database,
///   karena path absolut bisa berubah antar instalasi.
/// - Jika file tidak ditemukan, pemanggil cukup menampilkan gambar pengganti.
class ImageStorage {
  static const _subFolder = 'product_photos';

  /// Dapatkan direktori penyimpanan foto produk.
  /// Subfolder dibuat otomatis jika belum ada.
  static Future<Directory> _getPhotoDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(docDir.path, _subFolder));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  /// Salin [sourceFile] ke folder dokumen aplikasi dengan nama unik.
  /// Kembalikan nama file saja (bukan path penuh) untuk disimpan ke database.
  /// Jika [sourceFile] tidak ada, lempar exception.
  static Future<String> saveImage(File sourceFile) async {
    final photoDir = await _getPhotoDir();
    final ext = p.extension(sourceFile.path); // misalnya ".jpg"
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(p.join(photoDir.path, fileName));
    await sourceFile.copy(dest.path);
    return fileName; // simpan nama ini ke kolom photo_path di database
  }

  /// Bentuk path absolut dari [fileName] (nama file yang tersimpan di database).
  /// Kembalikan null jika [fileName] kosong atau null — UI menampilkan placeholder.
  static Future<String?> fullPath(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    final photoDir = await _getPhotoDir();
    return p.join(photoDir.path, fileName);
  }

  /// Hapus file foto lama saat foto produk diganti (B3 PRD).
  /// Aman dipanggil meski file tidak ada — tidak melempar exception.
  static Future<void> deleteImage(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    try {
      final photoDir = await _getPhotoDir();
      final file = File(p.join(photoDir.path, fileName));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Abaikan error penghapusan — tidak kritis.
    }
  }
}

