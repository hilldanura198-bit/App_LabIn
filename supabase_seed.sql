-- LabIN Supabase seed data
-- Run after supabase_schema.sql in the Supabase SQL Editor.

begin;

insert into public.laboratories (id, nama_lab, lokasi, status_operasional)
values
  ('11111111-1111-4111-8111-111111111111', 'Lab RPL', 'Gedung Teknologi Lt. 2', 'aktif'),
  ('22222222-2222-4222-8222-222222222222', 'Lab IoT', 'Gedung Teknologi Lt. 3', 'aktif'),
  ('33333333-3333-4333-8333-333333333333', 'Lab Jaringan', 'Gedung Teknologi Lt. 1', 'aktif')
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
