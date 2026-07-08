# Pembagian Kontribusi Tim LabIn (Berdasarkan Audit Git Graph)

Dokumen ini merangkum pembagian kontribusi 3 anggota tim mahasiswa **S1 Teknik Informatika Universitas Duta Bangsa Surakarta** yang terlibat secara aktif dalam pengerjaan proyek **LabIn (Laboratorium Interdisipliner Terpadu)**. Evaluasi pembagian kerja ini disusun secara transparan dan objektif berdasarkan audit histori commit non-merge pada Git Graph repositori utama proyek dari fase awal hingga rilis produk akademik UAS.

---

## 1. Metode Audit Sistem

Audit pelaporan kerja ini disusun dan diverifikasi langsung melalui instrumen:
* **Histori Git Graph Proyek:** Peninjauan kontribusi kode aktif, pengerjaan fungsionalitas, serta perbaikan bug (*hotfix*) dari tanggal 6 Juni hingga 7 Juli 2026.
* **Scope Fitur MVP:** Distribusi pengerjaan arsitektur Flutter (BLoC/Data Layer/Presentation Layer) dan integrasi layanan cloud database Supabase.
* **Aktivitas Deployment:** Rekam jejak penyempurnaan sistem operasional, pembersihan visual, serta penyusunan berkas administrasi rilis untuk kebutuhan Google Play Console.

---

## 2. Ringkasan Pembagian Peran (Summary Matrix)

| Kontributor | Peran Utama dalam Git Graph | Fokus Pekerjaan Utama |
| :--- | :--- | :--- |
| **Hilda Nur Abidah** <br>*(NIM: 240103250)* | **Lead System Integrator & Feature Implementer** | Bertanggung jawab atas konfigurasi dan penyediaan cloud database, manajemen integrasi fungsional hardware native, sistem otomasi dokumen, serta sinkronisasi tema warna (*OCR Camera, Google OAuth, Dynamic Campus Theme, PDF Auto-Generator, QR Scanner Handover, & Live Notifications*). |
| **Arvanda Nuraini** <br>*(NIM: 240103249)* | **Backend Schema & Admin Operations Dev** | Bertanggung jawab atas fondasi awal skema database Supabase, arsitektur tabel relasional, Row Level Security (RLS), logika penanganan konflik booking, ketersediaan ruangan real-time, manajemen menu Kalab, kontrol hak akses data, serta kendali operasional internal. |
| **Dhiannika Wahyu N. H.** <br>*(NIM: 240103187)* | **UI/UX Refiner & Client Layout Polish** | Bertanggung jawab atas responsivitas layout mobile, penanganan masalah *overflow rendering* di sisi klien, penyelarasan tipografi global, penyesuaian fungsional onboarding screen, integrasi denah visual terstruktur, visualisasi riwayat, penataan aset gambar, dan validasi form autentikasi. |

---

## 3. Bukti Aktivitas & Detail Kontribusi per Kontributor

### 3.1 Hilda Nur Abidah (Lead System Integrator)
Hilda bertanggung jawab penuh terhadap inisialisasi cloud server database Supabase serta menghubungkan arsitektur data layer tersebut dengan komponen API native, pemrosesan perangkat keras, dan otomasi dokumen pada framework Flutter.
* **Kontribusi Fitur Utama (Verified by Commits):**
  * **Inisialisasi & Tata Kelola Cloud Database:** Melakukan penyusunan lingkungan database proyek pada konsol Supabase, menyelaraskan sinkronisasi kolom WhatsApp, mengelola hak akses storage bucket untuk penyimpanan berkas eksternal, serta menjamin stabilitas query backend.
  * **Integrasi Kamera & Validasi OCR:** Mengembangkan fungsionalitas penangkapan gambar kartu identitas (KTM) secara native dan mengintegrasikannya dengan mesin ekstraksi teks otomatis (*OCR Camera*) untuk alur registrasi pengguna baru.
  * **Sistem Cetak Berkas Dokumen:** Membangun modul *PDF Auto-Generator Integration* untuk menerbitkan lembar surat izin peminjaman digital resmi yang tersinkronisasi langsung ke cloud storage berdasarkan status approval.
  * **Sistem Alur QR Scanner Handover:** Menyelesaikan modul pemindaian kode respons cepat (*Aslab QR Scanner*) untuk memproses perubahan status inventaris secara real-time saat serah terima barang berlangsung.
  * **Dynamic Campus Theme Matrix:** Mengonfigurasi logika pewarnaan antarmuka dinamis agar komponen visual seperti tombol, border, dan kartu informasi otomatis beradaptasi dengan lokasi kampus aktif.
  * **Google OAuth & Keamanan Navigasi:** Mengintegrasikan sistem autentikasi pihak ketiga menggunakan Google Sign-In serta menerapkan validasi `if (context.mounted)` guna menghindari memory leak atau crash pada penanganan alur asinkron.
