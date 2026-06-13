-- LabIN Supabase seed data
-- Run after supabase_schema.sql in the Supabase SQL Editor.

begin;

insert into public.laboratories (id, nama_lab, lokasi, status_operasional)
values
  ('11111111-1111-4111-8111-111111111111', 'Lab RPL', 'Gedung Teknologi Lt. 2', 'aktif'),
  ('22222222-2222-4222-8222-222222222222', 'Lab IoT', 'Gedung Teknologi Lt. 3', 'aktif'),
  ('33333333-3333-4333-8333-333333333333', 'Lab Jaringan', 'Gedung Teknologi Lt. 1', 'aktif'),
  ('44444444-4444-4444-8444-444444444444', 'Lab Akuntansi Digital', 'Gedung Bisnis Lt. 1', 'aktif'),
  ('55555555-5555-4555-8555-555555555555', 'Lab Business Analytics', 'Gedung Bisnis Lt. 2', 'aktif'),
  ('66666666-6666-4666-8666-666666666666', 'Lab Legal Tech', 'Gedung Hukum Lt. 1', 'aktif'),
  ('77777777-7777-4777-8777-777777777777', 'Lab Mediasi Digital', 'Gedung Hukum Lt. 2', 'aktif'),
  ('88888888-8888-4888-8888-888888888888', 'Lab Simulasi Klinik', 'Gedung Kesehatan Lt. 1', 'aktif'),
  ('99999999-9999-4999-8999-999999999999', 'Lab Kesehatan Masyarakat', 'Gedung Kesehatan Lt. 2', 'aktif')
on conflict (id) do update
set
  nama_lab = excluded.nama_lab,
  lokasi = excluded.lokasi,
  status_operasional = excluded.status_operasional;

