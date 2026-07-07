# Product Requirement Document - LabIn
### Sistem Manajemen Laboratorium Interdisipliner Terpadu, TermsGate, Jadwal Ruangan Real-Time, Aslab, dan Kalab

> **Fokus Produk:** Peminjaman ruang dan alat, sinkronisasi jadwal, pengendalian stok, pelaporan maintenance, dan alur operasional multi-role. Dokumen ini adalah versi final PRD LabIn yang siap dibuka dan diedit langsung di VSCode.

---

## 1. Informasi Dokumen

| Item | Keterangan |
| :--- | :--- |
| **Nama Produk** | LabIn (Laboratorium Interdisipliner) |
| **Jenis Produk** | Sistem manajemen fasilitas, sarpras, dan peminjaman laboratorium kampus |
| **Platform Mobile** | Flutter mobile app untuk Mahasiswa |
| **Platform Operasional** | Dashboard Aslab dan Kalab |
| **Backend** | Supabase: Auth, PostgreSQL, Realtime, RLS, Storage |
| **Target Pengguna** | Mahasiswa, Aslab, Kalab |
| **Target Proyek** | Produk akademik siap demo dan portfolio full-stack |
| **Status Dokumen** | Final PRD |
| **Versi** | v1.1 |

### 1.1 Addendum Implementasi Produk
* Halaman Terms & Conditions hanya muncul untuk akun baru yang baru selesai register.
* Login akun lama langsung bypass ke Beranda tanpa menampilkan TermsGate.
* Seluruh UI mengikuti tema kampus aktif melalui `AppTheme.campusColorsOf(context)`.
* Perubahan kampus harus mengubah warna utama beranda, profil, tombol, border, dan indikator secara sinkron.
* Laporan maintenance mahasiswa memakai status awal `diterima` agar sesuai constraint database.
* Fitur QR scanner, PDF, dan checkout harus berjalan tanpa dummy dan tanpa error platform.
* Settings memakai background putih netral, sedangkan kartu header profil mengikuti warna kampus aktif.

### 1.2 Pembaruan Implementasi Terkini
* Label role pada header profil harus tetap tampil dan menyesuaikan role pengguna aktif, misalnya Mahasiswa, Aslab, atau Kalab.
* Halaman jadwal ruangan untuk Mahasiswa bersifat read-only dan hanya menampilkan status ketersediaan ruangan.
* Halaman jadwal ruangan untuk Kalab memiliki kontrol tambahan untuk block atau unblock slot waktu tertentu.
* Status slot yang terbooking harus terlihat jelas agar mahasiswa tidak mengajukan peminjaman ganda.
* Nama ruangan dan aset laboratorium harus mengikuti file gambar lokal yang valid di folder assets agar tidak memunculkan placeholder yang salah.
* Sistem pencarian global, notifikasi, dan riwayat harus tetap memfilter data berdasarkan user aktif.

---

## 2. Ringkasan Produk
LabIn adalah aplikasi manajemen laboratorium interdisipliner berbasis mobile yang digunakan untuk mengelola peminjaman ruang, alat, dan sarpras kampus secara terstruktur. Aplikasi ini menghubungkan Mahasiswa, Aslab, dan Kalab dalam satu alur operasional yang real-time, aman, dan mudah diaudit.

Produk ini dirancang untuk:
* Mengurangi proses manual peminjaman.
* Mencegah duplikasi booking.
* Mempercepat validasi operasional.
* Menjaga sinkronisasi stok dan jadwal.
* Menyediakan jejak aktivitas yang jelas untuk audit dan pelaporan.

---

## 3. Masalah yang Diselesaikan
Pengelolaan laboratorium konvensional di kampus umumnya masih menghadapi beberapa masalah:
* Peminjaman alat dan ruangan masih sering dilakukan manual.
* Jadwal penggunaan ruangan tidak transparan.
* Status booking sering tidak sinkron antar pihak.
* Laporan kerusakan sarpras tidak terdokumentasi rapi.
* Pengurangan stok sering salah timing.
* Pengguna sulit mengetahui siapa yang harus melakukan approval di tiap tahap.

LabIn hadir untuk menyederhanakan semua alur tersebut dalam satu aplikasi yang tersinkron dengan database.

---

