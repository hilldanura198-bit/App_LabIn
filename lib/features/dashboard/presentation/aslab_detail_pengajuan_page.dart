import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';
import 'widgets/status_timeline.dart';

class AslabDetailPengajuanPage extends StatefulWidget {
  const AslabDetailPengajuanPage({
    super.key,
    required this.booking,
    required this.repository,
  });

  final LabBooking booking;
  final DashboardRepository repository;

  @override
  State<AslabDetailPengajuanPage> createState() =>
      _AslabDetailPengajuanPageState();
}

class _AslabDetailPengajuanPageState extends State<AslabDetailPengajuanPage> {
  final _noteController = TextEditingController();
  late final Future<bool> _conflictFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.booking.aslabNote ?? '';
    _conflictFuture = widget.repository.hasScheduleConflict(widget.booking);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final formatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat.Hm();
    return Scaffold(
      appBar: const GlassAppBar(title: 'Detail Pengajuan'),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _conflictFuture,
          builder: (context, snapshot) {
            final hasConflict = snapshot.data ?? false;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
              children: [
                _SectionCard(
                  title: 'Data Mahasiswa',
                  children: [
                    _InfoRow('Nama', booking.borrowerName),
                    _InfoRow('NIM', booking.borrowerIdentity ?? '-'),
                    _InfoRow(
                      'Program Studi',
                      booking.borrowerProgramStudi ?? booking.facultyLabel,
                    ),
                  ],
                ),
                _SectionCard(
                  title: 'Detail Reservasi',
                  children: [
                    _InfoRow('Ruangan', booking.labDisplayName),
                    _InfoRow(
                      'Tanggal',
                      formatter.format(booking.tanggalPinjam),
                    ),
                    _InfoRow(
                      'Jam Mulai',
                      booking.startTime.isNotEmpty
                          ? booking.startTime
                          : timeFormatter.format(booking.tanggalPinjam),
                    ),
                    _InfoRow(
                      'Jam Selesai',
                      booking.endTime.isNotEmpty
                          ? booking.endTime
                          : timeFormatter.format(booking.tanggalKembali),
                    ),
                  ],
                ),
                _SectionCard(
                  title: 'Daftar Barang',
                  children: booking.itemsSnapshot.isEmpty
                      ? const [Text('Tidak ada barang tercatat.')]
                      : booking.itemsSnapshot
                            .map(
                              (item) => _InfoRow(
                                item.name,
                                'Jumlah ${item.quantity}',
                              ),
                            )
                            .toList(),
                ),
                _SectionCard(
                  title: 'Keperluan Peminjaman',
                  children: [
                    Text(booking.purpose.isEmpty ? '-' : booking.purpose),
                  ],
                ),
                _SectionCard(
                  title: 'Timeline Approval',
                  children: [StatusTimeline(booking: booking)],
                ),
                _SectionCard(
                  title: 'Conflict Checker',
                  children: [
                    _ConflictIndicator(
                      loading:
                          snapshot.connectionState == ConnectionState.waiting,
                      hasConflict: hasConflict,
                    ),
                  ],
                ),
                _SectionCard(
                  title: 'Catatan Aslab',
                  children: [
                    TextField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText:
                            'Tambahkan catatan approval atau alasan tolak',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: FutureBuilder<bool>(
            future: _conflictFuture,
            builder: (context, snapshot) {
              final hasConflict = snapshot.data ?? false;
              return Row(
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
                      onPressed: _submitting || hasConflict ? null : _approve,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Setujui'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _approve() async {
    setState(() => _submitting = true);
    try {
      await widget.repository.approveAslab(
        widget.booking.id,
        note: _noteController.text,
      );
      if (mounted) Navigator.of(context).pop('Pengajuan diteruskan ke Kalab');
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _reject() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan penolakan wajib diisi.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.repository.rejectAslab(
        bookingId: widget.booking.id,
        reason: note,
      );
      if (mounted) Navigator.of(context).pop('Pengajuan ditolak');
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictIndicator extends StatelessWidget {
  const _ConflictIndicator({required this.loading, required this.hasConflict});

  final bool loading;
  final bool hasConflict;

  @override
  Widget build(BuildContext context) {
    final color = hasConflict
        ? const Color(0xFFFF4D6D)
        : const Color(0xFF22F55E);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              hasConflict
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,
              color: color,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loading
                  ? 'Memeriksa bentrok jadwal...'
                  : hasConflict
                  ? 'Bentrok dengan jadwal lain. Approval dinonaktifkan.'
                  : 'Aman, tidak ada bentrok jadwal.',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
