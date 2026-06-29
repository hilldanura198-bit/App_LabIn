import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class AslabDetailPengajuanPage extends StatefulWidget {
  const AslabDetailPengajuanPage({
    super.key,
    required this.booking,
    required this.repository,
  });

  final Map<String, dynamic> booking;
  final DashboardRepository repository;

  @override
  State<AslabDetailPengajuanPage> createState() =>
      _AslabDetailPengajuanPageState();
}

class _AslabDetailPengajuanPageState extends State<AslabDetailPengajuanPage> {
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borrower = _asMap(widget.booking['peminjam']);
    final lab = _asMap(widget.booking['laboratories']);
    final items = _items(widget.booking);
    return Scaffold(
      appBar: const GlassAppBar(title: 'Detail Pengajuan Aslab'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _firstNotEmpty([
                            borrower['nama'],
                            widget.booking['borrower_name'],
                            'Mahasiswa',
                          ]),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_firstNotEmpty([borrower['nim_nip'], '-'])} | ${_firstNotEmpty([lab['nama_lab'], widget.booking['lab_name_snapshot'], '-'])}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Barang',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          const Text('Tidak ada barang tercatat.')
                        else
                          ...items.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(item.$1),
                              trailing: Text(
                                'x${item.$2}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Aslab',
                            hintText:
                                'Opsional untuk approval, wajib untuk penolakan',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _submitting ? null : _reject,
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _submitting ? null : _approve,
                                icon: _submitting
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: const Text('Verifikasi'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve() async {
    await _run(() {
      return widget.repository.approveAslab(
        widget.booking['id'] as String,
        note: _noteController.text,
      );
    });
  }

  Future<void> _reject() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan penolakan wajib diisi.')),
      );
      return;
    }
    await _run(() {
      return widget.repository.rejectAslab(
        bookingId: widget.booking['id'] as String,
        reason: _noteController.text,
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      setState(() => _submitting = true);
      await action();
      if (!mounted) return;
      Navigator.of(context).pop('updated');
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<(String, int)> _items(Map<String, dynamic> booking) {
    final raw = booking['items_snapshot'] ?? booking['items'];
    if (raw is! List) return const [];
    return raw.map<(String, int)>((item) {
      final map = item is Map ? Map<String, dynamic>.from(item) : const {};
      return (
        map['name']?.toString() ?? map['nama']?.toString() ?? 'Item',
        map['quantity'] as int? ?? map['jumlah'] as int? ?? 1,
      );
    }).toList();
  }

  static String _firstNotEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '-';
  }
}