insert into public.inventories (
  id,
  lab_id,
  nama_alat,
  total_stok,
  stok_tersedia,
  kondisi,
  manual_url
)
values
  (
    'aaaaaaaa-0001-4001-8001-aaaaaaaa0001',
    '11111111-1111-4111-8111-111111111111',
    'PC Workstation RPL',
    24,
    18,
    'bagus',
    null
  ),
  (
    'aaaaaaaa-0002-4002-8002-aaaaaaaa0002',
    '11111111-1111-4111-8111-111111111111',
    'PC Server Mini',
    4,
    3,
    'bagus',
    null
  ),
  (
    'aaaaaaaa-0003-4003-8003-aaaaaaaa0003',
    '11111111-1111-4111-8111-111111111111',
    'Projector Lab RPL',
    2,
    2,
    'bagus',
    null
  ),
  (
    'aaaaaaaa-0004-4004-8004-aaaaaaaa0004',
    '11111111-1111-4111-8111-111111111111',
    'Kabel HDMI Premium',
    8,
    6,
    'bagus',
    null
  ),
  (
    'bbbbbbbb-0001-4001-8001-bbbbbbbb0001',
    '22222222-2222-4222-8222-222222222222',
    'Arduino Uno Kit',
    16,
    12,
    'bagus',
    null
  ),
  (
    'bbbbbbbb-0002-4002-8002-bbbbbbbb0002',
    '22222222-2222-4222-8222-222222222222',
    'ESP32 Development Board',
    20,
    15,
    'bagus',
    null
  ),
  (
    'bbbbbbbb-0003-4003-8003-bbbbbbbb0003',
    '22222222-2222-4222-8222-222222222222',
    'Sensor Ultrasonik HC-SR04',
    30,
    24,
    'bagus',
    null
  ),
  (
    'bbbbbbbb-0004-4004-8004-bbbbbbbb0004',
    '22222222-2222-4222-8222-222222222222',
    'Multimeter Digital',
    6,
    1,
    'bagus',
    null
  ),
  (
    'cccccccc-0001-4001-8001-cccccccc0001',
    '33333333-3333-4333-8333-333333333333',
    'Router Cisco',
    10,
    8,
    'bagus',
    null
  ),
  (
    'cccccccc-0002-4002-8002-cccccccc0002',
    '33333333-3333-4333-8333-333333333333',
    'Switch Manageable 24 Port',
    8,
    5,
    'bagus',
    null
  ),
  (
    'cccccccc-0003-4003-8003-cccccccc0003',
    '33333333-3333-4333-8333-333333333333',
    'Access Point WiFi 6',
    6,
    4,
    'bagus',
    null
  ),
  (
    'cccccccc-0004-4004-8004-cccccccc0004',
    '33333333-3333-4333-8333-333333333333',
    'LAN Cable Tester',
    5,
    3,
    'bagus',
    null
  ),
  (
    'dddddddd-1001-4101-8101-dddddddd1001',
    '44444444-4444-4444-8444-444444444444',
    'Laptop Akuntansi',
    12,
    10,
    'bagus',
    null
  ),
  (
    'dddddddd-1002-4102-8102-dddddddd1002',
    '44444444-4444-4444-8444-444444444444',
    'Printer Thermal',
    4,
    2,
    'bagus',
    null
  ),
  (
    'eeeeeeee-1001-4101-8101-eeeeeeee1001',
    '55555555-5555-4555-8555-555555555555',
    'Monitor Ultrawide',
    10,
    7,
    'bagus',
    null
  ),
  (
    'eeeeeeee-1002-4102-8102-eeeeeeee1002',
    '55555555-5555-4555-8555-555555555555',
    'Webcam Conference',
    8,
    5,
    'bagus',
    null
  ),
  (
    'ffffffff-1001-4101-8101-ffffffff1001',
    '66666666-6666-4666-8666-666666666666',
    'Scanner Dokumen',
    6,
    4,
    'bagus',
    null
  ),
  (
    'ffffffff-1002-4102-8102-ffffffff1002',
    '66666666-6666-4666-8666-666666666666',
    'Kamera Sidang',
    5,
    3,
    'bagus',
    null
  ),
  (
    '11111111-1001-4101-8101-111111111001',
    '77777777-7777-4777-8777-777777777777',
    'Microphone Meeting',
    12,
    8,
    'bagus',
    null
  ),
  (
    '11111111-1002-4102-8102-111111111002',
    '77777777-7777-4777-8777-777777777777',
    'Smart TV 55',
    3,
    2,
    'bagus',
    null
  ),
  (
    '22222222-1001-4101-8101-222222221001',
    '88888888-8888-4888-8888-888888888888',
    'Manekin CPR',
    4,
    3,
    'bagus',
    null
  ),
  (
    '22222222-1002-4102-8102-222222221002',
    '88888888-8888-4888-8888-888888888888',
    'Tensimeter Digital',
    10,
    6,
    'bagus',
    null
  ),
  (
    '33333333-1001-4101-8101-333333331001',
    '99999999-9999-4999-8999-999999999999',
    'Alat Ukur Antropometri',
    7,
    4,
    'bagus',
    null
  ),
  (
    '33333333-1002-4102-8102-333333331002',
    '99999999-9999-4999-8999-999999999999',
    'Tablet Survey',
    15,
    11,
    'bagus',
    null
  )
on conflict (id) do update
set
  lab_id = excluded.lab_id,
  nama_alat = excluded.nama_alat,
  total_stok = excluded.total_stok,
  stok_tersedia = excluded.stok_tersedia,
  kondisi = excluded.kondisi,
  manual_url = excluded.manual_url;

commit;

begin;

insert into public.satisfaction_surveys (id, periode, kategori, skor)
values
  ('dddddddd-0001-4001-8001-dddddddd0001', 'Semester Ganjil 2025', 'Kebersihan', 88),
  ('dddddddd-0002-4002-8002-dddddddd0002', 'Semester Ganjil 2025', 'Ketersediaan Alat', 82),
  ('dddddddd-0003-4003-8003-dddddddd0003', 'Semester Ganjil 2025', 'Kecepatan Layanan', 78),
  ('dddddddd-0004-4004-8004-dddddddd0004', 'Semester Ganjil 2025', 'Kenyamanan Ruang', 91),
  ('eeeeeeee-0001-4001-8001-eeeeeeee0001', 'Semester Genap 2026', 'Kebersihan', 90),
  ('eeeeeeee-0002-4002-8002-eeeeeeee0002', 'Semester Genap 2026', 'Ketersediaan Alat', 86),
  ('eeeeeeee-0003-4003-8003-eeeeeeee0003', 'Semester Genap 2026', 'Kecepatan Layanan', 84),
  ('eeeeeeee-0004-4004-8004-eeeeeeee0004', 'Semester Genap 2026', 'Kenyamanan Ruang', 93)
on conflict (id) do update
set
  periode = excluded.periode,
  kategori = excluded.kategori,
  skor = excluded.skor;

commit;
