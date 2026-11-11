/// Jenis filter rentang waktu pada laporan penjualan (D2 PRD).
enum ReportFilterType {
  today,
  last7Days,
  thisMonth,
  custom,
}

/// Helper untuk menghitung batas waktu awal hari (00:00:00) dan akhir hari (23:59:59).
class DateRangeHelper {
  /// Batas awal hari: 00:00:00.000
  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 0, 0, 0, 0);
  }

  /// Batas akhir hari: 23:59:59.999
  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }

  /// Menghitung pasangan rentang (start, end) berdasarkan jenis filter yang dipilih.
  static ({DateTime start, DateTime end}) getDateRange(
    ReportFilterType type, {
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    switch (type) {
      case ReportFilterType.today:
        return (
          start: startOfDay(current),
          end: endOfDay(current),
        );

      case ReportFilterType.last7Days:
        final start = current.subtract(const Duration(days: 6));
        return (
          start: startOfDay(start),
          end: endOfDay(current),
        );

      case ReportFilterType.thisMonth:
        final start = DateTime(current.year, current.month, 1);
        final end = DateTime(current.year, current.month + 1, 0);
        return (
          start: startOfDay(start),
          end: endOfDay(end),
        );

      case ReportFilterType.custom:
        final start = customStart ?? current;
        final end = customEnd ?? current;
        return (
          start: startOfDay(start),
          end: endOfDay(end),
        );
    }
  }
}

