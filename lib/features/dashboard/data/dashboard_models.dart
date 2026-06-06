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
    required this.qrToken,
    this.signatureUrl,
  });

  final String id;
  final String userId;
  final String labId;
  final String status;
  final DateTime tanggalPinjam;
  final DateTime tanggalKembali;
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
      qrToken: map['qr_token'] as String? ?? '',
      signatureUrl: map['signature_url'] as String?,
    );
  }
}

class BusyHour {
  const BusyHour({required this.hour, required this.count});

  final int hour;
  final int count;
}
