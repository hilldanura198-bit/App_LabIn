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
      '$_bookingColumns,profiles(nama,nim_nip,program_studi),laboratories(nama_lab)';

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
    final rows = await _supabase
        .from('laboratories')
        .select('id,nama_lab,lokasi,status_operasional,image_url')
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
          'nama,nim_nip,email,role,whatsapp_number,avatar_url,biometric_enabled,realtime_notifications_enabled,notification_sound_enabled',
        )
        .eq('id', userId)
        .single();
    final preferences = await _fetchOptionalProfilePreferences(userId);
    return ProfileSettings.fromMap({...row, ...preferences});
  }

  Future<void> updateProfile(ProfileSettings settings) {
    return updateProfileSettings(settings);
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
          'email': settings.email.trim(),
          'whatsapp_number': settings.whatsappNumber.trim(),
          'avatar_url': settings.avatarUrl,
          'biometric_enabled': settings.biometricEnabled,
          'realtime_notifications_enabled':
              settings.realtimeNotificationsEnabled,
          'notification_sound_enabled': settings.notificationSoundEnabled,
        })
        .eq('id', userId);
    await _updateOptionalProfilePreferences(userId, settings);
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
    await _supabase
        .from('bookings')
        .update({
          'status': 'approved_aslab',
          'aslab_note': _optionalTrimmed(note),
          'approved_by_aslab_id': aslabId,
        })
        .eq('id', bookingId)
        .eq('status', 'pending');
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
    return LabBooking.fromMap(booking);
  }

  Future<String> confirmItemHandover(String rawCode) async {
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

    await _supabase
        .from('bookings')
        .update({'status': nextStatus})
        .eq('id', bookingId);
    final returned = nextStatus == 'returned';
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
        throw Exception('Stok inventaris tidak cukup untuk disetujui.');
      }
      final nextStock = currentStock - quantity;
      await _supabase
          .from('inventories')
          .update({'stok_tersedia': nextStock})
          .eq('id', inventoryId);
    }
  }

  Future<Map<String, dynamic>> _fetchOptionalProfilePreferences(
    String userId,
  ) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('app_language,location_enabled,device_security_enabled')
          .eq('id', userId)
          .single();
      return Map<String, dynamic>.from(row);
    } on Object {
      return const {};
    }
  }

  Future<void> _updateOptionalProfilePreferences(
    String userId,
    ProfileSettings settings,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'app_language': settings.appLanguage,
            'location_enabled': settings.locationEnabled,
            'device_security_enabled': settings.deviceSecurityEnabled,
          })
          .eq('id', userId);
    } on Object {
      // Kolom preferensi mungkin belum dimigrasi di database lama.
    }
  }

  bool _shouldDecrementStockOnApproval(String previousStatus) {
    return previousStatus == 'approved_aslab';
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
}