## 4. Tujuan Produk

### 4.1 Tujuan Utama
Membangun platform manajemen laboratorium yang cepat, responsif, aman, dan mudah dipahami oleh mahasiswa maupun pengelola.

### 4.2 Tujuan Khusus
* Menyediakan login, register, dan session persistence yang stabil.
* Menampilkan TermsGate hanya satu kali pada akun baru.
* Menyediakan dashboard kampus dengan tema yang menyesuaikan lokasi aktif.
* Memungkinkan mahasiswa melakukan peminjaman ruang dan alat secara terarah.
* Menghubungkan alur persetujuan Aslab dan Kalab.
* Mengaktifkan PDF surat peminjaman, notifikasi, histori, dan maintenance report.
* Menjaga stok barang dan jadwal ruangan tetap konsisten dengan status transaksi.

---

## 5. Target Pengguna

### 5.1 Mahasiswa
* Login atau register.
* Membaca terms jika akun baru.
* Melihat katalog sarpras dan jadwal ruangan.
* Mengajukan peminjaman, memantau approval, dan mengunduh dokumen peminjaman.
* Mengirim laporan kerusakan bila diperlukan.

### 5.2 Aslab
* Memeriksa pengajuan awal dan validasi operasional barang/ruang.
* Melakukan scan QR pada alur serah terima.
* Membantu menjaga kelancaran operasional harian.

### 5.3 Kalab
* Memberi approval final.
* Mengendalikan stok, operasional ruangan, serta memblokir/membuka slot tertentu.
* Memproses laporan maintenance dan kontrol transaksi final.

### 5.4 Pembagian Peran pada Jadwal Ruangan
* **Mahasiswa:** Hanya melihat ketersediaan slot, tanggal, dan status ruangan.
* **Aslab:** Membantu validasi operasional, termasuk serah terima barang.
* **Kalab:** Mengatur status ruangan, memblokir slot tertentu, dan memastikan jadwal tidak bentrok.

---

## 6. Platform dan Teknologi

### 6.1 Mobile App
* **Framework:** Flutter 3.x & Dart 3.x
* **State Management:** BLoC / Riverpod
* **Formatting & Utilities:** `intl`, `image_picker`, `mobile_scanner` (atau `qr_code_scanner`), `cached_network_image`

### 6.2 Backend
* Supabase Auth
* PostgreSQL Database
* Realtime Subscriptions
* Row Level Security (RLS) & Supabase Storage

---

## 7. Scope Produk

### 7.1 Fitur Wajib MVP
* Smart Auth (Login, Register, Session Persistence) & TermsGate akun baru.
* Dashboard mahasiswa dengan tema kampus dinamis.
* Form peminjaman ruang/alat & checkout keranjang (status pending).
* Jadwal ruangan real-time & role dashboard (Aslab & Kalab).
* QR scan serah terima barang, Approval final Kalab, & PDF surat peminjaman.
* Riwayat, notifikasi, pengaturan profil, dan pelaporan maintenance.

### 7.2 Out of Scope
* Geofencing kehadiran otomatis.
* IoT smart lock untuk pintu ruangan.
* TTE tersertifikasi.
* Forecasting kebutuhan alat.
* Integrasi pembayaran.

---

## 8. Alur Utama Pengguna

### 8.1 Mahasiswa
1. Register/Login $\rightarrow$ Jika akun baru, melewati TermsGate satu kali.
2. Memilih kampus aktif $\rightarrow$ Melihat katalog, jadwal, dan status ruangan.
3. Mengisi form peminjaman $\rightarrow$ Checkout (status menjadi pending).
4. Memantau approval via notifikasi/riwayat $\rightarrow$ Unduh PDF setelah approved final.

### 8.2 Aslab
1. Login ke dashboard operasional $\rightarrow$ Melihat antrean booking/pengajuan.
2. Memverifikasi data $\rightarrow$ Melakukan scan QR saat serah terima barang.
3. Menandai booking siap diteruskan ke Kalab.

### 8.3 Kalab
1. Login ke dashboard manajemen $\rightarrow$ Melihat antrean approval final.
2. Memeriksa jadwal/stok $\rightarrow$ Approve/Reject permintaan.
3. Mengatur block/unblock slot ruangan & memproses laporan maintenance.

