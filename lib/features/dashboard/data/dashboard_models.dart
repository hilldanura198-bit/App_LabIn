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
    this.imageUrl,
  });

  final String id;
  final String labId;
  final String namaAlat;
  final int totalStok;
  final int stokTersedia;
  final String kondisi;
  final String type;
  final String? manualUrl;
  final String? imageUrl;

  bool get isAvailable => stokTersedia > 0 && kondisi == 'bagus';
  bool get isCritical => stokTersedia < 3 || kondisi == 'rusak';
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
    final name = map['nama_alat'] as String? ?? 'Alat Lab';
    return LabInventory(
      id: map['id'] as String,
      labId: map['lab_id'] as String,
      namaAlat: name,
      totalStok: map['total_stok'] as int? ?? map['total_stock'] as int? ?? 0,
      stokTersedia:
          map['stok_tersedia'] as int? ?? map['available_stock'] as int? ?? 0,
      kondisi: map['kondisi'] as String? ?? 'bagus',
      type: map['type'] as String? ?? map['jenis'] as String? ?? '',
      manualUrl: map['manual_url'] as String?,
      imageUrl: getLocalAssetPath(name),
    );
  }

  static String getLocalAssetPath(String name) =>
      DashboardModel.getLocalAssetPath(name);
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
    this.inventoryId,
    this.note,
  });

  final String name;
  final int quantity;
  final String labId;
  final String? inventoryId;
  final String? note;

  factory BookingSnapshotItem.fromMap(Map<String, dynamic> map) {
    return BookingSnapshotItem(
      name: map['name'] as String? ?? map['nama'] as String? ?? 'Item',
      quantity: map['quantity'] as int? ?? 1,
      labId: map['lab_id'] as String? ?? '',
      inventoryId:
          map['inventory_id'] as String? ?? map['inventoryId'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'lab_id': labId,
      if (inventoryId != null && inventoryId!.trim().isNotEmpty)
        'inventory_id': inventoryId!.trim(),
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
    this.borrowerProgramStudi,
    this.approvedByKalabName,
    this.approvedByKalabIdentity,
    this.approvedByKalabProgramStudi,
    this.aslabNote,
    this.rejectionReason,
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
  final String? borrowerProgramStudi;
  final String? approvedByKalabName;
  final String? approvedByKalabIdentity;
  final String? approvedByKalabProgramStudi;
  final String? aslabNote;
  final String? rejectionReason;

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
      borrowerName:
          _profileNameFromMap(_peminjamProfile(map)) ??
          map['borrower_name'] as String? ??
          'Mahasiswa',
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
      labNameSnapshot:
          map['lab_name_snapshot'] as String? ??
          _labNameFromMap(map['laboratories']),
      ratingReview: _ratingReviewFromMap(map['rating_review']),
      borrowerIdentity: _profileIdentityFromMap(_peminjamProfile(map)),
      borrowerProgramStudi: _profileProgramStudiFromMap(_peminjamProfile(map)),
      approvedByKalabName: _profileNameFromMap(map['kalab']),
      approvedByKalabIdentity: _profileIdentityFromMap(map['kalab']),
      approvedByKalabProgramStudi: _profileProgramStudiFromMap(map['kalab']),
      aslabNote: map['aslab_note'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
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

  static Object? _peminjamProfile(Map<String, dynamic> map) {
    return map['peminjam'] ?? map['profiles'];
  }

  static String? _profileIdentityFromMap(Object? value) {
    if (value is Map<String, dynamic>) return value['nim_nip'] as String?;
    if (value is Map) return value['nim_nip'] as String?;
    return null;
  }

  static String? _profileNameFromMap(Object? value) {
    if (value is Map<String, dynamic>) return value['nama'] as String?;
    if (value is Map) return value['nama'] as String?;
    return null;
  }

  static String? _profileProgramStudiFromMap(Object? value) {
    if (value is Map<String, dynamic>) return value['program_studi'] as String?;
    if (value is Map) return value['program_studi'] as String?;
    return null;
  }

  static String? _labNameFromMap(Object? value) {
    if (value is Map<String, dynamic>) return value['nama_lab'] as String?;
    if (value is Map) return value['nama_lab'] as String?;
    return null;
  }
}

class LabRoom {
  const LabRoom({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String location;
  final String status;
  final String? imageUrl;

  factory LabRoom.fromMap(Map<String, dynamic> map) {
    final name = map['nama_lab'] as String? ?? 'Ruang Lab';
    return LabRoom(
      id: map['id'] as String,
      name: name,
      location: map['lokasi'] as String? ?? '-',
      status: map['status_operasional'] as String? ?? 'aktif',
      imageUrl: DashboardModel.getLocalAssetPath(name),
    );
  }
}

class DashboardModel {
  const DashboardModel._();

  static const fallbackAssetPath = 'assets/images/labin.jpg';
  static const _localLabRplId = '00000000-0000-0000-0000-000000001101';
  static const _localLabHealthId = '00000000-0000-0000-0000-000000001102';
  static const _localLabNetworkId = '00000000-0000-0000-0000-000000001103';

  static const localFacilityCatalog = <LabInventory>[
    LabInventory(
      id: '00000000-0000-0000-0000-000000000001',
      labId: _localLabNetworkId,
      namaAlat: 'Acces point wifi',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/acces point wifi.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000002',
      labId: _localLabHealthId,
      namaAlat: 'Alat ukur antrometri',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/alat ukur antrometri.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000003',
      labId: _localLabNetworkId,
      namaAlat: 'Arduino ide',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/arduino ide.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000004',
      labId: _localLabNetworkId,
      namaAlat: 'Esp32 development board',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/esp32 development board.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000005',
      labId: _localLabRplId,
      namaAlat: 'Hdmi',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/hdmi.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000006',
      labId: _localLabRplId,
      namaAlat: 'Kamera sidang',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/kamera sidang.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000007',
      labId: _localLabNetworkId,
      namaAlat: 'Lan kabel',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/lan  kabel.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000008',
      labId: _localLabRplId,
      namaAlat: 'Laptop akutansi',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/laptop akutansi.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000009',
      labId: _localLabHealthId,
      namaAlat: 'Manekin cpr',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/manekin cpr.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000010',
      labId: _localLabRplId,
      namaAlat: 'Microphone meeting',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/microphone meeting.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000011',
      labId: _localLabRplId,
      namaAlat: 'Monitor ultrawide',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/monitor ultrawide.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000012',
      labId: _localLabHealthId,
      namaAlat: 'Multimeter digital',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/multimeter digital.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000013',
      labId: _localLabRplId,
      namaAlat: 'Pc',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/pc.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000014',
      labId: _localLabNetworkId,
      namaAlat: 'Pc server',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/pc server.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000015',
      labId: _localLabRplId,
      namaAlat: 'Printer',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/printer.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000016',
      labId: _localLabRplId,
      namaAlat: 'Proyektor',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/proyektor.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000017',
      labId: _localLabNetworkId,
      namaAlat: 'Router cisco',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/router cisco.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000018',
      labId: _localLabRplId,
      namaAlat: 'Scanner dokumen',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/scanner dokumen.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000019',
      labId: _localLabHealthId,
      namaAlat: 'Sensor Ultrasonik',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/sensor ultrasonic.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000020',
      labId: _localLabRplId,
      namaAlat: 'Smart tv',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/smart tv.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000021',
      labId: _localLabNetworkId,
      namaAlat: 'Switch manageable',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/switch manageable.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000022',
      labId: _localLabRplId,
      namaAlat: 'Tablet survey',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/tablet survey.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000023',
      labId: _localLabHealthId,
      namaAlat: 'Tensi meter',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/tensi meter.jpg',
    ),
    LabInventory(
      id: '00000000-0000-0000-0000-000000000024',
      labId: _localLabRplId,
      namaAlat: 'Webcam',
      totalStok: 9,
      stokTersedia: 9,
      kondisi: 'bagus',
      type: 'alat',
      imageUrl: 'assets/images/webcam.jpg',
    ),
  ];

  static List<LabInventory> mergeWithLocalFacilities(
    List<LabInventory> inventories,
  ) {
    final merged = <String, LabInventory>{
      for (final item in localFacilityCatalog) _assetKey(item.namaAlat): item,
    };
    for (final item in inventories) {
      final key = _assetKey(item.namaAlat);
      merged[key] = LabInventory(
        id: item.id,
        labId: item.labId,
        namaAlat: item.namaAlat.capitalize(),
        totalStok: item.totalStok,
        stokTersedia: item.stokTersedia,
        kondisi: item.kondisi,
        type: item.type,
        manualUrl: item.manualUrl,
        imageUrl: getLocalAssetPath(item.namaAlat),
      );
    }
    final result = merged.values.toList()
      ..sort((a, b) => a.namaAlat.compareTo(b.namaAlat));
    return result;
  }

  static String getLocalAssetPath(String name) {
    final normalized = _normalizeAssetName(name);
    return switch (normalized) {
      final value when value.contains('tablet survey') =>
        'assets/images/tablet survey.jpg',
      final value
          when value.contains('sensor ultrasonic') ||
              value.contains('sensor ultrasonik') =>
        'assets/images/sensor ultrasonic.jpg',
      final value
          when value.contains('pc workstation') ||
              value.contains('pc server') =>
        value.contains('server')
            ? 'assets/images/pc server.jpg'
            : 'assets/images/pc.jpg',
      final value when value.contains('pc') => 'assets/images/pc.jpg',
      final value when value.contains('microphone meeting') =>
        'assets/images/microphone meeting.jpg',
      final value when value.contains('webcam') => 'assets/images/webcam.jpg',
      final value when value.contains('switch manageable') =>
        'assets/images/switch manageable.jpg',
      final value
          when value.contains('tensimeter digital') ||
              value.contains('tensi meter') =>
        'assets/images/tensi meter.jpg',
      final value when value.contains('scanner dokumen') =>
        'assets/images/scanner dokumen.jpg',
      final value when value.contains('smart tv') =>
        'assets/images/smart tv.jpg',
      final value when value.contains('router cisco') =>
        'assets/images/router cisco.jpg',
      final value when value.contains('proyektor') =>
        'assets/images/proyektor.jpg',
      final value when value.contains('printer') => 'assets/images/printer.jpg',
      final value
          when value.contains('access point') ||
              value.contains('acces point') =>
        'assets/images/acces point wifi.jpg',
      final value when value.contains('arduino') =>
        'assets/images/arduino ide.jpg',
      final value
          when value.contains('antropometri') || value.contains('antrometri') =>
        'assets/images/alat ukur antrometri.jpg',
      final value when value.contains('esp32') =>
        'assets/images/esp32 development board.jpg',
      final value when value.contains('hdmi') => 'assets/images/hdmi.jpg',
      final value when value.contains('kamera sidang') =>
        'assets/images/kamera sidang.jpg',
      final value when value.contains('multimeter') =>
        'assets/images/multimeter digital.jpg',
      final value
          when value.contains('laptop akuntansi') ||
              value.contains('laptop akutansi') =>
        'assets/images/laptop akutansi.jpg',
      final value when value.contains('manekin') =>
        'assets/images/manekin cpr.jpg',
      final value when value.contains('lan') && value.contains('kabel') =>
        'assets/images/lan  kabel.jpg',
      final value when value.contains('monitor ultrawide') =>
        'assets/images/monitor ultrawide.jpg',
      final value when value.contains('area luar ruangan') =>
        'assets/images/area luar ruangan.jpg',
      final value when value.contains('ruangan rektor') =>
        'assets/images/ruangan rektor.jpg',
      final value when value.contains('simulasi klinik') =>
        'assets/images/lab simulasi klinik.jpg',
      final value
          when value.contains('jaringan komputer') ||
              value.contains('komputer') =>
        'assets/images/lab jaringan komputer.jpg',
      final value when value.contains('mediasi digital') =>
        'assets/images/lab mediasi digital.jpg',
      final value when value.contains('legal tech') =>
        'assets/images/lab legal tech.jpg',
      final value when value.contains('kesehatan masyarakat') =>
        'assets/images/lab kesehatan masyarakat.jpg',
      final value when value.contains('rpl') => 'assets/images/lab rpl.jpg',
      final value when value.contains('iot') => 'assets/images/lab iot.jpg',
      final value
          when value.contains('business analytic') ||
              value.contains('bussines') =>
        'assets/images/lab bussines analytic.jpg',
      final value when value.contains('akuntansi') =>
        'assets/images/lab akuntansi.jpg',
      _ => fallbackAssetPath,
    };
  }

  static String _assetKey(String name) {
    final normalized = _normalizeAssetName(name)
        .replaceAll('ultrasonik', 'ultrasonic')
        .replaceAll('access', 'acces')
        .replaceAll('akuntansi', 'akutansi');
    return normalized;
  }

  static String _normalizeAssetName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

extension LabInStringCasing on String {
  String capitalize() {
    final trimmed = trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

class ProfileSettings {
  const ProfileSettings({
    required this.name,
    required this.nimNip,
    required this.email,
    required this.role,
    required this.whatsappNumber,
    required this.avatarUrl,
    required this.biometricEnabled,
    required this.realtimeNotificationsEnabled,
    required this.notificationSoundEnabled,
    required this.appLanguage,
    required this.locationEnabled,
    required this.deviceSecurityEnabled,
  });

  final String name;
  final String nimNip;
  final String email;
  final String role;
  final String whatsappNumber;
  final String? avatarUrl;
  final bool biometricEnabled;
  final bool realtimeNotificationsEnabled;
  final bool notificationSoundEnabled;
  final String appLanguage;
  final bool locationEnabled;
  final bool deviceSecurityEnabled;

  factory ProfileSettings.fromMap(Map<String, dynamic> map) {
    return ProfileSettings(
      name: map['nama'] as String? ?? '',
      nimNip: map['nim_nip'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'mahasiswa',
      whatsappNumber: map['whatsapp_number'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      biometricEnabled: map['biometric_enabled'] as bool? ?? false,
      realtimeNotificationsEnabled:
          map['realtime_notifications_enabled'] as bool? ?? true,
      notificationSoundEnabled:
          map['notification_sound_enabled'] as bool? ?? true,
      appLanguage: map['app_language'] as String? ?? 'id',
      locationEnabled: map['location_enabled'] as bool? ?? true,
      deviceSecurityEnabled: map['device_security_enabled'] as bool? ?? true,
    );
  }

  ProfileSettings copyWith({
    String? name,
    String? nimNip,
    String? email,
    String? role,
    String? whatsappNumber,
    String? avatarUrl,
    bool? biometricEnabled,
    bool? realtimeNotificationsEnabled,
    bool? notificationSoundEnabled,
    String? appLanguage,
    bool? locationEnabled,
    bool? deviceSecurityEnabled,
  }) {
    return ProfileSettings(
      name: name ?? this.name,
      nimNip: nimNip ?? this.nimNip,
      email: email ?? this.email,
      role: role ?? this.role,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      realtimeNotificationsEnabled:
          realtimeNotificationsEnabled ?? this.realtimeNotificationsEnabled,
      notificationSoundEnabled:
          notificationSoundEnabled ?? this.notificationSoundEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      deviceSecurityEnabled:
          deviceSecurityEnabled ?? this.deviceSecurityEnabled,
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
