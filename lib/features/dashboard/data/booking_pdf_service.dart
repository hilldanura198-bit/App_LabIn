import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';
import 'dashboard_models.dart';

class BookingPdfService {
  const BookingPdfService._();

  static Future<Uint8List> buildBookingLetter(LabBooking booking) async {
    final document = pw.Document();
    final formatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat.Hm();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(margin: const pw.EdgeInsets.all(28)),
        build: (context) {
          return [
            _Header(),
            pw.SizedBox(height: 20),
            _InfoBlock(
              booking: booking,
              formatter: formatter,
              timeFormatter: timeFormatter,
            ),
            pw.SizedBox(height: 18),
            _ItemBlock(booking: booking),
            pw.SizedBox(height: 18),
            _SignatureBlock(),
            pw.SizedBox(height: 12),
            pw.Text(
              'Dokumen ini dibuat otomatis oleh ${AppBrand.name} berdasarkan data booking yang tersimpan di sistem.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ];
        },
      ),
    );

    return document.save();
  }
}

class _Header extends pw.StatelessWidget {
  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(AppTheme.deepTeal.toARGB32()),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'KOP SURAT ${AppBrand.name.toUpperCase()}',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            AppBrand.name,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            AppBrand.tagline,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.white, thickness: 1),
          pw.SizedBox(height: 8),
          pw.Text(
            'SURAT KETERANGAN PEMINJAMAN',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends pw.StatelessWidget {
  _InfoBlock({
    required this.booking,
    required this.formatter,
    required this.timeFormatter,
  });

  final LabBooking booking;
  final DateFormat formatter;
  final DateFormat timeFormatter;

  @override
  pw.Widget build(pw.Context context) {
    final rows = <_RowItem>[
      _RowItem('Nomor Surat', booking.reservationNo),
      _RowItem('Nama Peminjam', booking.borrowerName),
      _RowItem('Fakultas', booking.facultyLabel),
      _RowItem('Lab / Ruang', booking.labDisplayName),
      _RowItem('WhatsApp', booking.whatsappNumber),
      _RowItem(
        'Tanggal Pengajuan',
        booking.requestDate == null
            ? '-'
            : formatter.format(booking.requestDate!),
      ),
      _RowItem('Tanggal Peminjaman', formatter.format(booking.tanggalPinjam)),
      _RowItem(
        'Jam',
        '${booking.startTime.isNotEmpty ? booking.startTime : timeFormatter.format(booking.tanggalPinjam)} - '
            '${booking.endTime.isNotEmpty ? booking.endTime : timeFormatter.format(booking.tanggalKembali)}',
      ),
      _RowItem('Keperluan', booking.purpose),
      if ((booking.otherItems ?? '').trim().isNotEmpty)
        _RowItem('Opsi Lainnya', booking.otherItems!.trim()),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Detail Peminjaman',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...rows.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      row.label,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Text(': '),
                  pw.Expanded(
                    child: pw.Text(
                      row.value,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemBlock extends pw.StatelessWidget {
  _ItemBlock({required this.booking});

  final LabBooking booking;

  @override
  pw.Widget build(pw.Context context) {
    final items = booking.itemsSnapshot;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Daftar Barang / Ruangan',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (items.isEmpty)
            pw.Text(
              'Tidak ada daftar alat terpisah. Data peminjaman dicatat sebagai reservasi ruang.',
              style: pw.TextStyle(fontSize: 9),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['No', 'Nama Barang', 'Jumlah'],
              data: [
                for (var i = 0; i < items.length; i++)
                  ['${i + 1}', items[i].name, '${items[i].quantity}'],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(AppTheme.electricBlue.toARGB32()),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                2: pw.FixedColumnWidth(36),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300),
            ),
        ],
      ),
    );
  }
}

class _SignatureBlock extends pw.StatelessWidget {
  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Catatan:', style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Dokumen ini berlaku sebagai bukti permohonan peminjaman.',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Container(
          width: 180,
          child: pw.Column(
            children: [
              pw.Text(
                'Pengesahan',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 54),
              pw.Container(height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('Nama & Paraf', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowItem {
  const _RowItem(this.label, this.value);

  final String label;
  final String value;
}