### 8.4 Login/Register dan TermsGate
* TermsGate hanya muncul jika user selesai register. Akun lama langsung bypass ke Beranda.
* Tombol setuju di TermsGate hanya aktif setelah scroll selesai.

---

## 9. Fitur Fungsional per Modul

* **9.1 Auth & Onboarding:** Register profil dasar, login email/password, session persistence, TermsGate user baru, opsi biometrik.
* **9.2 Dashboard Mahasiswa:** Header lokasi aktif, search global, kalender mingguan responsif, katalog modul LabIn & Sarpras dengan kartu stok.
* **9.3 Form Peminjaman:** Input identitas lengkap. Fitur checkbox "pinjam diri sendiri" untuk auto-fill data session, checklist alat, dan validasi ketat.
* **9.4 Jadwal Ruangan:** Tampilan slot waktu real-time. Mode read-only untuk mahasiswa (hanya status ketersediaan). Kalab memiliki hak akses eksklusif untuk block/unblock slot.
* **9.5 Sarpras & Denah:** Katalog dengan gambar dari aset lokal/URL valid, denah kampus multi-lokasi terintegrasi Google Maps.
* **9.6 Keranjang, Checkout, & PDF:** Checkout ke Supabase menghasilkan status pending. Stok berkurang dan PDF aktif **hanya** setelah approval final Kalab.
* **9.7 Notifikasi & Riwayat:** Push alert pembaruan status transaksi. Riwayat wajib terfilter otomatis berdasarkan user aktif secara rapi.
* **9.8 Settings & Profil:** Edit profile & upload avatar ke storage. Tema warna mengikuti lokasi kampus secara dinamis dengan background utama netral.
* **9.9 Dashboard Aslab:** Manajemen daftar tunggu validasi dan integrasi QR Scanner untuk mengubah status booking menjadi aktif.
* **9.10 Dashboard Kalab:** Panel kendali utama untuk approval final, manajemen stok, tabel laporan maintenance, dan tombol aksi responsif.

---

## 10. Aturan Bisnis Inti

* **TermsGate:** Khusus akun baru. Tombol persetujuan terkunci sebelum scroll teks selesai.
* **Stok Barang:** Tidak berkurang pada status pending atau approval Aslab. Stok terpotong mutlak pada approval final Kalab.
* **Jadwal Ruangan:** Mahasiswa dilarang melihat beban visual kontrol operasional. Jika slot diblokir Kalab, otomatis terbaca tidak tersedia oleh mahasiswa.
* **Maintenance:** Status default: `diterima`. Kalab berhak memutasi status menjadi `diproses`, `selesai`, atau `ditolak`.
* **PDF:** Tombol unduh terkunci total selama status belum final (`approved_kalab`).
* **Lokasi Kampus:** Warna UI wajib responsif (gradient, border, aksen) mengikuti lokasi kampus aktif pada beranda, profil, dan button.

---

## 11. Struktur Data & Integrasi Supabase

### 11.1 Tabel `profiles`
* `id` (PK), `nama`, `identitas`, `email`, `role`, `campus_id`, `avatar_url`, `created_at`

### 11.2 Tabel `inventories`
* `id` (PK), `lab_id`, `nama_alat`, `stok_total`, `stok_tersedia`, `jenis`, `foto_url`, `created_at`

### 11.3 Tabel `bookings`
* `id` (PK), `user_id`, `campus_id`, `laboratory_id`, `reservation_no`, `start_time`, `end_time`, `purpose`, `status`, `created_at`
* *Enum Status:* `pending`, `approved_aslab`, `approved_kalab`, `active`, `returned`, `rejected`

### 11.4 Tabel `booking_items`
* `id` (PK), `booking_id`, `inventory_id`, `quantity`

### 11.5 Tabel `maintenance_reports`
* `id` (PK), `user_id`, `inventory_id`, `deskripsi`, `foto_url`, `status_perbaikan`, `created_at`
* *Enum Status:* `diterima`, `diproses`, `selesai`, `ditolak`

### 11.6 Tabel `notifications`
* `id` (PK), `user_id`, `title`, `body`, `type`, `read_at`, `created_at`

### 11.7 Tabel `terms_acceptances`
* `id` (PK), `user_id`, `accepted_at`, `version`

