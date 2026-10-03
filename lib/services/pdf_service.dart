import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

class PdfService {
  // ============================================================
  // NORMAL BILL PDF
  // ============================================================

  static Future<Uint8List> generateBillPdf({
    required String restaurant,
    required Bill bill,
    required List<OrderItem> items,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                restaurant,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Bar and Restro',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BILL',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  bill.billNo,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(bill.dateTime))}',
            ),
            pw.Text('Table: ${bill.tableName}'),
            pw.Text('Customer: ${bill.customerName}'),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              cellPadding: const pw.EdgeInsets.all(7),
              headers: const [
                'Item',
                'Qty',
                'Rate',
                'Amount',
              ],
              data: items.map((item) {
                final qty = item.qty % 1 == 0
                    ? item.qty.toInt().toString()
                    : item.qty.toStringAsFixed(2);

                return [
                  '${item.productName} (${item.unit})',
                  qty,
                  'Rs. ${item.price.toStringAsFixed(2)}',
                  'Rs. ${item.amount.toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Rs. ${bill.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Payment: ${bill.paymentMode}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 35),
            pw.Center(
              child: pw.Text(
                'Thank you for visiting Gavthan Bar and Restro',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  // ============================================================
  // PDF PREVIEW / PRINT / SHARE
  // ============================================================

  static Future<void> printBill({
    required String restaurant,
    required Bill bill,
    required List<OrderItem> items,
  }) async {
    final bytes = await generateBillPdf(
      restaurant: restaurant,
      bill: bill,
      items: items,
    );

    await Printing.layoutPdf(
      name: 'Bill-${bill.billNo}',
      onLayout: (format) async => bytes,
    );
  }

  // ============================================================
  // SHARE PDF
  // ============================================================

  static Future<void> shareBill({
    required String restaurant,
    required Bill bill,
    required List<OrderItem> items,
  }) async {
    final bytes = await generateBillPdf(
      restaurant: restaurant,
      bill: bill,
      items: items,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Bill-${bill.billNo}.pdf',
    );
  }

  // ============================================================
  // THERMAL RECEIPT
  // ============================================================

  static Future<Uint8List> _buildThermalPdf({
    required String restaurant,
    required Bill bill,
    required List<OrderItem> items,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          164,
          560,
          marginAll: 8,
        ),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  restaurant,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Bar and Restro',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Bill: ${bill.billNo}'),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(bill.dateTime))}',
              ),
              pw.Text('Table: ${bill.tableName}'),
              pw.Text('Customer: ${bill.customerName}'),
              pw.Divider(),
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.productName,
                        maxLines: 1,
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${item.qty % 1 == 0 ? item.qty.toInt() : item.qty} x ${item.price.toStringAsFixed(0)}',
                          ),
                          pw.Text(
                            item.amount.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rs. ${bill.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Text('Payment: ${bill.paymentMode}'),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you!',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ============================================================
  // THERMAL PRINT
  // ============================================================

  static Future<void> printThermalBill({
    required String restaurant,
    required Bill bill,
    required List<OrderItem> items,
  }) async {
    final bytes = await _buildThermalPdf(
      restaurant: restaurant,
      bill: bill,
      items: items,
    );

    await Printing.layoutPdf(
      name: 'Thermal-${bill.billNo}',
      onLayout: (_) async => bytes,
    );
  }
}