* **Pesan Commit Kunci pada Grafik Proyek:**
  * `Fix: Step 1 - Real SSO, OCR Camera Validation, and Supabase WA Column Sync`
  * `Feat: Step 3 - Multi-Faculty Form, 8 Lab Schedule, and PDF Auto-Generator Integration`
  * `Feat: Step 4 - Real Campus Denah Maps, Feedback System, QR Scanner, and Live Notifications`
  * `refactor: campus theme sync, maintenance flow, and schedule UI`
  * `UI/Fix: Expand logo fitting, purge dark header blocks, and implement sleek light top navbar`

### 3.2 Arvanda Nuraini (Backend & Admin Dev)
Arvanda bertanggung jawab penuh atas perancangan struktur data relasional, pengkondisian aturan keamanan sirkulasi data internal, penanganan logika bisnis multi-aktor, serta kontrol eksklusif pada menu panel dashboard administrasi.
* **Kontribusi Fitur Utama (Verified by Commits):**
  * **Perancangan Arsitektur Basis Data:** Menyusun skema tabel awal proyek (`profiles`, `inventories`, `bookings`), mendesain relasi data, foreign key, serta menerapkan Row Level Security (RLS) ketat untuk membatasi hak akses riwayat peminjaman sesuai kepemilikan akun.
  * **Sistem Manajemen Penjadwalan Kamar:** Membangun mesin pengecek konflik jadwal (*conflict checker*), visualisasi ketersediaan ruangan real-time, serta tombol instruksi *block/unblock slot waktu* harian khusus untuk otoritas Kalab.
  * **Optimalisasi Dashboard Administrasi:** Mengembangkan struktur visual untuk panel kontrol operasional menu Kalab, termasuk fitur peninjauan bertingkat (*multistep review*) dari verifikasi Aslab hingga otorisasi final potong stok barang oleh Kalab.
  * **Sistem Pelaporan Kendala Sarpras:** Merestrukturisasi query penyimpanan laporan maintenance mahasiswa dengan penyesuaian constraint status awal database (status default `diterima`) agar mempermudah monitoring kerusakan oleh pengelola.
* **Pesan Commit Kunci pada Grafik Proyek:**
  * `Add Supabase schema for LabIn`
  * `Feat: Step 2 - Refine multistep booking review`
  * `Feat: Step 2 - Upgrade SAPRAS assets and status UI`
  * `Fix: lock booking history detail by owner role`
  * `refactor: move maintenance reports to dedicated page`

### 3.3 Dhiannika Wahyu N. H. (UI/UX Refiner)
Dhiannika bertanggung jawab penuh dalam menjaga konsistensi visual antarmuka klien, memosisikan tata letak komponen agar responsif, serta membebaskan alur navigasi dari kendala rendering atau overflow halaman.
* **Kontribusi Fitur Utama (Verified by Commits):**
  * **Penyempurnaan Alur Onboarding & Autentikasi:** Menerapkan desain *glassmorphism app bar*, membersihkan tumpukan layout header panel login, memosisikan textfield registrasi, serta memperkuat validasi error handling pada form registrasi mahasiswa.
  * **Penanganan Masalah Responsivitas Visual:** Memperbaiki gangguan kegagalan render (*overflow bug handling*) pada kartu sirkulasi stok, menyelaraskan tipografi global, serta memperbaiki pemotongan teks pada status linimasa peminjaman.
  * **Integrasi Denah & Manajemen Aset Lokal:** Menyusun visualisasi blueprint denah laboratorium terintegrasi multi-kampus, memetakan aset lokal di folder assets untuk menghindari placeholder kosong, serta mengonfigurasi fitur pilihan bahasa (Bahasa Indonesia & English).