### 11.8 Realtime & RLS
* Modul booking, notifikasi, dan jadwal wajib menggunakan realtime subscription.
* Seluruh data di Supabase diamankan menggunakan Row Level Security (RLS) terfilter berdasarkan `user_id` aktif.

---

## 12. Kontrak Data dan API Client-Side

### 12.1 Checkout Booking
```dart
await supabase.from('bookings').insert({
  'user_id': userId,
  'campus_id': campusId,
  'laboratory_id': labId,
  'reservation_no': reservationNo,
  'start_time': startTime.toIso8601String(),
  'end_time': endTime.toIso8601String(),
  'purpose': purpose.trim(),
  'status': 'pending',
});

### 12.2 Approval Final Kalab
```dart
await supabase.from('bookings').update({
  'status': 'approved_kalab',
}).eq('id', bookingId);

### 12.3 Laporan Maintenance Mahasiswa
await supabase.from('maintenance_reports').insert({
  'user_id': userId,
  'inventory_id': inventoryId,
  'deskripsi': description.trim(),
  'foto_url': photoUrl,
  'status_perbaikan': 'diterima',
});

---

## 13. Kriteria Penerimaan (Acceptance Criteria)

* **13.1 TermsGate:** User baru register wajib melihat terms. User lama langsung bypass. Tombol setuju terkunci sampai scroll berakhir.
* **13.2 Dynamic Campus Theme:** Transisi warna UI di halaman utama, settings, dan beranda berubah seketika mengikuti pembaruan data lokasi kampus.
* **13.3 Booking Flow:** Output awal berstatus pending tanpa mengurangi stok. Validasi final mutlak berada pada keputusan Kalab.
* **13.4 Maintenance Flow:** Laporan terinisiasi dengan status `diterima` dan disajikan dalam bentuk list card/tabel yang mudah dipindai oleh Kalab.
* **13.5 PDF Flow:** Validasi tombol download terkunci ketat jika status relasi data belum mencapai status final.

---

## 14. Risiko Teknis dan Mitigasi

| Risiko | Dampak | Mitigasi |
| :--- | :--- | :--- |
| Check constraint status tidak cocok | Data gagal tersimpan | Samakan string literal client dan SQL |
| Kamera tidak diberi izin | Scanner crash di Android | Tambahkan permission native kamera |
| Query tanpa filter user | Data lintas user bocor | Selalu filter by `user_id` aktif |
| Dead code / widget berat | UI lambat di mobile | Hapus komponen tidak dipakai |
| Theme statis tidak sinkron | Branding kampus terasa rusak | Pakai campus theme extension secara konsisten |
| Context navigation tidak aman | Force close saat pindah halaman | Pakai `if (context.mounted)` sebelum Navigator.push |
| Jadwal mahasiswa terlalu kompleks | UX sulit dipahami | Pisahkan mode read-only untuk mahasiswa dan mode kontrol untuk Kalab |

---

## 15. Prioritas Implementasi
1. Auth, TermsGate, dan session persistence.
2. Dynamic campus theme di semua halaman utama.
3. Booking flow, checkout, dan validasi stok.
4. Jadwal ruangan real-time dan role-based access.
5. Aslab scanner QR dan serah terima barang.
6. Kalab approval final dan maintenance management.
7. PDF, notifikasi, histori, settings, dan profil.

---

## 16. Definition of Done (DoD)
* Aplikasi berjalan tanpa error utama & `flutter analyze` bersih.
* Modul transaksi terintegrasi penuh secara realtime ke Supabase.
* Alur kerja antar role (Mahasiswa, Aslab, Kalab) tervalidasi dengan benar.
* Role-based UI berjalan konsisten di semua halaman utama (Settings, dashboard, dan jadwal ruangan menampilkan warna sesuai lokasi kampus aktif).

---

## 17. Kesimpulan
LabIn adalah platform manajemen laboratorium yang dirancang agar peminjaman ruang dan alat menjadi lebih cepat, transparan, aman, dan siap dipresentasikan sebagai produk full-stack. Dengan dukungan role Mahasiswa, Aslab, dan Kalab, aplikasi ini memiliki alur operasional yang lengkap dari pengajuan, validasi, approval final, hingga dokumentasi dan audit.