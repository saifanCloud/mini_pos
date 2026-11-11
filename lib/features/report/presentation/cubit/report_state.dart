import 'package:equatable/equatable.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/report_summary.dart';

enum ReportStatus { initial, loading, loaded, error }

/// State laporan penjualan dengan dukungan filter tanggal (D2 PRD).
class ReportState extends Equatable {
  final ReportStatus status;
  final ReportSummary summary;
  final String? errorMessage;

  // Filter aktif (D2 PRD)
  final ReportFilterType filterType;
  final DateTime? customStart;
  final DateTime? customEnd;

  const ReportState({
    this.status = ReportStatus.initial,
    this.summary = const ReportSummary(
      totalRevenue: 0,
      totalTransactions: 0,
      transactions: [],
    ),
    this.errorMessage,
    this.filterType = ReportFilterType.today,
    this.customStart,
    this.customEnd,
  });

  /// Rentang tanggal aktif sesuai filter yang dipilih.
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
    String? errorMessage,
    bool clearError = false,
    ReportFilterType? filterType,
    DateTime? customStart,
    DateTime? customEnd,
    bool clearCustom = false,
  }) {
    return ReportState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filterType: filterType ?? this.filterType,
      customStart: clearCustom ? null : customStart ?? this.customStart,
      customEnd: clearCustom ? null : customEnd ?? this.customEnd,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        errorMessage,
        filterType,
        customStart,
        customEnd,
      ];
}

