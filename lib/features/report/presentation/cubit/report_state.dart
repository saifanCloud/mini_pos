import 'package:equatable/equatable.dart';
import '../../domain/entities/report_summary.dart';

enum ReportStatus { initial, loading, loaded, error }

/// State untuk laporan penjualan dan riwayat transaksi (F9 PRD).
class ReportState extends Equatable {
  final ReportStatus status;
  final ReportSummary summary;
  final String? errorMessage;

  const ReportState({
    this.status = ReportStatus.initial,
    this.summary = const ReportSummary(),
    this.errorMessage,
  });

  ReportState copyWith({
    ReportStatus? status,
    ReportSummary? summary,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}

