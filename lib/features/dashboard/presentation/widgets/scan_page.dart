import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.title});

  final String title;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) {
            return;
          }
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code == null || code.isEmpty) {
            return;
          }
          _handled = true;
          Navigator.of(context).pop(code);
        },
      ),
    );
  }
}
