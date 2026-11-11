import 'package:equatable/equatable.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/report_summary.dart';

enum ReportStatus { initial, loading, loaded, error }

/// State untuk laporan penjualan dan riwayat transaksi dengan filter tanggal (F9 & D2 PRD).
class ReportState extends Equatable {
  final ReportStatus status;
  final ReportSummary summary;
  final ReportFilterType filterType;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? errorMessage;

  const ReportState({
    this.status = ReportStatus.initial,
    this.summary = const ReportSummary(),
    this.filterType = ReportFilterType.today, // Bawaan: Hari ini (D2 PRD)
    this.customStart,
    this.customEnd,
    this.errorMessage,
  });

  /// Menghitung batas awal hari (00:00:00) dan akhir hari (23:59:59) untuk filter yang aktif.
  ({DateTime start, DateTime end}) get activeDateRange {
    return DateRangeHelper.getDateRange(
      filterType,
      customStart: customStart,
      customEnd: customEnd,
    );
  }

  ReportState copyWith({
    ReportStatus? status,
    ReportSummary? summary,
    ReportFilterType? filterType,
    DateTime? customStart,
    DateTime? customEnd,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      filterType: filterType ?? this.filterType,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        filterType,
        customStart,
        customEnd,
        errorMessage,
      ];
}
