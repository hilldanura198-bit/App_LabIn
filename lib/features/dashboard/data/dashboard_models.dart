import 'package:flutter/material.dart';

class LabInventory {
  const LabInventory({
    required this.id,
    required this.labId,
    required this.namaAlat,
    required this.totalStok,
    required this.stokTersedia,
    required this.kondisi,
    required this.type,
    this.manualUrl,
  });

  final String id;
  final String labId;
  final String namaAlat;
  final int totalStok;
  final int stokTersedia;
  final String kondisi;
  final String type;
  final String? manualUrl;

  bool get isAvailable => stokTersedia > 0 && kondisi == 'bagus';
  bool get isCritical => stokTersedia <= 1 || kondisi == 'rusak';
  bool get isRoomStock {
    final normalizedType = type.toLowerCase();
    final normalizedName = namaAlat.toLowerCase();
    return normalizedType == 'ruangan' ||
        normalizedType == 'room' ||
        normalizedType == 'lab' ||
        normalizedName.contains('ruang') ||
        normalizedName.startsWith('lab ');
  }

  factory LabInventory.fromMap(Map<String, dynamic> map) {
    return LabInventory(
      id: map['id'] as String,
      labId: map['lab_id'] as String,
      namaAlat: map['nama_alat'] as String? ?? 'Alat Lab',
      totalStok: map['total_stok'] as int? ?? map['total_stock'] as int? ?? 0,
      stokTersedia:
          map['stok_tersedia'] as int? ?? map['available_stock'] as int? ?? 0,
      kondisi: map['kondisi'] as String? ?? 'bagus',
      type: map['type'] as String? ?? map['jenis'] as String? ?? '',
      manualUrl: map['manual_url'] as String?,
    );
  }
}

class BookingItemDraft {
  const BookingItemDraft({required this.inventory, required this.quantity});

  final LabInventory inventory;
  final int quantity;
}

class BookingSnapshotItem {
  const BookingSnapshotItem({
    required this.name,
    required this.quantity,
    required this.labId,
    this.note,
  });

  final String name;
  final int quantity;
  final String labId;
  final String? note;

  factory BookingSnapshotItem.fromMap(Map<String, dynamic> map) {
    return BookingSnapshotItem(
      name: map['name'] as String? ?? map['nama'] as String? ?? 'Item',
      quantity: map['quantity'] as int? ?? 1,
      labId: map['lab_id'] as String? ?? '',
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'lab_id': labId,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }
}

class LabBooking {
  const LabBooking({
    required this.id,
    required this.userId,
    required this.labId,
    required this.status,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.reservationNo,
    required this.qrToken,
    required this.borrowerName,
    required this.whatsappNumber,
    required this.facultyCode,
    required this.purpose,
    required this.requestDate,
    required this.startTime,
    required this.endTime,
    required this.itemsSnapshot,
    required this.createdAt,
    this.signatureUrl,
    this.otherItems,
    this.labNameSnapshot,
    this.ratingReview,
    this.borrowerIdentity,
  });

  final String id;
  final String userId;
  final String labId;
  final String status;
  final DateTime tanggalPinjam;
  final DateTime tanggalKembali;
  final String reservationNo;
  final String qrToken;
  final String borrowerName;
  final String whatsappNumber;
  final String facultyCode;
  final String purpose;
  final DateTime? requestDate;
  final String startTime;
  final String endTime;
  final List<BookingSnapshotItem> itemsSnapshot;
  final DateTime createdAt;
  final String? signatureUrl;
  final String? otherItems;
  final String? labNameSnapshot;
  final Map<String, dynamic>? ratingReview;
  final String? borrowerIdentity;

