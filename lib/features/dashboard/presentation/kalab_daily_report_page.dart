import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'download_docs_saver.dart';
import 'widgets/glass_app_bar.dart';

class KalabDailyReportPage extends StatefulWidget {
  const KalabDailyReportPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<KalabDailyReportPage> createState() => _KalabDailyReportPageState();
}

class _KalabDailyReportPageState extends State<KalabDailyReportPage> {
  DateTime _selectedDate = DateTime.now();
  _ReportPeriod _period = _ReportPeriod.daily;
  late Future<List<DailyBorrowerReport>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final range = _period.rangeFor(_selectedDate);
    _reportFuture = widget.repository.fetchBorrowerReportForRange(
      start: range.start,
      end: range.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Laporan Peminjaman'),
      body: SafeArea(
        child: FutureBuilder<List<DailyBorrowerReport>>(
          future: _reportFuture,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <DailyBorrowerReport>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DateFilterCard(
                          selectedDate: _selectedDate,
                          period: _period,
                          totalBorrowers: rows.length,
                          totalItems: rows.fold(
                            0,
                            (sum, row) => sum + row.totalQuantity,
                          ),
                          onPick: _pickDate,
                          onPeriodChanged: (period) {
                            setState(() {
                              _period = period;
                              _load();
                            });
                          },
                          onExport: rows.isEmpty
                              ? null
                              : () => _exportRows(rows),
                        ),
                        const SizedBox(height: 16),
                        if (!snapshot.hasData)
                          const Center(child: CircularProgressIndicator())
                        else if (rows.isEmpty)
                          const _EmptyDailyReport()
                        else
                          ...rows.map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DailyReportCard(row: row),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _load();
    });
  }

  Future<void> _exportRows(List<DailyBorrowerReport> rows) async {
    final range = _period.rangeFor(_selectedDate);
    final buffer = StringBuffer(
      'reservation_no,borrower,identity,lab,status,total_items,borrowed_at,items\n',
    );
    for (final row in rows) {
      final items = row.items
          .map((item) => '${item.name} x${item.quantity}')
          .join('; ');
      buffer.writeln(
        [
          row.reservationNo,
          row.borrowerName,
          row.identity,
          row.labName,
          row.status,
          row.totalQuantity.toString(),
          DateFormat('yyyy-MM-dd HH:mm').format(row.borrowedAt),
          items,
        ].map(_csvCell).join(','),
      );
    }
    final filename =
        'laporan-peminjaman-${_period.name}-${DateFormat('yyyyMMdd').format(range.start)}.csv';
    final path = await savePdfBytesToDevice(
      Uint8List.fromList(utf8.encode(buffer.toString())),
      filename,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Laporan tersimpan di $path')));
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

class _DateFilterCard extends StatelessWidget {
  const _DateFilterCard({
    required this.selectedDate,
    required this.period,
    required this.totalBorrowers,
    required this.totalItems,
    required this.onPick,
    required this.onPeriodChanged,
    required this.onExport,
  });

  final DateTime selectedDate;
  final _ReportPeriod period;
  final int totalBorrowers;
  final int totalItems;
  final VoidCallback onPick;
  final ValueChanged<_ReportPeriod> onPeriodChanged;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_ReportPeriod>(
              segments: _ReportPeriod.values
                  .map(
                    (item) => ButtonSegment<_ReportPeriod>(
                      value: item,
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
              selected: {period},
              onSelectionChanged: (selected) => onPeriodChanged(selected.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.displayRange(selectedDate),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '$totalBorrowers peminjam | $totalItems item',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pilih tanggal acuan',
                  onPressed: onPick,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
                IconButton(
                  tooltip: 'Ekspor CSV',
                  onPressed: onExport,
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReportPeriod {
  daily('Harian'),
  weekly('Mingguan'),
  monthly('Bulanan'),
  semester('Semesteran');

  const _ReportPeriod(this.label);

  final String label;

  ({DateTime start, DateTime end}) rangeFor(DateTime date) {
    return switch (this) {
      _ReportPeriod.daily => (
        start: DateTime(date.year, date.month, date.day),
        end: DateTime(date.year, date.month, date.day + 1),
      ),
      _ReportPeriod.weekly => _weekRange(date),
      _ReportPeriod.monthly => (
        start: DateTime(date.year, date.month),
        end: DateTime(date.year, date.month + 1),
      ),
      _ReportPeriod.semester => _semesterRange(date),
    };
  }

  String displayRange(DateTime date) {
    final range = rangeFor(date);
    final endInclusive = range.end.subtract(const Duration(days: 1));
    final formatter = DateFormat('dd MMM yyyy');
    if (this == _ReportPeriod.daily) {
      return formatter.format(range.start);
    }
    return '${formatter.format(range.start)} - ${formatter.format(endInclusive)}';
  }

  static ({DateTime start, DateTime end}) _weekRange(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    return (start: start, end: start.add(const Duration(days: 7)));
  }

  static ({DateTime start, DateTime end}) _semesterRange(DateTime date) {
    final startMonth = date.month <= 6 ? 1 : 7;
    final start = DateTime(date.year, startMonth);
    return (start: start, end: DateTime(date.year, startMonth + 6));
  }
}

class _DailyReportCard extends StatelessWidget {
  const _DailyReportCard({required this.row});

  final DailyBorrowerReport row;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.borrowerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(label: Text(row.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${row.identity} | ${row.reservationNo} | ${row.labName}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 10),
            ...row.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 17),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.name)),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDailyReport extends StatelessWidget {
  const _EmptyDailyReport();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 44),
            const SizedBox(height: 10),
            Text(
              'Tidak ada peminjaman pada tanggal ini.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
