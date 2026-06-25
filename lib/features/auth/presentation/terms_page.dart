import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final _scrollController = ScrollController();
  bool _reachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final reachedBottom = position.pixels >= position.maxScrollExtent - 16;
    if (reachedBottom != _reachedBottom) {
      setState(() {
        _reachedBottom = reachedBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ketentuan Penggunaan LabIn'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 16) {
                    if (!_reachedBottom) {
                      setState(() => _reachedBottom = true);
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.cyberGradient,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      AppBrand.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ketentuan Penggunaan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Baca sampai selesai sebelum masuk ke beranda.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Selamat datang di ${AppBrand.name}!',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Terima kasih atas ketersediaan Anda untuk menggunakan platform peminjaman interdisipliner multi-fasilitas ini. Dokumen ini menjelaskan hak, kewajiban, batasan, dan tanggung jawab pengguna agar peminjaman ruang, alat, dan layanan kampus tetap tertib, aman, dan transparan.',
                                textAlign: TextAlign.justify,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 18),
                              const _TermsParagraph(
                                title: '1. Ruang Lingkup Layanan',
                                body:
                                    'LabIn menyediakan sarana untuk mengajukan peminjaman ruang, alat, dan fasilitas kampus dengan alur digital yang terhubung ke data operasional. Pengguna wajib memastikan data yang diinput akurat, termasuk identitas, jadwal, dan kebutuhan peminjaman.',
                              ),
                              const _TermsParagraph(
                                title: '2. Ketepatan Informasi',
                                body:
                                    'Seluruh informasi yang dikirimkan melalui formulir harus benar, dapat diverifikasi, dan sesuai kebutuhan kegiatan. Data palsu, manipulatif, atau tidak relevan dapat menyebabkan penolakan pengajuan serta pembatasan akses akun.',
                              ),
                              const _TermsParagraph(
                                title: '3. Tanggung Jawab Pengguna',
                                body:
                                    'Pengguna bertanggung jawab atas penggunaan fasilitas yang dipinjam, termasuk menjaga kebersihan, ketertiban, dan keamanan barang maupun ruang. Segala kerusakan, kehilangan, atau penyalahgunaan wajib dilaporkan sesuai prosedur yang berlaku.',
                              ),
                              const _TermsParagraph(
                                title: '4. Validasi dan Persetujuan',
                                body:
                                    'Setiap pengajuan dapat melalui proses verifikasi oleh asisten laboratorium atau kepala laboratorium. Status peminjaman dapat berubah menjadi pending, disetujui, atau ditolak berdasarkan ketersediaan, kesesuaian jadwal, dan kebijakan operasional kampus.',
                              ),
                              const _TermsParagraph(
                                title: '5. Privasi dan Keamanan',
                                body:
                                    'Data akun, sesi login, dokumen KTM, dan riwayat peminjaman dikelola untuk menunjang operasional layanan. Pengguna wajib menjaga kredensial pribadi dan tidak membagikan akses akun kepada pihak lain.',
                              ),
                              const _TermsParagraph(
                                title: '6. Perubahan Ketentuan',
                                body:
                                    'LabIn dapat memperbarui ketentuan penggunaan dari waktu ke waktu agar selaras dengan kebutuhan layanan dan kebijakan akademik. Pengguna dianjurkan membaca kembali ketentuan setiap kali ada pembaruan penting.',
                              ),
                              const _TermsParagraph(
                                title: '7. Pernyataan Persetujuan',
                                body:
                                    'Dengan menekan tombol Saya Setuju, pengguna menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan penggunaan LabIn. Jika tidak setuju, pengguna dapat keluar dari halaman ini dan kembali lagi setelah mempertimbangkan syarat yang berlaku.',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Lanjutkan membaca hingga akhir halaman untuk mengaktifkan tombol persetujuan.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _reachedBottom ? _accept : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('Saya Setuju'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _accept() {
    widget.onAccepted();
  }
}

class _TermsParagraph extends StatelessWidget {
  const _TermsParagraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.justify,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
