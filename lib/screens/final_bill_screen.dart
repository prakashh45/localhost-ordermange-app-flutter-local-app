import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';
import 'bill_success_screen.dart';

class FinalBillScreen extends StatefulWidget {
  final RestaurantTable table;
  final Customer customer;
  const FinalBillScreen(
      {super.key, required this.table, required this.customer});
  @override
  State<FinalBillScreen> createState() => _FinalBillScreenState();
}

class _FinalBillScreenState extends State<FinalBillScreen> {
  String mode = 'Cash';
  List<OrderItem> items = [];
  int? orderId;
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final id =
        await DatabaseService.instance.getDraftOrderId(widget.customer.id);
    if (id != null) {
      final x = await DatabaseService.instance.getOrderItems(id);
      if (mounted)
        setState(() {
          orderId = id;
          items = x;
        });
    }
  }

  double get total => items.fold(0, (s, i) => s + i.amount);

  Future<void> complete() async {
    if (orderId == null || _isFinalizing) return;

    setState(() {
      _isFinalizing = true;
    });

    final billNo =
        'GBR-${DateFormat('yyyyMMdd-HHmmssSSS').format(DateTime.now())}-$orderId';

    try {
      // Finalize exactly once.
      await DatabaseService.instance.finalizeOrder(
        orderId!,
        mode,
        billNo,
      );

      final bills = await DatabaseService.instance.getAllBills();

      final bill = bills.firstWhere(
        (b) => b.billNo == billNo,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BillSuccessScreen(
            bill: bill,
            items: items,
          ),
        ),
      );

      if (!mounted) return;

      // Return to CustomerOrderScreen.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFinalizing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Final Bill - ${widget.table.name}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                        child: Text('Gavthan Bar and Restro',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 4),
                    Center(
                        child: Text(
                            '${widget.table.name} • ${widget.customer.name}')),
                    const Divider(),
                    ...items.map((x) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${x.productName} (${x.unit})'),
                          leading: Text('${x.qty.toInt()}'),
                          trailing: Text(money(x.amount)),
                        )),
                    const Divider(),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(money(total),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Payment Mode',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'Cash',
                    label: Text('Cash'),
                    icon: Icon(Icons.money)),
                ButtonSegment(
                    value: 'UPI',
                    label: Text('UPI'),
                    icon: Icon(Icons.qr_code)),
                ButtonSegment(
                    value: 'Card',
                    label: Text('Card'),
                    icon: Icon(Icons.credit_card)),
              ],
              selected: {mode},
              onSelectionChanged: (v) => setState(() => mode = v.first),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: accent, padding: const EdgeInsets.all(16)),
              onPressed: _isFinalizing ? null : complete,
              icon: _isFinalizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(_isFinalizing ? 'Finalizing...' : 'Complete Bill'),
            ),
          ],
        ),
      );
}
