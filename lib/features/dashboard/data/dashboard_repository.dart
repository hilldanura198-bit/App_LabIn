import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase belum dikonfigurasi.');
    }
    return client;
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  Stream<List<LabInventory>> watchInventories() {
    return _supabase
        .from('inventories')
        .stream(primaryKey: ['id'])
        .order('nama_alat')
        .map((rows) => rows.map(LabInventory.fromMap).toList());
  }

  Stream<List<LabBooking>> watchCurrentUserBookings() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('tanggal_pinjam', ascending: false)
        .map((rows) => rows.map(LabBooking.fromMap).toList());
  }

  Stream<List<LabBooking>> watchReservation(String reservationNo) {
    final normalized = reservationNo.trim().toUpperCase();
    if (normalized.isEmpty) {
      return Stream.value(const []);
    }
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('reservation_no', normalized)
        .map((rows) => rows.map(LabBooking.fromMap).toList());
  }

  Future<List<LabRoom>> fetchLaboratories() async {
    final rows = await _supabase
        .from('laboratories')
        .select('id,nama_lab,lokasi,status_operasional')
        .order('nama_lab');
    return rows.map(LabRoom.fromMap).toList();
  }

  Stream<List<LabRoom>> watchLaboratories() {
    return _supabase
        .from('laboratories')
        .stream(primaryKey: ['id'])
        .order('nama_lab')
        .map((rows) => rows.map(LabRoom.fromMap).toList());
  }

  Stream<List<SatisfactionScore>> watchSatisfactionScores() {
    return _supabase
        .from('satisfaction_surveys')
        .stream(primaryKey: ['id'])
        .order('kategori')
        .map((rows) => rows.map(SatisfactionScore.fromMap).toList());
  }

  Stream<List<LabBooking>> watchBookingsByStatus(List<String> statuses) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('tanggal_pinjam')
        .map(
          (rows) => rows
              .map(LabBooking.fromMap)
              .where((booking) => statuses.contains(booking.status))
              .toList(),
        );
  }

  Future<List<BusyHour>> fetchBusyHours() async {
    final rows = await _supabase
        .from('bookings')
        .select('tanggal_pinjam')
        .gte(
          'tanggal_pinjam',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        );

    final counts = <int, int>{};
    for (final row in rows) {
      final date = DateTime.parse(row['tanggal_pinjam'] as String).toLocal();
      counts[date.hour] = (counts[date.hour] ?? 0) + 1;
    }

    final busyHours =
        counts.entries
            .map((entry) => BusyHour(hour: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return busyHours.take(5).toList();
  }

  Future<void> createBooking({
    required DateTime tanggalPinjam,
    required List<BookingItemDraft> items,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    if (items.isEmpty) {
      throw Exception('Keranjang masih kosong.');
    }

    final labId = items.first.inventory.labId;
    final checkout = await _supabase
        .from('bookings')
        .insert({
          'user_id': userId,
          'lab_id': labId,
          'status': 'pending',
          'tanggal_pinjam': tanggalPinjam.toIso8601String(),
          'tanggal_kembali': tanggalPinjam
              .add(const Duration(hours: 3))
              .toIso8601String(),
        })
        .select('id')
        .single();

    final bookingId = checkout['id'] as String;
    await _supabase
        .from('booking_items')
        .insert(
          items
              .map(
                (item) => {
                  'booking_id': bookingId,
                  'inventory_id': item.inventory.id,
                  'jumlah': item.quantity,
                },
              )
              .toList(),
        );
  }

  Future<LabBooking> createMultiStepBooking({
    required String labId,
    required String noWhatsapp,
    required DateTime tanggalPinjam,
    required DateTime tanggalKembali,
    required String? deskNo,
    required List<BookingItemDraft> items,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    await _supabase
        .from('profiles')
        .update({'no_whatsapp': noWhatsapp.trim()})
        .eq('id', userId);

    final booking = await _supabase
        .from('bookings')
        .insert({
          'user_id': userId,
          'lab_id': labId,
          'status': 'pending',
          'tanggal_pinjam': tanggalPinjam.toIso8601String(),
          'tanggal_kembali': tanggalKembali.toIso8601String(),
          'desk_no': deskNo,
        })
        .select(
          'id,user_id,lab_id,status,tanggal_pinjam,tanggal_kembali,reservation_no,qr_token,signature_url',
        )
        .single();

    if (items.isNotEmpty) {
      final bookingId = booking['id'] as String;
      await _supabase
          .from('booking_items')
          .insert(
            items
                .map(
                  (item) => {
                    'booking_id': bookingId,
                    'inventory_id': item.inventory.id,
                    'jumlah': item.quantity,
                  },
                )
                .toList(),
          );
    }
    return LabBooking.fromMap(booking);
  }

  Stream<List<LabBooking>> watchApprovedDocuments() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('tanggal_pinjam', ascending: false)
        .map(
          (rows) => rows
              .map(LabBooking.fromMap)
              .where((booking) => booking.status == 'approved_kalab')
              .toList(),
        );
  }

  Stream<List<LabBooking>> watchRoomSchedule() {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('tanggal_pinjam')
        .map((rows) => rows.map(LabBooking.fromMap).toList());
  }

  Future<ProfileSettings> fetchProfileSettings() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    final row = await _supabase
        .from('profiles')
        .select(
          'nama,nim_nip,role,no_whatsapp,avatar_url,biometric_enabled,realtime_notifications_enabled,notification_sound_enabled',
        )
        .eq('id', userId)
        .single();
    return ProfileSettings.fromMap(row);
  }

  Future<void> updateProfileSettings(ProfileSettings settings) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    await _supabase
        .from('profiles')
        .update({
          'nama': settings.name.trim(),
          'nim_nip': settings.nimNip.trim(),
          'no_whatsapp': settings.noWhatsapp.trim(),
          'avatar_url': settings.avatarUrl,
          'biometric_enabled': settings.biometricEnabled,
          'realtime_notifications_enabled':
              settings.realtimeNotificationsEnabled,
          'notification_sound_enabled': settings.notificationSoundEnabled,
        })
        .eq('id', userId);
  }

  Future<String> uploadAvatar(XFile image) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final path =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: image.mimeType ?? 'image/$safeExtension',
          ),
        );
    final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
    return avatarUrl;
  }

  Future<void> updatePassword(String password) async {
    if (password.trim().length < 6) {
      throw Exception('Password minimal 6 karakter.');
    }
    await _supabase.auth.updateUser(UserAttributes(password: password.trim()));
  }

  Future<void> reportMaintenance({
    required LabInventory inventory,
    required String description,
    required XFile photo,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    final bytes = await photo.readAsBytes();
    final extension = photo.name.split('.').last.toLowerCase();
    final path =
        '$userId/reports/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _supabase.storage
        .from('maintenance-reports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: photo.mimeType ?? 'image/$extension',
          ),
        );
    final photoUrl = _supabase.storage
        .from('maintenance-reports')
        .getPublicUrl(path);

    await _supabase.from('maintenance_reports').insert({
      'user_id': userId,
      'inventory_id': inventory.id,
      'deskripsi': description.trim(),
      'foto_url': photoUrl,
      'status_perbaikan': 'diterima',
    });
  }

  Future<void> approveAslab(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'approved_aslab'})
        .eq('id', bookingId);
  }

  Future<void> approveKalab({
    required String bookingId,
    required Uint8List signatureBytes,
  }) async {
    final path =
        'kalab/$bookingId-${DateTime.now().millisecondsSinceEpoch}.png';
    await _supabase.storage
        .from('signatures')
        .uploadBinary(
          path,
          signatureBytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );
    final signatureUrl = _supabase.storage
        .from('signatures')
        .getPublicUrl(path);

    await _supabase
        .from('bookings')
        .update({'status': 'approved_kalab', 'signature_url': signatureUrl})
        .eq('id', bookingId);
  }

  Future<void> applyQrValidation(String rawCode) async {
    final parts = rawCode.split('|');
    if (parts.length < 2) {
      throw Exception('QR tidak valid.');
    }

    final bookingId = parts.first;
    final booking = await _supabase
        .from('bookings')
        .select('status')
        .eq('id', bookingId)
        .single();
    final status = booking['status'] as String? ?? 'pending';
    final nextStatus = status == 'approved_kalab'
        ? 'active'
        : status == 'active'
        ? 'returned'
        : null;
    if (nextStatus == null) {
      throw Exception('Status booking belum siap divalidasi: $status');
    }

    await _supabase
        .from('bookings')
        .update({'status': nextStatus})
        .eq('id', bookingId);
  }

  Future<void> markAssetAudited(String barcode) async {
    await _supabase
        .from('inventories')
        .update({'kondisi': 'bagus'})
        .eq('id', barcode);
  }
}
