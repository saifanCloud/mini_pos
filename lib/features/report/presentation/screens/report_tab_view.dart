import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../receipt/presentation/screens/receipt_screen.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/report_summary.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';

/// Tab Laporan Penjualan (F9 & D2 PRD).
/// - Kartu ringkasan total omzet & jumlah transaksi.
/// - Filter cepat: Hari ini (bawaan), 7 hari terakhir, Bulan ini, Kustom.
/// - Daftar riwayat transaksi terbaru di atas, ketuk membuka struk.
/// - Empty state saat belum ada transaksi.
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

  Future<void> _pickCustomRange(BuildContext context) async {
    final state = context.read<ReportCubit>().state;
    final initial = state.filterType == ReportFilterType.custom &&
            state.customStart != null &&
            state.customEnd != null
        ? DateTimeRange(start: state.customStart!, end: state.customEnd!)
        : DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 6)),
            end: DateTime.now(),
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initial,
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );

    if (picked != null && context.mounted) {
      context.read<ReportCubit>().setFilter(
            ReportFilterType.custom,
            customStart: picked.start,
            customEnd: picked.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<ReportCubit>().loadReport(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Filter Tanggal Cepat (D2 PRD) ──
                      _buildFilterChips(context, state, theme),

                      // Label rentang aktif
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: _buildActiveDateLabel(state, theme),
                      ),

                      // ── Kartu Ringkasan ──
                      _buildSummaryCard(state, theme),
                      const SizedBox(height: 20),

                      Text(
                        'Riwayat Transaksi',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Daftar Riwayat / Loading / Empty State ──
              if (state.status == ReportStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == ReportStatus.error)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage ?? 'Gagal memuat laporan',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.read<ReportCubit>().loadReport(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (state.summary.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Transaksi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Transaksi yang selesai akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: state.summary.transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = state.summary.transactions[index];
                      return _buildTransactionTile(tx, theme, context);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    ReportState state,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(context, state, ReportFilterType.today, 'Hari ini'),
          const SizedBox(width: 8),
          _filterChip(
              context, state, ReportFilterType.last7Days, '7 Hari Terakhir'),
          const SizedBox(width: 8),
          _filterChip(
              context, state, ReportFilterType.thisMonth, 'Bulan Ini'),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Kustom'),
            selected: state.filterType == ReportFilterType.custom,
            avatar: const Icon(Icons.date_range_outlined, size: 16),
            onSelected: (_) => _pickCustomRange(context),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    ReportState state,
    ReportFilterType type,
    String label,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: state.filterType == type,
      onSelected: (_) => context.read<ReportCubit>().setFilter(type),
    );
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  Widget _buildActiveDateLabel(ReportState state, ThemeData theme) {
    final range = state.activeDateRange;
    final String label;
    if (range.start.day == range.end.day &&
        range.start.month == range.end.month &&
        range.start.year == range.end.year) {
      label = _formatDate(range.start);
    } else {
      label = '${_formatDate(range.start)} – ${_formatDate(range.end)}';
    }
    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSummaryCard(ReportState state, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Omzet',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    RupiahFormatter.format(state.summary.totalRevenue),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Transaksi',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.summary.totalTransactions}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    TransactionHistoryItem tx,
    ThemeData theme,
    BuildContext context,
  ) {
    final dateTime = DateTime.tryParse(tx.createdAt)?.toLocal();
    final timeLabel = dateTime != null
        ? DateFormat('dd/MM/yy HH:mm').format(dateTime)
        : tx.createdAt;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptScreen(transactionId: tx.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Ikon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_outlined,
                  size: 20,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${tx.id} · ${tx.cashierName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$timeLabel · ${tx.totalItems} item',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Total
              Text(
                RupiahFormatter.format(tx.total),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

