import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dashboard_repository.dart';

class DownloadDocsPage extends StatelessWidget {
  const DownloadDocsPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unduh Dokumen Berkas')),
      body: SafeArea(
        child: StreamBuilder(
          stream: repository.watchApprovedDocuments(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!;
            if (docs.isEmpty) {
              return const Center(
                child: Text('Belum ada dokumen approved Kalab.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(doc.reservationNo),
                    subtitle: const Text(
                      'Surat izin peminjaman disetujui Kalab',
                    ),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () async {
                        final url = doc.signatureUrl;
                        if (url == null || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('URL dokumen belum tersedia.'),
                            ),
                          );
                          return;
                        }
                        await launchUrl(Uri.parse(url));
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('PDF'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