* **Pesan Commit Kunci pada Grafik Proyek:**
  * `Improve registration auth error handling`
  * `Make dashboard navbar responsive`
  * `Fix: Rollback onboarding visual, resolve slider overflow, lock strict user_id privacy`
  * `Fix: dark calendar contrast and SAPRAS image loading`
  * `ui: fix text overflow in timeline status`

---

## 4. Matriks Pembagian Kerja Berdasarkan Modul Aplikasi

| Modul Utama LabIn | Penanggung Jawab Dominan | Bukti Fungsional Proyek |
| :--- | :--- | :--- |
| **Arsitektur PRD & Dokumentasi** | Hilda Nur Abidah | Dokumen PRD v1.1 resmi pada direktori `docs/` |
| **Database Server Initialization** | Hilda Nur Abidah | Penyediaan dan konfigurasi sistem cloud backend Supabase |
| **Database Tables & SQL Schema Design** | Arvanda Nuraini | Skema migrations Supabase PostgreSQL & aturan RLS |
| **OCR KTM Validation & Google SSO** | Hilda Nur Abidah | Modul registrasi akun mahasiswa baru |
| **TermsGate & Scroll Validation** | Hilda Nur Abidah | Fitur scroll-lock pada tombol persetujuan syarat |
| **Dynamic Campus Theme Matrix** | Hilda Nur Abidah | Sinkronisasi perubahan warna UI berbasis lokasi aktif |
| **UI/UX Dashboard & Sarpras Mobile** | Dhiannika Wahyu N. H. | Responsive app-bars dan pembersihan bug overflow visual |
| **Real-Time Schedule Matrix & CRUD** | Arvanda Nuraini | Kontrol slot ketersediaan ruang laboratorium |
| **QR Code Scanner & Handover Logic** | Hilda Nur Abidah | Modul serah terima barang oleh Aslab |
| **PDF Auto-Generator Cloud Sync** | Hilda Nur Abidah | Unduh surat izin peminjaman format PDF resmi |
| **Maintenance Flow & Data Integrity** | Arvanda & Hilda | Penyelarasan constraint status awal database |

---

## 5. Kesimpulan Distribusi Beban Kerja

Kolaborasi tim mahasiswa Teknik Informatika UDB Surakarta dalam membangun sistem informasi **LabIn** terbukti berjalan secara berkesinambungan dengan pembagian porsi kerja yang saling melengkapi dan terdokumentasi nyata pada metadata Git riwayat proyek:

1. **Hilda Nur Abidah** bergerak sebagai *lead engine integrator* yang memegang cakupan tanggung jawab pada penyediaan infrastruktur cloud database server, realisasi logika arsitektur tingkat tinggi, fungsionalitas hardware native (Kamera OCR, Scanner QR), pemrosesan berkas cetak dokumen digital, serta sinkronisasi tema UI.
2. **Arvanda Nuraini** bergerak sebagai penyusun skema basis data dasar, pengatur arsitektur relasional PostgreSQL Supabase, dan perancang alur transaksional data sisi administrator laboratorium (Kalab & Aslab).
3. **Dhiannika Wahyu N. H.** bergerak sebagai menjaga estetika antarmuka, konsistensi visual layout halaman, penanganan bug interface (*overflow rendering*), dan kenyamanan pemakaian aplikasi di sisi pengguna (*client-side mobile UX*).

Kombinasi kerja sama ini berhasil menyatukan seluruh modul operasional sehingga aplikasi LabIn siap dipublikasikan secara fungsional maupun arsitektural sebagai produk akademik portfolio full-stack yang utuh.