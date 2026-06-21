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
    final date = DateFormat('dd MMMM yyyy').format(booking.tanggalPinjam);
    final startTime = booking.startTime.isNotEmpty
        ? booking.startTime
        : DateFormat.Hm().format(booking.tanggalPinjam);
    final endTime = booking.endTime.isNotEmpty
        ? booking.endTime
        : DateFormat.Hm().format(booking.tanggalKembali);

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: const GlassAppBar(title: 'Detail Pengajuan'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.vibrantPurple.withValues(alpha: 0.16),
              AppTheme.electricBlue.withValues(alpha: 0.08),
              AppTheme.offWhite,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<bool>(
            future: _conflictFuture,
            builder: (context, snapshot) {
              final hasConflict = snapshot.data ?? false;
              final checking =
                  snapshot.connectionState == ConnectionState.waiting;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 112),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailHero(booking: booking),
                        const SizedBox(height: 16),
                        _SectionCard(
                          icon: Icons.school_outlined,
                          title: 'Data Mahasiswa',
                          children: [
                            _InfoRow('Nama', booking.borrowerName),
                            _InfoRow('NIM', booking.borrowerIdentity ?? '-'),
                            _InfoRow(
                              'Program Studi',
                              booking.borrowerProgramStudi ??
                                  booking.facultyLabel,
                            ),
                          ],
                        ),
                        _SectionCard(
                          icon: Icons.meeting_room_outlined,
                          title: 'Detail Reservasi',
                          children: [
                            _InfoRow('Nama Ruangan', booking.labDisplayName),
                            _InfoRow('Tanggal', date),
                            _InfoRow('Jam Mulai', startTime),
                            _InfoRow('Jam Selesai', endTime),
                          ],
                        ),
                        _SectionCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Daftar Alat',
                          children: booking.itemsSnapshot.isEmpty
                              ? const [_EmptyItemText()]
                              : booking.itemsSnapshot
                                    .map((item) => _ToolItemRow(item: item))
                                    .toList(),
                        ),
                        _SectionCard(
                          icon: Icons.description_outlined,
                          title: 'Keperluan',
                          children: [
                            Text(
                              booking.purpose.trim().isEmpty
                                  ? '-'
                                  : booking.purpose.trim(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        _SectionCard(
                          icon: Icons.timeline_rounded,
                          title: 'Timeline / Status',
                          children: [StatusTimeline(booking: booking)],
                        ),
                        _SectionCard(
                          icon: Icons.event_busy_outlined,
                          title: 'Pengecekan Konflik Jadwal',
                          children: [
                            _ConflictIndicator(
                              loading: checking,
                              hasConflict: hasConflict,
                            ),
                          ],
                        ),
                        _SectionCard(
                          icon: Icons.notes_rounded,
                          title: 'Catatan Aslab',
                          children: [
                            TextField(
                              controller: _noteController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText:
                                    'Tambahkan catatan approval atau alasan tolak',
                                prefixIcon: Icon(Icons.edit_note_rounded),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Catatan wajib diisi jika pengajuan ditolak.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: FutureBuilder<bool>(
            future: _conflictFuture,
            builder: (context, snapshot) {
              final hasConflict = snapshot.data ?? false;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE11D48),
                        side: const BorderSide(color: Color(0xFFE11D48)),
                      ),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberGradientButton(
                      onPressed: _submitting || hasConflict ? null : _approve,
                      borderRadius: 16,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded),
                                SizedBox(width: 8),
                                Text('Setujui'),
                              ],
                            ),
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

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final itemCount = booking.itemsSnapshot.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.cyberGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantPurple.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.reservationNo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      booking.borrowerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: booking.statusLabel, color: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Ruangan',
                  value: booking.labDisplayName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Barang',
                  value: itemCount == 0 ? '0 item' : '$itemCount item',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.electricBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.electricBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItemRow extends StatelessWidget {
  const _ToolItemRow({required this.item});

  final BookingSnapshotItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.coolMist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.electricBlue.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppTheme.electricBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _StatusBadge(
            label: 'x${item.quantity}',
            color: AppTheme.electricBlue,
          ),
        ],
      ),
    );
  }
}

class _EmptyItemText extends StatelessWidget {
  const _EmptyItemText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tidak ada barang tercatat.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.muted,
        fontWeight: FontWeight.w600,
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
        ? const Color(0xFFE11D48)
        : const Color(0xFF16A34A);
    final icon = hasConflict
        ? Icons.warning_amber_rounded
        : Icons.verified_rounded;
    final title = hasConflict ? 'Konflik jadwal terdeteksi' : 'Aman';
    final message = hasConflict
        ? 'Ruangan dan waktu peminjaman bertabrakan dengan reservasi lain. Tombol setujui dinonaktifkan.'
        : 'Tidak ada bentrok jadwal untuk ruangan dan waktu yang diajukan.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading ? 'Memeriksa konflik jadwal...' : title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  loading
                      ? 'Sistem sedang mengecek bentrok ruangan dan waktu.'
                      : message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onDark = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: onDark ? 0.32 : 0.26),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onDark ? Colors.white : color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
