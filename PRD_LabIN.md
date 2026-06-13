# PRD LabIN

## Ringkasan Produk

LabIN adalah aplikasi mobile untuk membantu pengelolaan aktivitas laboratorium, mulai dari peminjaman alat, jadwal penggunaan ruang lab, pelaporan kerusakan, hingga riwayat aktivitas pengguna. Aplikasi ditujukan untuk mahasiswa, dosen, asisten laboratorium, dan admin laboratorium.

## Tujuan

- Mempermudah pengguna melihat ketersediaan fasilitas laboratorium.
- Menyediakan alur peminjaman alat dan ruang yang jelas.
- Membantu admin memantau permintaan, jadwal, inventaris, dan laporan kerusakan.
- Mengurangi pencatatan manual yang rawan hilang atau tidak sinkron.

## Target Pengguna

- Mahasiswa: melihat jadwal lab, mengajukan peminjaman, melaporkan kerusakan.
- Dosen: memesan ruang lab untuk kegiatan perkuliahan atau praktikum.
- Asisten laboratorium: memvalidasi penggunaan alat, mengecek kondisi inventaris.
- Admin laboratorium: mengelola data alat, ruang, jadwal, pengguna, dan laporan.

## Ruang Lingkup MVP

### Autentikasi

- Pengguna dapat masuk menggunakan email dan password.
- Pengguna memiliki role: mahasiswa, dosen, asisten, atau admin.
- Pengguna dapat keluar dari aplikasi.

### Dashboard

- Menampilkan ringkasan jadwal lab hari ini.
- Menampilkan status pengajuan peminjaman terbaru.
- Menampilkan notifikasi penting seperti persetujuan, penolakan, atau jadwal mendatang.

### Inventaris Alat

- Pengguna dapat melihat daftar alat laboratorium.
- Setiap alat memiliki nama, kategori, kode inventaris, status, lokasi, dan deskripsi.
- Status alat minimal mencakup tersedia, dipinjam, rusak, dan perawatan.

### Peminjaman

- Pengguna dapat mengajukan peminjaman alat atau ruang.
- Form peminjaman mencakup item, tanggal, waktu mulai, waktu selesai, tujuan, dan catatan.
- Admin atau asisten dapat menyetujui atau menolak pengajuan.
- Pengguna dapat melihat riwayat pengajuan.

### Jadwal Laboratorium

- Pengguna dapat melihat jadwal penggunaan ruang lab.
- Jadwal dapat difilter berdasarkan tanggal dan ruang.
- Admin dapat membuat, mengubah, dan menghapus jadwal.

### Laporan Kerusakan

- Pengguna dapat membuat laporan kerusakan alat atau fasilitas.
- Laporan mencakup item, lokasi, deskripsi masalah, tingkat urgensi, dan foto opsional.
- Admin dapat memperbarui status laporan menjadi diterima, diproses, selesai, atau ditolak.

### Profil

- Pengguna dapat melihat informasi akun.
- Pengguna dapat mengubah nama, nomor identitas, program studi, dan nomor telepon.

## Kebutuhan Non-Fungsional

- Aplikasi dibuat dengan Flutter 3 dan Dart.
- UI mengikuti Material Design.
- Struktur kode dipisahkan berdasarkan fitur.
- State management direkomendasikan menggunakan Riverpod.
- Navigasi direkomendasikan menggunakan GoRouter.
- Aplikasi harus responsif untuk ukuran layar Android umum.
- Form harus memiliki validasi input.
- Error dan loading state harus ditampilkan dengan jelas.

## Struktur Fitur yang Disarankan

- `auth`: login, logout, session, role.
- `dashboard`: ringkasan aktivitas dan notifikasi.
- `inventory`: daftar dan detail alat.
- `booking`: pengajuan dan riwayat peminjaman.
- `schedule`: jadwal ruang lab.
- `report`: laporan kerusakan.
- `profile`: data pengguna.

## Data Utama

### User

- `id`
- `name`
- `email`
- `role`
- `identityNumber`
- `department`
- `phone`

### LabItem

- `id`
- `name`
- `inventoryCode`
- `category`
- `status`
- `location`
- `description`

### BookingRequest

- `id`
- `userId`
- `itemId`
- `roomId`
- `startTime`
- `endTime`
- `purpose`
- `status`
- `notes`

### LabSchedule

- `id`
- `roomId`
- `title`
- `startTime`
- `endTime`
- `createdBy`

### DamageReport

- `id`
- `userId`
- `itemId`
- `location`
- `description`
- `urgency`
- `status`
- `photoUrl`

## Alur Utama

1. Pengguna login ke aplikasi.
2. Pengguna melihat dashboard dan jadwal lab.
3. Pengguna memilih alat atau ruang yang ingin digunakan.
4. Pengguna mengirim pengajuan peminjaman.
5. Admin atau asisten memvalidasi pengajuan.
6. Pengguna menerima status pengajuan.
7. Setelah penggunaan selesai, status alat atau ruang diperbarui.

## Kriteria Sukses MVP

- Pengguna dapat login dan melihat dashboard.
- Pengguna dapat melihat daftar alat dan jadwal lab.
- Pengguna dapat membuat pengajuan peminjaman.
- Admin atau asisten dapat mengubah status pengajuan.
- Pengguna dapat membuat laporan kerusakan.
- Semua form utama memiliki validasi dasar.
- Aplikasi lulus `flutter analyze` tanpa error.

## Rencana Implementasi Awal

1. Rapikan struktur folder Flutter berdasarkan fitur.
2. Tambahkan dependency Riverpod dan GoRouter.
3. Buat model data inti.
4. Buat halaman login dan dashboard.
5. Buat dummy repository untuk inventaris, jadwal, peminjaman, dan laporan.
6. Hubungkan flow navigasi dasar.
7. Tambahkan test widget untuk halaman utama.

