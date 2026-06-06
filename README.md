# LabIN

LabIN adalah aplikasi Flutter untuk pengelolaan aktivitas laboratorium: autentikasi multi-role, peminjaman alat, validasi QR, approval bertahap, laporan kerusakan, dan audit inventaris berbasis Supabase.

## Arsitektur

Project ini memakai pendekatan feature-first Clean Architecture ringan:

- `lib/core`: konfigurasi global, credentials, dan theme.
- `lib/features/auth`: BLoC autentikasi, repository Supabase Auth, login, register, biometric login.
- `lib/features/dashboard`: model data, repository Supabase, BLoC dashboard, dan halaman multi-role.
- `lib/features/dashboard/presentation/widgets`: komponen reusable seperti QR scanner, signature pad, timeline, dan busy meter.

Alur state management dipisahkan dengan BLoC:

- `AuthBloc`: login, register mahasiswa, biometric login, lookup role dari tabel `profiles`.
- `DashboardBloc`: stream inventaris dan booking, cart peminjaman, approval Aslab/Kalab, validasi QR, laporan maintenance, dan audit barcode.

## Package Utama

- `supabase_flutter`: Auth, Database, Storage, dan Realtime stream.
- `flutter_bloc`: state management berbasis event/state.
- `google_fonts`: typography Poppins untuk visual premium.
- `local_auth`: biometric login.
- `image_picker`: upload KTM dan foto laporan kerusakan.
- `table_calendar`: smart calendar stok.
- `qr_flutter`: dynamic QR pass.
- `mobile_scanner`: QR/barcode scanner.
- `signature`: digital signature pad Kalab.
- `intl`: utilitas tanggal/waktu.

## Setup Supabase

1. Jalankan `supabase_schema.sql` di Supabase SQL Editor.
2. Jalankan `supabase_seed.sql` untuk mengisi data awal lab dan inventaris.
3. Buat bucket Storage berikut di Supabase:
   - `ktm`
   - `maintenance-reports`
   - `signatures`
4. Isi credentials permanen di:

```dart
lib/core/constants/supabase_credentials.dart
```

Ganti:

```dart
static const url = 'https://your-project-ref.supabase.co';
static const anonKey = 'your-supabase-anon-or-publishable-key';
```

dengan URL dan anon/publishable key proyek Supabase.

## Menjalankan Aplikasi

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Saat credentials belum diisi, aplikasi tetap bisa dibuka sampai halaman login, tetapi operasi Supabase akan menampilkan pesan konfigurasi.

## Fitur Multi-Role

- Mahasiswa: kalender stok realtime, grid inventaris, cart booking, checkout, dynamic QR pass, timeline status, busy meter, laporan kerusakan dengan kamera.
- Aslab: swipe-right approval awal dan scanner QR untuk mengubah status booking menjadi `active` atau `returned`.
- Kalab: approval akhir dengan signature pad, upload tanda tangan ke Storage, smart inventory alert untuk stok kritis, dan audit barcode.
