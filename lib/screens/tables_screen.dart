import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';
import 'table_order_screen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});
  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<RestaurantTable> tables = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await DatabaseService.instance.getTables();
    if (mounted) setState(() => tables = x);
  }

  Future<void> openTable(RestaurantTable table) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => TableOrderScreen(table: table)));
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tables')),
        body: RefreshIndicator(
          onRefresh: load,
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: tables.length,
            itemBuilder: (_, i) {
              final t = tables[i];
              final open = t.status == 'OPEN';
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => openTable(t),
                child: Card(
                  elevation: 0,
                  color:
                      open ? const Color(0xFFFFE2E2) : const Color(0xFFDDF8E8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_bar,
                            size: 30,
                            color: open ? Colors.red.shade700 : accent),
                        const SizedBox(height: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t.name,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(open ? 'OPEN' : 'FREE',
                            style: TextStyle(
                                color: open
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w700)),
                        if (open) ...[
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '👥 ${t.activeCustomerCount} '
                              '${t.activeCustomerCount == 1 ? 'Customer' : 'Customers'}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money(t.runningTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
