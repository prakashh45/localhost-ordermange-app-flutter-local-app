import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String billNo;
  final Future<Uint8List> Function() generatePdf;

  const PdfPreviewScreen({
    super.key,
    required this.billNo,
    required this.generatePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill $billNo'),
      ),
      body: PdfPreview(
        build: (format) async {
          return await generatePdf();
        },
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: true,
        canChangeOrientation: false,
        pdfFileName: 'Bill-$billNo.pdf',
        actions: const [],
      ),
    );
  }
}