  factory LabBooking.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items_snapshot'];
    final itemsSnapshot = <BookingSnapshotItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          itemsSnapshot.add(BookingSnapshotItem.fromMap(item));
        } else if (item is Map) {
          itemsSnapshot.add(
            BookingSnapshotItem.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return LabBooking(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      labId: map['lab_id'] as String,
      status: map['status'] as String? ?? 'pending',
      tanggalPinjam: DateTime.parse(map['tanggal_pinjam'] as String).toLocal(),
      tanggalKembali: DateTime.parse(
        map['tanggal_kembali'] as String,
      ).toLocal(),
      reservationNo:
          map['reservation_no'] as String? ??
          'PMJ-${map['id'].toString().substring(0, 5).toUpperCase()}',
      qrToken: map['qr_token'] as String? ?? '',
      borrowerName: map['borrower_name'] as String? ?? 'Mahasiswa',
      whatsappNumber: map['whatsapp_number'] as String? ?? '',
      facultyCode: map['faculty_code'] as String? ?? 'FIK',
      purpose: map['purpose'] as String? ?? '',
      requestDate: map['request_date'] == null
          ? null
          : DateTime.parse(map['request_date'] as String).toLocal(),
      startTime: map['start_time'] as String? ?? '',
      endTime: map['end_time'] as String? ?? '',
      itemsSnapshot: itemsSnapshot,
      createdAt: map['created_at'] == null
          ? DateTime.parse(map['tanggal_pinjam'] as String).toLocal()
          : DateTime.parse(map['created_at'] as String).toLocal(),
      signatureUrl: map['signature_url'] as String?,
      otherItems: map['other_items'] as String?,
      labNameSnapshot: map['lab_name_snapshot'] as String?,
      ratingReview: _ratingReviewFromMap(map['rating_review']),
      borrowerIdentity: _borrowerIdentityFromMap(map['profiles']),
    );
  }

  String get labDisplayName => labNameSnapshot ?? labId;
  String get facultyLabel {
    return switch (facultyCode) {
      'FIK' => 'FIK',
      'FEB' => 'FEB',
      'FH' => 'FH',
      'FK' => 'FK',
      _ => facultyCode,
    };
  }

  String get statusLabel {
    return switch (status) {
      'pending' => 'Pending',
      'approved_aslab' || 'approved_kalab' => 'Approved',
      'active' => 'Active',
      'rejected' => 'Ditolak',
      'returned' => 'Selesai',
      'late' => 'Terlambat',
      _ => status,
    };
  }

  Color get statusColor {
    return switch (status) {
      'approved_aslab' ||
      'approved_kalab' ||
      'active' => const Color(0xFF22F55E),
      'rejected' => const Color(0xFFFF4D6D),
      'late' => const Color(0xFFFFC53D),
      _ => const Color(0xFFFFB020),
    };
  }

  List<String> get itemNames =>
      itemsSnapshot.map((item) => '${item.name} x${item.quantity}').toList();

  int? get ratingValue {
    final value = ratingReview?['rating'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  String get reviewMessage => (ratingReview?['review'] as String? ?? '').trim();

  static Map<String, dynamic>? _ratingReviewFromMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _borrowerIdentityFromMap(Object? value) {
    if (value is Map<String, dynamic>) return value['nim_nip'] as String?;
    if (value is Map) return value['nim_nip'] as String?;
    return null;
  }
}

class LabRoom {
  const LabRoom({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
  });

  final String id;
  final String name;
  final String location;
  final String status;

  factory LabRoom.fromMap(Map<String, dynamic> map) {
    return LabRoom(
      id: map['id'] as String,
      name: map['nama_lab'] as String? ?? 'Ruang Lab',
      location: map['lokasi'] as String? ?? '-',
      status: map['status_operasional'] as String? ?? 'aktif',
    );
  }
}

class ProfileSettings {
  const ProfileSettings({
    required this.name,
    required this.nimNip,
    required this.role,
    required this.whatsappNumber,
    required this.avatarUrl,
    required this.biometricEnabled,
    required this.realtimeNotificationsEnabled,
    required this.notificationSoundEnabled,
  });

  final String name;
  final String nimNip;
  final String role;
  final String whatsappNumber;
  final String? avatarUrl;
  final bool biometricEnabled;
  final bool realtimeNotificationsEnabled;
  final bool notificationSoundEnabled;

  factory ProfileSettings.fromMap(Map<String, dynamic> map) {
    return ProfileSettings(
      name: map['nama'] as String? ?? '',
      nimNip: map['nim_nip'] as String? ?? '',
      role: map['role'] as String? ?? 'mahasiswa',
      whatsappNumber: map['whatsapp_number'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      biometricEnabled: map['biometric_enabled'] as bool? ?? false,
      realtimeNotificationsEnabled:
          map['realtime_notifications_enabled'] as bool? ?? true,
      notificationSoundEnabled:
          map['notification_sound_enabled'] as bool? ?? true,
    );
  }
}

class BusyHour {
  const BusyHour({required this.hour, required this.count});

  final int hour;
  final int count;
}

class SatisfactionScore {
  const SatisfactionScore({
    required this.id,
    required this.period,
    required this.category,
    required this.score,
  });

  final String id;
  final String period;
  final String category;
  final int score;

  factory SatisfactionScore.fromMap(Map<String, dynamic> map) {
    return SatisfactionScore(
      id: map['id'] as String,
      period: map['periode'] as String? ?? 'Periode',
      category: map['kategori'] as String? ?? 'Layanan',
      score: map['skor'] as int? ?? 0,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.kind,
    required this.targetType,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String kind;
  final String targetType;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? 'Notifikasi',
      message: map['message'] as String? ?? '',
      kind: map['kind'] as String? ?? 'general',
      targetType: map['target_type'] as String? ?? 'booking',
      targetId: map['target_id'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.rating,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int rating;
  final String message;
  final DateTime createdAt;

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    return FeedbackEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      rating: map['rating'] as int? ?? 0,
      message: map['message'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
