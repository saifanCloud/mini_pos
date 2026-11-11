import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../receipt/presentation/screens/receipt_screen.dart';
import '../../domain/entities/report_filter.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';

/// Layar Tab Laporan Penjualan & Riwayat Transaksi dengan Filter Periode (F9 & D2 PRD).
/// - Pilihan cepat: Hari ini (default), 7 hari terakhir, Bulan ini, dan Kustom (date range picker).
/// - Kartu ringkasan omzet dan jumlah transaksi mengikuti filter aktif.
/// - Riwayat transaksi terurut terbaru di atas yang dapat diketuk untuk melihat struk digital.
class ReportTabView extends StatefulWidget {
  const ReportTabView({super.key});

  @override
  State<ReportTabView> createState() => _ReportTabViewState();
}

class _ReportTabViewState extends State<ReportTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportCubit>().loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<ReportCubit, ReportState>(
        builder: (context, state) {
          if (state.status == ReportStatus.loading && state.summary.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ReportStatus.error && state.summary.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Gagal memuat laporan',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.read<ReportCubit>().loadReport(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = state.summary;
          final dateRange = state.activeDateRange;
          final dateRangeText = _formatDateRangeSubtitle(dateRange.start, dateRange.end);

          return RefreshIndicator(
            onRefresh: () => context.read<ReportCubit>().loadReport(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Baris Filter Cepat Tanggal (D2 PRD)
                _buildFilterChips(context, state),

                const SizedBox(height: 8),

                // Info rentang tanggal aktif
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateRangeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Kartu Ringkasan Penjualan (F9 & D2 PRD)
                Row(
                  children: [
                    // Total Omzet
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Omzet',
                        value: RupiahFormatter.format(summary.totalRevenue),
                        icon: Icons.payments_outlined,
                        color: theme.colorScheme.primary,
                        bgColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.35),
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Transaksi Sukses
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Transaksi Sukses',
                        value: '${summary.totalTransactions}',
                        icon: Icons.receipt_long_outlined,
                        color: theme.colorScheme.secondary,
                        bgColor: theme.colorScheme.secondaryContainer
                            .withValues(alpha: 0.35),
                        theme: theme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Header Bagian Riwayat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${summary.totalTransactions} transaksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. Daftar Riwayat Transaksi / Empty State (F9 & D2 PRD)
                if (summary.isEmpty)
                  _buildEmptyState(theme, dateRangeText)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = summary.transactions[index];
                      final dateTime =
                          DateTime.tryParse(item.createdAt)?.toLocal();
                      final formattedDate = dateTime != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
                          : item.createdAt;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            // Ketuk membuka ReceiptScreen (F9 PRD)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceiptScreen(
                                  transactionId: item.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Ikon Struk
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.receipt_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Detail Transaksi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '#${item.id}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kasir: ${item.cashierName} • ${item.totalItems} item',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Total Uang & Panah
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      RupiahFormatter.format(item.total),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ReportState state) {
    final cubit = context.read<ReportCubit>();

    String customLabel = 'Kustom';
    if (state.filterType == ReportFilterType.custom &&
        state.customStart != null &&
        state.customEnd != null) {
      final startFmt = DateFormat('d/M').format(state.customStart!);
      final endFmt = DateFormat('d/M').format(state.customEnd!);
      customLabel = '$startFmt - $endFmt';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Hari Ini (Bawaan)
          ChoiceChip(
            label: const Text('Hari ini'),
            selected: state.filterType == ReportFilterType.today,
            onSelected: (_) => cubit.setFilter(ReportFilterType.today),
          ),
          const SizedBox(width: 8),

          // 7 Hari Terakhir
          ChoiceChip(
            label: const Text('7 hari terakhir'),
            selected: state.filterType == ReportFilterType.last7Days,
            onSelected: (_) => cubit.setFilter(ReportFilterType.last7Days),
          ),
          const SizedBox(width: 8),

          // Bulan Ini
          ChoiceChip(
            label: const Text('Bulan ini'),
            selected: state.filterType == ReportFilterType.thisMonth,
            onSelected: (_) => cubit.setFilter(ReportFilterType.thisMonth),
          ),
          const SizedBox(width: 8),

          // Rentang Kustom (Date Range Picker)
          ChoiceChip(
            avatar: const Icon(Icons.date_range, size: 16),
            label: Text(customLabel),
            selected: state.filterType == ReportFilterType.custom,
            onSelected: (_) => _pickCustomRange(context, state),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context, ReportState state) async {
    final now = DateTime.now();
    final initialStart = state.customStart ?? now;
    final initialEnd = state.customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Pilih Rentang Tanggal Laporan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null && context.mounted) {
      context.read<ReportCubit>().setFilter(
            ReportFilterType.custom,
            customStart: picked.start,
            customEnd: picked.end,
          );
    }
  }

  String _formatDateRangeSubtitle(DateTime start, DateTime end) {
    final startFmt = DateFormat('d MMM yyyy').format(start);
    final endFmt = DateFormat('d MMM yyyy').format(end);

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return 'Periode: $startFmt';
    }
    return 'Periode: $startFmt s/d $endFmt';
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String periodText) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ditemukan transaksi penjualan untuk $periodText.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
