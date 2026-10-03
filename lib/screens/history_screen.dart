import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Bill> bills = [];
  DateTime selected = DateTime.now();
  final Set<int> _deletingBillIds = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await DatabaseService.instance.getBills(day: selected);
    if (mounted) setState(() => bills = x);
  }

  String formatTimestamp(String value) {
    return DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.parse(value));
  }

  Future<void> confirmDelete(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this bill?'),
        content: Text(
          '${bill.billNo}\n${bill.tableName} • ${money(bill.total)}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingBillIds.add(bill.id));
    try {
      await DatabaseService.instance.deleteBill(bill.id);
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _deletingBillIds.remove(bill.id));
    }
  }

  Future<void> confirmClearHistory() async {
    if (bills.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This will permanently delete finalized historical bills.\n\n'
          'Current drafts, tables, products, stock, and settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DatabaseService.instance.deleteAllHistory();
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = bills.fold(0.0, (s, b) => s + b.total);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            onPressed: bills.isEmpty ? null : confirmClearHistory,
            tooltip: 'Clear History',
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(DateFormat('dd MMM yyyy').format(selected)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: selected);
                if (d != null) {
                  setState(() => selected = d);
                  await load();
                }
              },
            ),
          ),
          Card(
              child: ListTile(
                  title: const Text('Total Sales'),
                  trailing: Text(money(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)))),
          ...bills.map(
            (b) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.billNo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(b.tableName),
                    Text('Customer: ${b.customerName}'),
                    const SizedBox(height: 6),
                    Text('Created: ${formatTimestamp(b.createdAt)}'),
                    Text('Finalized: ${formatTimestamp(b.finalizedAt)}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total: ${money(b.total)}\nPayment: ${b.paymentMode}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _deletingBillIds.contains(b.id)
                              ? null
                              : () => confirmDelete(b),
                          icon: _deletingBillIds.contains(b.id)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (bills.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child:
                    Center(child: Text('No finalized bills for this date.'))),
        ],
      ),
    );
  }
}
