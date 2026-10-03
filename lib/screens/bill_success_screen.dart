import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';
import '../widgets/common.dart';
import 'pdf_preview_screen.dart';

class BillSuccessScreen extends StatelessWidget {
  final Bill bill;
  final List<OrderItem> items;

  const BillSuccessScreen({
    super.key,
    required this.bill,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Completed'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: const Color(0xFFE2F9EB),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    child: Icon(Icons.check, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bill Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Bill No: ${bill.billNo}'),
                  Text('Table: ${bill.tableName}'),
                  Text('Customer: ${bill.customerName}'),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${money(bill.total)}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Payment: ${bill.paymentMode}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =========================
          // VIEW PDF
          // =========================
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfPreviewScreen(
                    billNo: bill.billNo,
                    generatePdf: () {
                      return PdfService.generateBillPdf(
                        restaurant: 'Gavthan Bar and Restro',
                        bill: bill,
                        items: items,
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('VIEW PDF BILL'),
          ),

          const SizedBox(height: 10),

          // =========================
          // THERMAL PRINT
          // =========================
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await PdfService.printThermalBill(
                  restaurant: 'Gavthan Bar and Restro',
                  bill: bill,
                  items: items,
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Printer error: $e'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('PRINT THERMAL BILL'),
          ),

          const SizedBox(height: 18),

          // =========================
          // BACK TO TABLES
          // =========================
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.table_bar),
            label: const Text('BACK TO TABLES'),
          ),
        ],
      ),
    );
  }
}
