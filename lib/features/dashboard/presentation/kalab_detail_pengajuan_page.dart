import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class KalabDetailPengajuanPage extends StatefulWidget {
  const KalabDetailPengajuanPage({
    super.key,
    required this.booking,
    required this.repository,
  });

  final Map<String, dynamic> booking;
  final DashboardRepository repository;

  @override
  State<KalabDetailPengajuanPage> createState() =>
      _KalabDetailPengajuanPageState();
}

class _KalabDetailPengajuanPageState extends State<KalabDetailPengajuanPage> {
  final _noteController = TextEditingController();
  late final LabBooking _booking;
  String? _submittingAction;

  @override
  void initState() {
    super.initState();
    _booking = _bookingFromMap(widget.booking);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final date = DateFormat('dd MMMM yyyy').format(booking.tanggalPinjam);
    final startTime = booking.startTime.isNotEmpty
        ? booking.startTime
        : DateFormat.Hm().format(booking.tanggalPinjam);
    final endTime = booking.endTime.isNotEmpty
        ? booking.endTime
        : DateFormat.Hm().format(booking.tanggalKembali);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Final Approval Kalab'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.vibrantPurple.withValues(alpha: 0.14),
              AppTheme.electricBlue.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(booking: booking),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Data Mahasiswa',
                      icon: Icons.school_outlined,
                      children: [
                        _InfoRow('Nama', booking.borrowerName),
                        _InfoRow('NIM', booking.borrowerIdentity ?? '-'),
                      ],
                    ),
                    _SectionCard(
                      title: 'Detail Reservasi',
                      icon: Icons.meeting_room_outlined,
                      children: [
                        _InfoRow('Ruangan', booking.labDisplayName),
                        _InfoRow('Tanggal', date),
                        _InfoRow('Jam Mulai', startTime),
                        _InfoRow('Jam Selesai', endTime),
                        _InfoRow(
                          'Keperluan',
                          booking.purpose.trim().isEmpty
                              ? '-'
                              : booking.purpose.trim(),
                        ),
                      ],
                    ),
                    _SectionCard(
                      title: 'Daftar Barang',
                      icon: Icons.inventory_2_outlined,
                      children: booking.itemsSnapshot.isEmpty
                          ? const [_EmptyText('Tidak ada barang tercatat.')]
                          : booking.itemsSnapshot
                                .map((item) => _ItemRow(item: item))
                                .toList(),
                    ),
                    _SectionCard(
                      title: 'Catatan Aslab',
                      icon: Icons.notes_outlined,
                      children: [
                        Text(
                          booking.aslabNote?.trim().isNotEmpty == true
                              ? booking.aslabNote!.trim()
                              : '-',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    _SectionCard(
                      title: 'Catatan Kalab',
                      icon: Icons.edit_note_rounded,
                      children: [
                        TextField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Tambahkan catatan final bila diperlukan',
                            prefixIcon: Icon(Icons.edit_note_rounded),
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
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submittingAction == null ? _reject : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFE11D48)),
                  ),
                  icon: _submittingAction == 'reject'
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded),
                  label: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CyberGradientButton(
                  onPressed: _submittingAction == null ? _approveFinal : null,
                  borderRadius: 16,
                  child: _submittingAction == 'approve'
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Setujui Final & Potong Stok',
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveFinal() async {
    setState(() => _submittingAction = 'approve');
    try {
      await widget.repository.approveKalab(bookingId: _booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Persetujuan final berhasil, stok telah dipotong',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop('approved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _submittingAction = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectReasonDialog();
    if (reason == null || reason.trim().isEmpty) {
      return;
    }
    setState(() => _submittingAction = 'reject');
    try {
      await widget.repository.rejectKalab(
        bookingId: _booking.id,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengajuan ditolak'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      Navigator.of(context).pop('rejected');
    } catch (error) {
      if (!mounted) return;
      setState(() => _submittingAction = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<String?> _showRejectReasonDialog() {
    final controller = TextEditingController(text: _noteController.text);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText:
                'Tuliskan alasan agar mahasiswa bisa memperbaiki pengajuan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Tolak Pengajuan'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object? error) {
    final message = error?.toString() ?? 'Terjadi kendala.';
    return message.replaceFirst('Exception: ', '').trim();
  }

  LabBooking _bookingFromMap(Map<String, dynamic> source) {
    final map = Map<String, dynamic>.from(source);
    final laboratory = _asMap(map['laboratories']);
    final profile = _asMap(map['peminjam'] ?? map['profiles']);
    if (map['lab_id'] == null && map['ruangan_id'] != null) {
      map['lab_id'] = map['ruangan_id'];
    }
    map['lab_name_snapshot'] ??=
        laboratory['name'] ?? laboratory['nama_lab'] ?? map['lab_name'];
    map['items_snapshot'] ??= map['items'] ?? const [];
    map['borrower_name'] ??= profile['nama'];
    map['reservation_no'] ??= 'Booking ${map['id'] ?? ''}';
    map['qr_token'] ??= '';
    map['whatsapp_number'] ??= '';
    map['faculty_code'] ??= '';
    map['purpose'] ??= '';
    map['tanggal_kembali'] ??= map['tanggal_pinjam'];
    map['created_at'] ??= map['tanggal_pinjam'];
    return LabBooking.fromMap(map);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.campusGradientOf(context),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantPurple.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
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
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.electricBlue),
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final BookingSnapshotItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(item.name),
      trailing: Text(
        'x${item.quantity}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
