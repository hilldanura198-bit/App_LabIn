import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_models.dart';
import 'profile_repository.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient? _client;
  static const _bookingColumns =
      'id,user_id,lab_id,status,tanggal_pinjam,tanggal_kembali,reservation_no,qr_token,signature_url,borrower_name,whatsapp_number,faculty_code,purpose,request_date,start_time,end_time,items_snapshot,other_items,lab_name_snapshot,rating_review,desk_no,created_at,aslab_note,rejection_reason,approved_by_aslab_id,approved_by_kalab_id';
  static const _bookingWithProfileColumns =
      '$_bookingColumns,peminjam:profiles!fk_bookings_profiles(*),kalab:profiles!bookings_approved_by_kalab_id_fkey(*),laboratories(nama_lab)';

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw Exception('Sistem backend belum dikonfigurasi.');
    }
    return client;
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  User? get currentUser => _client?.auth.currentUser;

  SupabaseClient? get client => _client;

  Stream<List<LabInventory>> watchInventories() {
    return _supabase
        .from('inventories')
        .stream(primaryKey: ['id'])
        .order('nama_alat')
        .map((rows) => rows.map(LabInventory.fromMap).toList());
  }

  Stream<List<LabInventory>> watchInventoriesByCampus(
    String campusName,
  ) async* {
    final normalizedCampus = _normalizeCampus(campusName);
    final rooms = await fetchLaboratories();
    final labIds = rooms
        .where((room) {
          final location = _normalizeCampus(room.location);
          final name = _normalizeCampus(room.name);
          return location.contains(normalizedCampus) ||
              name.contains(normalizedCampus);
        })
        .map((room) => room.id)
        .toSet();
    if (labIds.isEmpty) {
      yield* watchInventories();
      return;
    }
    yield* watchInventories().map((items) {
      final filtered = items
          .where((item) => labIds.contains(item.labId))
          .toList();
      return filtered.isEmpty ? items : filtered;
    });
  }

  String _normalizeCampus(String value) {
    return value
        .toLowerCase()
        .replaceAll('rektorat', 'rektor')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Stream<int> watchRoomStockTotal() {
    return watchInventories().map((inventories) {
      final roomInventories = inventories.where((item) => item.isRoomStock);
      if (roomInventories.isNotEmpty) {
        return roomInventories.fold(0, (sum, item) => sum + item.stokTersedia);
      }
      return inventories
          .where((item) => item.isAvailable)
          .map((item) => item.labId)
          .toSet()
          .length;
    });
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

  Stream<List<AppNotification>> watchNotifications() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromMap).toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Stream<List<LabBooking>> watchReservation(String reservationNo) {
    final userId = currentUserId;
    final normalized = reservationNo.trim().toUpperCase();
    if (userId == null || normalized.isEmpty) {
      return Stream.value(const []);
    }
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (rows) => rows
              .where((row) => row['reservation_no'] == normalized)
              .map(LabBooking.fromMap)
              .toList(),
        );
  }

  Future<List<LabRoom>> fetchLaboratories() async {
    List<dynamic> rows;
    try {
      rows = await _supabase
          .from('laboratories')
          .select('id,nama_lab,lokasi,status_operasional,image_url')
          .order('nama_lab');
    } on Object {
      rows = await _supabase
          .from('laboratories')
          .select('id,nama_lab,lokasi,status_operasional,foto_url')
          .order('nama_lab');
    }
    return rows
        .map((row) => LabRoom.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<LabInventory>> searchInventories(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      final rows = await _supabase
          .from('inventories')
          .select()
          .order('nama_alat')
          .limit(20);
      return (rows as List<dynamic>)
          .map((row) => LabInventory.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    }
    final safeQuery = normalized.replaceAll('%', r'\%').replaceAll('_', r'\_');
    List<dynamic> rows;
    try {
      rows = await _supabase
          .from('inventories')
          .select()
          .or(
            'nama_alat.ilike.%$safeQuery%,nama_sarana.ilike.%$safeQuery%,deskripsi.ilike.%$safeQuery%',
          )
          .order('nama_alat')
          .limit(30);
    } catch (_) {
      rows = await _supabase
          .from('inventories')
          .select()
          .ilike('nama_alat', '%$safeQuery%')
          .order('nama_alat')
          .limit(30);
    }
    return rows
        .map((row) => LabInventory.fromMap(Map<String, dynamic>.from(row)))
        .toList();
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

  Stream<List<FeedbackEntry>> watchFeedbackEntries() {
    return _supabase
        .from('feedback')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(FeedbackEntry.fromMap).toList());
  }

  Stream<List<LabBooking>> watchBookingsByStatus(List<String> statuses) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('tanggal_pinjam')
        .asyncMap((rows) async {
          final bookingIds = rows
              .map(LabBooking.fromMap)
              .where((booking) => statuses.contains(booking.status))
              .map((booking) => booking.id)
              .toList();
          if (bookingIds.isEmpty) {
            return const <LabBooking>[];
          }
          final rowsWithProfiles = await _supabase
              .from('bookings')
              .select(_bookingWithProfileColumns)
              .inFilter('id', bookingIds)
              .order('tanggal_pinjam');
          return rowsWithProfiles.map(LabBooking.fromMap).toList();
        });
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

  Future<LabBooking> createBooking({
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<BookingItemDraft> items,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    if (items.isEmpty) {
      throw Exception('Keranjang masih kosong.');
    }

    String? bookingId;
    try {
      final labId = items.first.inventory.labId;
      _validateBookingRange(startDateTime, endDateTime);
      await _ensureNoTimeCollision(
        labId: labId,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );
      final itemsSnapshot = items
          .map(
            (item) => BookingSnapshotItem(
              name: item.inventory.namaAlat,
              quantity: item.quantity,
              labId: item.inventory.labId,
              inventoryId: item.inventory.id,
            ).toMap(),
          )
          .toList();
      final checkout = await _supabase
          .from('bookings')
          .insert({
            'user_id': userId,
            'lab_id': labId,
            'status': 'pending',
            'tanggal_pinjam': startDateTime.toUtc().toIso8601String(),
            'tanggal_kembali': endDateTime.toUtc().toIso8601String(),
            'start_time': DateFormat('HH:mm').format(startDateTime.toLocal()),
            'end_time': DateFormat('HH:mm').format(endDateTime.toLocal()),
            'items_snapshot': itemsSnapshot,
          })
          .select(
            'id,user_id,lab_id,status,tanggal_pinjam,tanggal_kembali,reservation_no,qr_token,signature_url,borrower_name,whatsapp_number,faculty_code,purpose,request_date,start_time,end_time,items_snapshot,other_items,lab_name_snapshot,rating_review,desk_no',
          )
          .single();

      bookingId = checkout['id'] as String;
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
      await _insertNotification(
        userId: userId,
        title: 'Checkout berhasil',
        message:
            'Pengajuan reservasi berhasil terkirim dan menunggu verifikasi lab.',
        kind: 'booking_created',
        targetType: 'booking',
        targetId: bookingId,
      );
      return LabBooking.fromMap(checkout);
    } on Object catch (error) {
      if (bookingId != null) {
        try {
          await _supabase.from('bookings').delete().eq('id', bookingId);
        } on Object catch (rollbackError) {
          throw Exception(
            'Checkout gagal dikirim: $error. Rollback gagal: $rollbackError',
          );
        }
      }
      throw Exception('Checkout gagal dikirim: $error');
    }
  }

  Future<LabBooking> createMultiStepBooking({
    required String borrowerName,
    required String whatsappNumber,
    required String facultyCode,
    required String labId,
    required String labNameSnapshot,
    required DateTime requestDate,
    required DateTime borrowDate,
    required DateTime returnDate,
    required String startTime,
    required String endTime,
    required String purpose,
    required String? deskNo,
    required List<BookingItemDraft> items,
    String? otherItems,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    final startDateTime = _combineDateAndTime(borrowDate, startTime);
    final endDateTime = _combineDateAndTime(returnDate, endTime);
    _validateBookingRange(startDateTime, endDateTime);
    await _ensureNoTimeCollision(
      labId: labId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );
    await _supabase
        .from('profiles')
        .update({'whatsapp_number': whatsappNumber.trim()})
        .eq('id', userId);

    final booking = await _supabase
        .from('bookings')
        .insert({
          'user_id': userId,
          'lab_id': labId,
          'lab_name_snapshot': labNameSnapshot,
          'borrower_name': borrowerName.trim(),
          'whatsapp_number': whatsappNumber.trim(),
          'faculty_code': facultyCode,
          'request_date': DateFormat('yyyy-MM-dd').format(requestDate),
          'purpose': purpose.trim(),
          'start_time': startTime,
          'end_time': endTime,
          'status': 'pending',
          'tanggal_pinjam': startDateTime.toUtc().toIso8601String(),
          'tanggal_kembali': endDateTime.toUtc().toIso8601String(),
          'desk_no': deskNo,
          'items_snapshot': items
              .map(
                (item) => BookingSnapshotItem(
                  name: item.inventory.namaAlat,
                  quantity: item.quantity,
                  labId: item.inventory.labId,
                  inventoryId: item.inventory.id,
                ).toMap(),
              )
              .toList(),
          'other_items': otherItems?.trim(),
        })
        .select(
          'id,user_id,lab_id,status,tanggal_pinjam,tanggal_kembali,reservation_no,qr_token,signature_url,borrower_name,whatsapp_number,faculty_code,purpose,request_date,start_time,end_time,items_snapshot,other_items,lab_name_snapshot,rating_review,desk_no',
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
    await _insertNotification(
      userId: userId,
      title: 'Pengajuan multi-step tersimpan',
      message: 'Reservasi untuk ${labNameSnapshot.trim()} sudah tercatat.',
      kind: 'booking_created',
      targetType: 'booking',
      targetId: booking['id'] as String,
    );
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
    final now = DateTime.now();
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('tanggal_pinjam')
        .map(
          (rows) => rows
              .map(LabBooking.fromMap)
              .where(
                (booking) => booking.tanggalKembali.isAfter(
                  now.subtract(const Duration(days: 30)),
                ),
              )
              .toList(),
        );
  }

  Future<ProfileSettings> fetchProfileSettings() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    final row = await _supabase
        .from('profiles')
        .select(
          'nama,nim_nip,email,role,program_studi,whatsapp_number,avatar_url,app_language',
        )
        .eq('id', userId)
        .maybeSingle();
    if (row != null) {
      return ProfileSettings.fromMap(row);
    }
    final user = currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    return ProfileSettings(
      name: (metadata['nama'] ?? metadata['name'] ?? 'Pengguna').toString(),
      nimNip: (metadata['nim_nip'] ?? metadata['nim'] ?? '-').toString(),
      email: user?.email ?? '',
      role: 'mahasiswa',
      programStudi: (metadata['program_studi'] ?? '').toString(),
      whatsappNumber: (metadata['whatsapp_number'] ?? '').toString(),
      avatarUrl: null,
      appLanguage: 'id',
    );
  }

  Future<void> updateProfile(ProfileSettings settings) {
    return updateProfileSettings(settings);
  }

  Future<void> updateProfileSettings(ProfileSettings settings) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    final payload = {
      'id': userId,
      'nama': settings.name.trim(),
      'nim_nip': settings.nimNip.trim(),
      'email': settings.email.trim(),
      'role': settings.role.trim().isEmpty ? 'mahasiswa' : settings.role,
      'whatsapp_number': settings.whatsappNumber.trim(),
      'avatar_url': settings.avatarUrl,
      'app_language': settings.appLanguage,
    };
    if (settings.programStudi.trim().isNotEmpty) {
      payload['program_studi'] = settings.programStudi.trim();
    }
    await _supabase.from('profiles').upsert(payload);
    await _insertNotification(
      userId: userId,
      title: 'Profil diperbarui',
      message: 'Data profil Anda berhasil disinkronkan.',
      kind: 'profile_update',
      targetType: 'profile',
      targetId: userId,
    );
  }

  Future<String> uploadAvatar(XFile image) async {
    return ProfileRepository(_client).uploadProfilePicture(image);
  }

  Future<String> uploadSarprasImage(XFile image) async {
    final userId = currentUserId ?? 'kalab';
    final extension = image.name.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final path =
        '$userId/sarpras-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final bytes = await image.readAsBytes();
    await _supabase.storage
        .from('sarpras-media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: image.mimeType ?? 'image/$safeExtension',
          ),
        );
    return _supabase.storage.from('sarpras-media').getPublicUrl(path);
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
    await _insertNotification(
      userId: userId,
      title: 'Laporan maintenance terkirim',
      message:
          'Laporan untuk ${inventory.namaAlat} sudah diteruskan ke tim lab.',
      kind: 'maintenance_report',
      targetType: 'maintenance',
      targetId: inventory.id,
    );
  }

  Future<void> approveAslab(String bookingId, {String? note}) async {
    final booking = await _supabase
        .from('bookings')
        .select('user_id,reservation_no,status')
        .eq('id', bookingId)
        .single();
    final previousStatus = booking['status'] as String? ?? 'pending';
    if (previousStatus != 'pending') {
      throw Exception('Pengajuan sudah tidak berstatus pending.');
    }
    final aslabId = currentUserId;
    if (aslabId == null) {
      throw Exception('Sesi Aslab tidak ditemukan. Silakan login ulang.');
    }
    final updated = await _supabase
        .from('bookings')
        .update({
          'status': 'approved_aslab',
          'aslab_note': _optionalTrimmed(note),
          'approved_by_aslab_id': aslabId,
        })
        .eq('id', bookingId)
        .eq('status', 'pending')
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw Exception('Pengajuan sudah tidak berstatus pending.');
    }
    if (_shouldDecrementStockOnApproval(previousStatus)) {
      await _decrementInventoryStockForBooking(bookingId);
    }
    await _insertNotification(
      userId: booking['user_id'] as String,
      title: 'Reservasi disetujui Aslab',
      message:
          'Pengajuan ${booking['reservation_no'] as String? ?? bookingId} sedang menunggu persetujuan Kalab.',
      kind: 'booking_status',
      targetType: 'booking',
      targetId: bookingId,
    );
  }

  Future<void> rejectAslab({
    required String bookingId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Catatan penolakan wajib diisi.');
    }
    final booking = await _supabase
        .from('bookings')
        .select('user_id,reservation_no')
        .eq('id', bookingId)
        .single();
    await _supabase
        .from('bookings')
        .update({
          'status': 'rejected',
          'aslab_note': reason.trim(),
          'rejection_reason': reason.trim(),
        })
        .eq('id', bookingId);
    await _insertNotification(
      userId: booking['user_id'] as String,
      title: 'Reservasi ditolak Aslab',
      message:
          'Pengajuan ${booking['reservation_no'] as String? ?? bookingId} ditolak: ${reason.trim()}',
      kind: 'booking_status',
      targetType: 'booking',
      targetId: bookingId,
    );
  }

  Future<bool> hasScheduleConflict(LabBooking booking) async {
    final rows = await _supabase
        .from('bookings')
        .select('id,start_time,end_time,tanggal_pinjam,tanggal_kembali,status')
        .eq('lab_id', booking.labId)
        .neq('id', booking.id)
        .not('status', 'in', '(rejected,cancelled)')
        .lt('tanggal_pinjam', booking.tanggalKembali.toUtc().toIso8601String())
        .gt('tanggal_kembali', booking.tanggalPinjam.toUtc().toIso8601String());

    return rows.isNotEmpty;
  }

  Future<void> approveKalab({
    required String bookingId,
    Uint8List? signatureBytes,
  }) async {
    final booking = await _supabase
        .from('bookings')
        .select('user_id,reservation_no,status')
        .eq('id', bookingId)
        .single();
    final previousStatus = booking['status'] as String? ?? 'pending';
    if (previousStatus != 'approved_aslab') {
      throw Exception('Pengajuan belum siap untuk persetujuan Kalab.');
    }
    final kalabId = currentUserId;
    if (kalabId == null) {
      throw Exception('Sesi Kalab tidak ditemukan. Silakan login ulang.');
    }

    String? signatureUrl;
    if (signatureBytes != null) {
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
      signatureUrl = _supabase.storage.from('signatures').getPublicUrl(path);
    }

    final payload = {
      'status': 'approved_kalab',
      'approved_by_kalab_id': kalabId,
      'signature_url': ?signatureUrl,
    };
    await _supabase
        .from('bookings')
        .update(payload)
        .eq('id', bookingId)
        .eq('status', 'approved_aslab');
    if (_shouldDecrementStockOnApproval(previousStatus)) {
      await _decrementInventoryStockForBooking(bookingId);
    }
    await _insertNotification(
      userId: booking['user_id'] as String,
      title: 'Reservasi disetujui Kalab',
      message:
          'Pengajuan ${booking['reservation_no'] as String? ?? bookingId} telah disahkan.',
      kind: 'booking_status',
      targetType: 'booking',
      targetId: bookingId,
    );
  }

  Future<void> rejectKalab({
    required String bookingId,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }
    final booking = await _supabase
        .from('bookings')
        .select('user_id,reservation_no,status')
        .eq('id', bookingId)
        .single();
    final previousStatus = booking['status'] as String? ?? 'pending';
    if (previousStatus != 'approved_aslab') {
      throw Exception('Pengajuan sudah tidak menunggu persetujuan Kalab.');
    }

    await _supabase
        .from('bookings')
        .update({'status': 'rejected', 'rejection_reason': trimmedReason})
        .eq('id', bookingId)
        .eq('status', 'approved_aslab');
    await _insertNotification(
      userId: booking['user_id'] as String,
      title: 'Reservasi ditolak Kalab',
      message:
          'Pengajuan ${booking['reservation_no'] as String? ?? bookingId} ditolak: $trimmedReason',
      kind: 'booking_status',
      targetType: 'booking',
      targetId: bookingId,
    );
  }

  Future<void> applyQrValidation(String rawCode) async {
    final bookingId = _bookingIdFromQr(rawCode);
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
    final updatedBooking = await _supabase
        .from('bookings')
        .select('user_id,reservation_no')
        .eq('id', bookingId)
        .single();
    await _insertNotification(
      userId: updatedBooking['user_id'] as String,
      title: 'QR berhasil divalidasi',
      message:
          'Status ${updatedBooking['reservation_no'] as String? ?? bookingId} berubah menjadi $nextStatus.',
      kind: 'booking_status',
      targetType: 'booking',
      targetId: bookingId,
    );
  }

  Future<LabBooking> fetchBookingForQr(String rawCode) async {
    final bookingId = _bookingIdFromQr(rawCode);
    final booking = await _supabase
        .from('bookings')
        .select(_bookingWithProfileColumns)
        .eq('id', bookingId)
        .single();
    final map = Map<String, dynamic>.from(booking);
    final bookingItems = await _fetchBookingItemsSnapshot(bookingId);
    if (bookingItems.isNotEmpty) {
      map['items_snapshot'] = bookingItems.map((item) => item.toMap()).toList();
    }
    return LabBooking.fromMap(map);
  }

  Future<String> confirmItemHandover(
    String rawCode, {
    String returnCondition = 'bagus',
  }) async {
    final bookingId = _bookingIdFromQr(rawCode);
    final booking = await _supabase
        .from('bookings')
        .select('user_id,reservation_no,status')
        .eq('id', bookingId)
        .single();
    final status = booking['status'] as String? ?? 'pending';
    final nextStatus = switch (status) {
      'approved_kalab' => 'active',
      'active' => 'returned',
      _ => null,
    };
    if (nextStatus == null) {
      throw Exception('Status booking belum siap diproses: $status');
    }

    final updated = await _supabase
        .from('bookings')
        .update({'status': nextStatus})
        .eq('id', bookingId)
        .eq('status', status)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw Exception('Status booking sudah berubah. Muat ulang data.');
    }
    final returned = nextStatus == 'returned';
    if (returned) {
      await _incrementInventoryStockForBooking(bookingId);
      if (returnCondition == 'rusak') {
        await _markBookingInventoriesCondition(bookingId, 'rusak');
      }
    }
    await _insertNotification(
      userId: booking['user_id'] as String,
      title: returned ? 'Barang dikembalikan' : 'Barang diserahterimakan',
      message: returned
          ? 'Reservasi ${booking['reservation_no'] as String? ?? bookingId} selesai dan barang sudah dikembalikan.'
          : 'Reservasi ${booking['reservation_no'] as String? ?? bookingId} sudah aktif.',
      kind: 'booking_status',
      targetType: 'booking',
      targetId: bookingId,
    );
    return nextStatus;
  }

  Future<void> markAssetAudited(String barcode) async {
    await _supabase
        .from('inventories')
        .update({'kondisi': 'bagus'})
        .eq('id', barcode);
  }

  Future<void> createInventory({
    required String labId,
    required String name,
    required int totalStock,
    required int availableStock,
    required String type,
    String? manualUrl,
    XFile? image,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Nama inventaris wajib diisi.');
    }
    if (totalStock < 0 || availableStock < 0 || availableStock > totalStock) {
      throw Exception('Jumlah stok tidak valid.');
    }
    final imageUrl = image == null ? null : await uploadSarprasImage(image);
    await _supabase.from('inventories').insert({
      'lab_id': labId,
      'nama_alat': name.trim(),
      'total_stok': totalStock,
      'stok_tersedia': availableStock,
      'kondisi': 'bagus',
      'type': type.trim().isEmpty ? 'alat' : type.trim(),
      'manual_url': _optionalTrimmed(manualUrl),
      'image_url': imageUrl,
    });
    await _appendConsensusLog(
      entityTable: 'inventories',
      entityId: name.trim(),
      command: 'create_inventory',
      payload: {'lab_id': labId, 'type': type, 'total_stok': totalStock},
    );
  }

  Future<void> createLaboratory({
    required String name,
    required String location,
    XFile? image,
  }) async {
    if (name.trim().isEmpty || location.trim().isEmpty) {
      throw Exception('Nama dan lokasi ruangan wajib diisi.');
    }
    final imageUrl = image == null ? null : await uploadSarprasImage(image);
    await _supabase.from('laboratories').insert({
      'nama_lab': name.trim(),
      'lokasi': location.trim(),
      'status_operasional': 'aktif',
      'image_url': imageUrl,
    });
    await _appendConsensusLog(
      entityTable: 'laboratories',
      entityId: name.trim(),
      command: 'create_laboratory',
      payload: {'lokasi': location.trim()},
    );
  }

  Future<List<UserAccountSummary>> fetchUserAccounts() async {
    final rows = await _supabase
        .from('profiles')
        .select('id,nama,nim_nip,email,role')
        .order('role')
        .order('nama');
    return rows.map(UserAccountSummary.fromMap).toList();
  }

  Future<void> verifyAslabAccount(String userId) async {
    await updateUserRole(userId: userId, role: 'aslab');
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    if (!{'mahasiswa', 'aslab', 'kalab'}.contains(role)) {
      throw Exception('Role tidak valid.');
    }
    await _supabase.from('profiles').update({'role': role}).eq('id', userId);
    await _appendConsensusLog(
      entityTable: 'profiles',
      entityId: userId,
      command: 'update_user_role',
      payload: {'role': role},
    );
  }

  Future<void> deleteUserProfile(String userId) async {
    if (userId == currentUserId) {
      throw Exception('Akun aktif tidak dapat dihapus dari panel ini.');
    }
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
    } on PostgrestException catch (error) {
      if (error.code == '23503') {
        throw Exception(
          'User memiliki histori transaksi sehingga tidak dapat dihapus langsung. Ubah role atau arsipkan melalui backend admin.',
        );
      }
      rethrow;
    }
    await _appendConsensusLog(
      entityTable: 'profiles',
      entityId: userId,
      command: 'delete_user_profile',
      payload: const {},
    );
  }

  Future<void> createManagedUser({
    required String name,
    required String identity,
    required String email,
    required String password,
    required String role,
  }) async {
    if (name.trim().isEmpty ||
        identity.trim().isEmpty ||
        email.trim().isEmpty ||
        password.length < 6) {
      throw Exception(
        'Data user belum lengkap atau password kurang dari 6 karakter.',
      );
    }
    if (!{'mahasiswa', 'aslab', 'kalab'}.contains(role)) {
      throw Exception('Role tidak valid.');
    }
    final kalabRefreshToken = _supabase.auth.currentSession?.refreshToken;
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nama': name.trim(), 'nim_nip': identity.trim(), 'role': role},
    );
    final userId = response.user?.id;
    if (userId == null) {
      throw Exception('Auth user belum tersedia setelah pendaftaran.');
    }
    await _supabase.from('profiles').upsert({
      'id': userId,
      'nama': name.trim(),
      'nim_nip': identity.trim(),
      'email': email.trim(),
      'role': role,
    });
    await _appendConsensusLog(
      entityTable: 'profiles',
      entityId: userId,
      command: 'create_managed_user',
      payload: {'role': role},
    );
    final currentUserId = _supabase.auth.currentUser?.id;
    if (kalabRefreshToken != null && currentUserId == userId) {
      await _supabase.auth.setSession(kalabRefreshToken);
    }
  }

  Future<List<BorrowedInventoryReport>> fetchBorrowedInventoryReport() async {
    final rows = await _supabase
        .from('booking_items')
        .select('inventory_id,jumlah,bookings(status),inventories(nama_alat)')
        .inFilter('bookings.status', ['approved_kalab', 'active', 'late']);
    final totals = <String, ({String name, int quantity})>{};
    for (final row in rows) {
      final inventoryId = row['inventory_id']?.toString() ?? '';
      if (inventoryId.isEmpty) continue;
      final inventory = row['inventories'];
      final name = inventory is Map
          ? inventory['nama_alat'] as String? ?? 'Inventaris'
          : 'Inventaris';
      final quantity = row['jumlah'] as int? ?? 0;
      final current = totals[inventoryId];
      totals[inventoryId] = (
        name: current?.name ?? name,
        quantity: (current?.quantity ?? 0) + quantity,
      );
    }
    final report =
        totals.entries
            .map(
              (entry) => BorrowedInventoryReport(
                inventoryId: entry.key,
                name: entry.value.name,
                quantity: entry.value.quantity,
              ),
            )
            .toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return report;
  }

  Stream<List<LabBooking>> watchReturnableBookings() {
    return watchBookingsByStatus(const ['active']);
  }

  Future<void> confirmReturnChecklist({
    required String bookingId,
    required Map<String, int> returnedQuantities,
    required String condition,
  }) async {
    final items = await fetchBookingItemDetails(bookingId);
    for (final item in items) {
      final inventoryId = item.inventoryId;
      if (inventoryId == null || inventoryId.isEmpty) continue;
      final returned = returnedQuantities[inventoryId] ?? 0;
      if (returned != item.quantity) {
        throw Exception('Kuantitas ${item.name} tidak cocok.');
      }
    }
    await confirmItemHandover(bookingId, returnCondition: condition);
    await _appendConsensusLog(
      entityTable: 'bookings',
      entityId: bookingId,
      command: 'confirm_return_checklist',
      payload: {'condition': condition},
    );
  }

  Future<List<DailyBorrowerReport>> fetchDailyBorrowerReport(
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return fetchBorrowerReportForRange(start: start, end: end);
  }

  Future<List<DailyBorrowerReport>> fetchBorrowerReportForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _supabase
        .from('bookings')
        .select(_bookingWithProfileColumns)
        .gte('tanggal_pinjam', start.toUtc().toIso8601String())
        .lt('tanggal_pinjam', end.toUtc().toIso8601String())
        .order('tanggal_pinjam');
    return rows
        .map((row) => DailyBorrowerReport.fromBooking(LabBooking.fromMap(row)))
        .toList();
  }

  Future<void> submitFeedback({
    required int rating,
    required String message,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5.');
    }
    await _supabase.from('feedback').insert({
      'user_id': userId,
      'rating': rating,
      'message': message.trim(),
    });
    await _insertNotification(
      userId: userId,
      title: 'Feedback tersimpan',
      message: 'Terima kasih, masukan Anda sudah tercatat.',
      kind: 'feedback',
      targetType: 'feedback',
      targetId: userId,
    );
  }

  Future<void> submitBookingReview({
    required String bookingId,
    required int rating,
    required String review,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5.');
    }
    final booking = await _supabase
        .from('bookings')
        .select('user_id,status')
        .eq('id', bookingId)
        .single();
    if (booking['user_id'] != userId) {
      throw Exception('Anda tidak memiliki akses ke reservasi ini.');
    }
    if (booking['status'] != 'returned') {
      throw Exception('Rating hanya dapat dikirim setelah peminjaman selesai.');
    }
    await _supabase
        .from('bookings')
        .update({
          'rating_review': {
            'rating': rating,
            'review': review.trim(),
            'submitted_at': DateTime.now().toIso8601String(),
          },
        })
        .eq('id', bookingId);
  }

  Future<void> _decrementInventoryStockForBooking(String bookingId) async {
    final rows = await _supabase
        .from('booking_items')
        .select('inventory_id,jumlah,inventories(stok_tersedia)')
        .eq('booking_id', bookingId);
    for (final row in rows) {
      final inventoryId = row['inventory_id'] as String;
      final quantity = row['jumlah'] as int? ?? 0;
      final inventory = row['inventories'];
      final currentStock = inventory is Map
          ? inventory['stok_tersedia'] as int? ?? 0
          : 0;
      if (quantity > currentStock) {
        throw Exception('Stok inventaris tidak cukup untuk diserahkan.');
      }
      final nextStock = currentStock - quantity;
      await _supabase
          .from('inventories')
          .update({'stok_tersedia': nextStock})
          .eq('id', inventoryId);
    }
  }

  Future<void> _incrementInventoryStockForBooking(String bookingId) async {
    final rows = await _supabase
        .from('booking_items')
        .select('inventory_id,jumlah,inventories(stok_tersedia,total_stok)')
        .eq('booking_id', bookingId);
    for (final row in rows) {
      final inventoryId = row['inventory_id'] as String;
      final quantity = row['jumlah'] as int? ?? 0;
      final inventory = row['inventories'];
      final inventoryMap = inventory is Map
          ? Map<String, dynamic>.from(inventory)
          : const <String, dynamic>{};
      final currentStock = inventoryMap['stok_tersedia'] as int? ?? 0;
      final totalStock = inventoryMap['total_stok'] as int? ?? currentStock;
      final nextStock = (currentStock + quantity).clamp(0, totalStock);
      await _supabase
          .from('inventories')
          .update({'stok_tersedia': nextStock})
          .eq('id', inventoryId);
    }
  }

  Future<void> _markBookingInventoriesCondition(
    String bookingId,
    String condition,
  ) async {
    final rows = await _supabase
        .from('booking_items')
        .select('inventory_id')
        .eq('booking_id', bookingId);
    for (final row in rows) {
      final inventoryId = row['inventory_id']?.toString();
      if (inventoryId == null || inventoryId.isEmpty) continue;
      await _supabase
          .from('inventories')
          .update({'kondisi': condition})
          .eq('id', inventoryId);
    }
  }

  Future<List<BookingSnapshotItem>> _fetchBookingItemsSnapshot(
    String bookingId,
  ) async {
    final rows = await _supabase
        .from('booking_items')
        .select('inventory_id,jumlah,inventories(nama_alat,lab_id)')
        .eq('booking_id', bookingId);
    return rows.map<BookingSnapshotItem>((row) {
      final inventory = row['inventories'];
      final inventoryMap = inventory is Map
          ? Map<String, dynamic>.from(inventory)
          : const <String, dynamic>{};
      return BookingSnapshotItem(
        name: inventoryMap['nama_alat'] as String? ?? 'Item',
        quantity: row['jumlah'] as int? ?? 1,
        labId: inventoryMap['lab_id'] as String? ?? '',
        inventoryId: row['inventory_id']?.toString(),
      );
    }).toList();
  }

  Future<List<BookingItemDetail>> fetchBookingItemDetails(
    String bookingId,
  ) async {
    final rows = await _supabase
        .from('booking_items')
        .select('inventory_id,jumlah,inventories(nama_alat,kondisi,lab_id)')
        .eq('booking_id', bookingId)
        .order('created_at');
    return rows.map<BookingItemDetail>((row) {
      final inventory = row['inventories'];
      final inventoryMap = inventory is Map
          ? Map<String, dynamic>.from(inventory)
          : const <String, dynamic>{};
      return BookingItemDetail(
        name: inventoryMap['nama_alat'] as String? ?? 'Item',
        condition: inventoryMap['kondisi'] as String? ?? 'baik',
        quantity: row['jumlah'] as int? ?? 1,
        labId: inventoryMap['lab_id'] as String? ?? '',
        inventoryId: row['inventory_id']?.toString(),
      );
    }).toList();
  }

  bool _shouldDecrementStockOnApproval(String previousStatus) {
    return previousStatus == 'pending';
  }

  String _bookingIdFromQr(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      throw Exception('QR tidak valid.');
    }
    return trimmed.split('|').first;
  }

  void _validateBookingRange(DateTime startDateTime, DateTime endDateTime) {
    if (!endDateTime.isAfter(startDateTime)) {
      throw Exception('Waktu kembali harus setelah waktu pinjam.');
    }
  }

  Future<void> _ensureNoTimeCollision({
    required String labId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) async {
    final rows = await _supabase
        .from('bookings')
        .select('id,tanggal_pinjam,tanggal_kembali')
        .eq('lab_id', labId)
        .not('status', 'in', '(returned,rejected)')
        .lt('tanggal_pinjam', endDateTime.toUtc().toIso8601String())
        .gt('tanggal_kembali', startDateTime.toUtc().toIso8601String())
        .limit(1);
    if (rows.isNotEmpty) {
      throw Exception('Jadwal bentrok dengan peminjaman lain.');
    }
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts.first);
    final minute = int.parse(parts.last);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String? _optionalTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _insertNotification({
    required String userId,
    required String title,
    required String message,
    required String kind,
    required String targetType,
    required String targetId,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'kind': kind,
      'target_type': targetType,
      'target_id': targetId,
      'is_read': false,
    });
  }

  Future<void> _appendConsensusLog({
    required String entityTable,
    required String entityId,
    required String command,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _supabase.from('raft_replication_log').insert({
        'entity_table': entityTable,
        'entity_id': entityId,
        'command': command,
        'payload': payload,
        'committed': true,
      });
    } on Object {
      // Older databases may not have the consensus audit table yet.
    }
  }
}
