import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Bill> bills = [];
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _normalizeDates();
    load();
  }

  void _normalizeDates() {
    startDate = DateTime(startDate.year, startDate.month, startDate.day);
    endDate = DateTime(endDate.year, endDate.month, endDate.day);
  }

  Future<void> load() async {
    final all = await DatabaseService.instance.getAllBills();
    final from = DateTime(startDate.year, startDate.month, startDate.day);
    final until = DateTime(endDate.year, endDate.month, endDate.day + 1);
    final x = all.where((b) {
      final d = DateTime.parse(b.finalizedAt);
      return !d.isBefore(from) && d.isBefore(until);
    }).toList();
    if (mounted) setState(() => bills = x);
  }

  Future<void> chooseDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: start ? startDate : endDate,
    );
    if (picked == null || !mounted) return;

    final value = DateTime(picked.year, picked.month, picked.day);
    if (start && value.isAfter(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date cannot be after end date')),
      );
      return;
    }
    if (!start && value.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }

    setState(() {
      if (start) {
        startDate = value;
      } else {
        endDate = value;
      }
    });
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final total = bills.fold(0.0, (s, b) => s + b.total);
    final cash = bills
        .where((b) => b.paymentMode == 'Cash')
        .fold(0.0, (s, b) => s + b.total);
    final upi = bills
        .where((b) => b.paymentMode == 'UPI')
        .fold(0.0, (s, b) => s + b.total);
    final card = bills
        .where((b) => b.paymentMode == 'Card')
        .fold(0.0, (s, b) => s + b.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Revenue Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => chooseDate(start: true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label:
                              Text(DateFormat('dd MMM yyyy').format(startDate)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => chooseDate(start: false),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label:
                              Text(DateFormat('dd MMM yyyy').format(endDate)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
              child: ListTile(
                  title: const Text('Revenue'),
                  trailing: Text(money(total),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)))),
          Row(children: [
            Expanded(
                child: StatCard(
                    title: 'Cash',
                    value: money(cash),
                    icon: Icons.money,
                    background: softGreen)),
            const SizedBox(width: 8),
            Expanded(
                child: StatCard(
                    title: 'UPI',
                    value: money(upi),
                    icon: Icons.qr_code,
                    background: softBlue)),
          ]),
          const SizedBox(height: 8),
          StatCard(
              title: 'Card',
              value: money(card),
              icon: Icons.credit_card,
              background: const Color(0xFFFFF5D9)),
          const SizedBox(height: 14),
          Text('${bills.length} finalized bills',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ...bills.map((b) => ListTile(
                title: Text(b.billNo),
                subtitle: Text(
                    '${b.tableName} • ${b.customerName} • ${DateFormat('dd MMM, hh:mm a').format(DateTime.parse(b.dateTime))}'),
                trailing: Text(money(b.total)),
              )),
        ],
      ),
    );
  }
}
