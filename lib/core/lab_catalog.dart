class FacultyCatalog {
  const FacultyCatalog({required this.code, required this.name});

  final String code;
  final String name;
}

class LabCatalog {
  const LabCatalog({
    required this.id,
    required this.name,
    required this.facultyCode,
    required this.location,
    required this.description,
  });

  final String id;
  final String name;
  final String facultyCode;
  final String location;
  final String description;
}

class AppLabCatalog {
  const AppLabCatalog._();

  static const faculties = [
    FacultyCatalog(code: 'FIK', name: 'Fakultas Ilmu Komputer'),
    FacultyCatalog(code: 'FEB', name: 'Fakultas Ekonomi dan Bisnis'),
    FacultyCatalog(code: 'FH', name: 'Fakultas Hukum'),
    FacultyCatalog(code: 'FK', name: 'Fakultas Kesehatan'),
  ];

  static const labs = [
    LabCatalog(
      id: 'fik-rpl',
      name: 'Lab RPL',
      facultyCode: 'FIK',
      location: 'Gedung Teknologi Lt. 2',
      description: 'Rekayasa perangkat lunak dan pengembangan aplikasi.',
    ),
    LabCatalog(
      id: 'fik-iot',
      name: 'Lab IoT',
      facultyCode: 'FIK',
      location: 'Gedung Teknologi Lt. 3',
      description: 'Perangkat embedded, sensor, dan konektivitas cerdas.',
    ),
    LabCatalog(
      id: 'feb-akuntansi',
      name: 'Lab Akuntansi Digital',
      facultyCode: 'FEB',
      location: 'Gedung Bisnis Lt. 1',
      description: 'Sistem keuangan, kasir, dan simulasi akuntansi digital.',
    ),
    LabCatalog(
      id: 'feb-analytics',
      name: 'Lab Business Analytics',
      facultyCode: 'FEB',
      location: 'Gedung Bisnis Lt. 2',
      description: 'Analitik data, dashboard bisnis, dan pelaporan manajerial.',
    ),
    LabCatalog(
      id: 'fh-legaltech',
      name: 'Lab Legal Tech',
      facultyCode: 'FH',
      location: 'Gedung Hukum Lt. 1',
      description: 'Kajian hukum digital, dokumentasi, dan simulasi peradilan.',
    ),
    LabCatalog(
      id: 'fh-mediasi',
      name: 'Lab Mediasi Digital',
      facultyCode: 'FH',
      location: 'Gedung Hukum Lt. 2',
      description: 'Pembelajaran mediasi, negosiasi, dan persidangan virtual.',
    ),
    LabCatalog(
      id: 'fk-simulasi',
      name: 'Lab Simulasi Klinik',
      facultyCode: 'FK',
      location: 'Gedung Kesehatan Lt. 1',
      description: 'Simulasi tindakan klinis dan peralatan kesehatan dasar.',
    ),
    LabCatalog(
      id: 'fk-kesehatan',
      name: 'Lab Kesehatan Masyarakat',
      facultyCode: 'FK',
      location: 'Gedung Kesehatan Lt. 2',
      description: 'Praktikum kesehatan masyarakat dan observasi lapangan.',
    ),
  ];

  static LabCatalog? labById(String id) {
    for (final lab in labs) {
      if (lab.id == id) {
        return lab;
      }
    }
    return null;
  }

  static List<LabCatalog> labsForFaculty(String facultyCode) {
    return labs.where((lab) => lab.facultyCode == facultyCode).toList();
  }

  static FacultyCatalog? facultyByCode(String code) {
    for (final faculty in faculties) {
      if (faculty.code == code) {
        return faculty;
      }
    }
    return null;
  }
}
