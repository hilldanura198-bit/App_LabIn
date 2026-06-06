class LabInventory {
  const LabInventory({
    required this.id,
    required this.labId,
    required this.namaAlat,
    required this.totalStok,
    required this.stokTersedia,
    required this.kondisi,
    this.manualUrl,
  });

  final String id;
  final String labId;
  final String namaAlat;
  final int totalStok;
  final int stokTersedia;
  final String kondisi;
  final String? manualUrl;

  bool get isAvailable => stokTersedia > 0 && kondisi == 'bagus';
  bool get isCritical => stokTersedia <= 1 || kondisi == 'rusak';

  factory LabInventory.fromMap(Map<String, dynamic> map) {
    return LabInventory(
      id: map['id'] as String,
      labId: map['lab_id'] as String,
      namaAlat: map['nama_alat'] as String? ?? 'Alat Lab',
      totalStok: map['total_stok'] as int? ?? 0,
      stokTersedia: map['stok_tersedia'] as int? ?? 0,
      kondisi: map['kondisi'] as String? ?? 'bagus',
      manualUrl: map['manual_url'] as String?,
    );
  }
}

class BookingItemDraft {
  const BookingItemDraft({required this.inventory, required this.quantity});

  final LabInventory inventory;
  final int quantity;
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
    this.signatureUrl,
  });

  final String id;
  final String userId;
  final String labId;
  final String status;
  final DateTime tanggalPinjam;
  final DateTime tanggalKembali;
  final String reservationNo;
  final String qrToken;
  final String? signatureUrl;

  factory LabBooking.fromMap(Map<String, dynamic> map) {
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
      signatureUrl: map['signature_url'] as String?,
    );
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
    required this.noWhatsapp,
    required this.biometricEnabled,
    required this.realtimeNotificationsEnabled,
  });

  final String name;
  final String nimNip;
  final String role;
  final String noWhatsapp;
  final bool biometricEnabled;
  final bool realtimeNotificationsEnabled;

  factory ProfileSettings.fromMap(Map<String, dynamic> map) {
    return ProfileSettings(
      name: map['nama'] as String? ?? '',
      nimNip: map['nim_nip'] as String? ?? '',
      role: map['role'] as String? ?? 'mahasiswa',
      noWhatsapp: map['no_whatsapp'] as String? ?? '',
      biometricEnabled: map['biometric_enabled'] as bool? ?? false,
      realtimeNotificationsEnabled:
          map['realtime_notifications_enabled'] as bool? ?? true,
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
