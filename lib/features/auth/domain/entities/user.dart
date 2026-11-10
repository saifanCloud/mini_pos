/// Entity User — layer domain, murni Dart.
/// Tidak boleh mengimpor Flutter, sqflite, atau package lain.
class User {
  final int id;
  final String name;
  final String username;
  final String createdAt; // ISO 8601

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.createdAt,
  });
}

