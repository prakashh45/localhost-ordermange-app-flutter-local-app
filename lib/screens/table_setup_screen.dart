import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';

class TableSetupScreen extends StatefulWidget {
  const TableSetupScreen({super.key});

  @override
  State<TableSetupScreen> createState() => _TableSetupScreenState();
}

class _TableSetupScreenState extends State<TableSetupScreen> {
  List<RestaurantTable> tables = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await DatabaseService.instance.getAllTablesForManagement();
    if (!mounted) return;
    setState(() => tables = result);
  }

  Future<void> addTable() async {
    final name = await _askForName('Add Table');
    if (name == null) return;
    await _save(() => DatabaseService.instance.addTable(name));
  }

  Future<void> renameTable(RestaurantTable table) async {
    final name = await _askForName('Rename Table', initialValue: table.name);
    if (name == null) return;
    await _save(() => DatabaseService.instance.updateTable(table.id, name));
  }

  Future<void> deleteTable(RestaurantTable table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Delete ${table.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save(() => DatabaseService.instance.deleteTable(table.id));
  }

  Future<String?> _askForName(String title, {String? initialValue}) async {
    final controller = TextEditingController(text: initialValue);
    var isClosing = false;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final value = controller.text.trim();
            if (value.isEmpty || isClosing) return;
            isClosing = true;
            Navigator.of(dialogContext).pop(value);
          },
          decoration: const InputDecoration(
            hintText: 'Enter table name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isClosing
                ? null
                : () {
                    isClosing = true;
                    Navigator.of(dialogContext).pop();
                  },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: isClosing
                ? null
                : () {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    isClosing = true;
                    Navigator.of(dialogContext).pop(value);
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();

    final value = result?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Table Setup')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addTable,
          icon: const Icon(Icons.add),
          label: const Text('Add Table'),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: tables.length,
          itemBuilder: (_, index) {
            final table = tables[index];
            final isOpen = table.status == 'OPEN';
            return Card(
              child: ListTile(
                leading:
                    Icon(Icons.table_bar, color: isOpen ? Colors.red : accent),
                title: Text(table.name),
                subtitle: Text(isOpen ? 'OPEN' : 'FREE'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () => renameTable(table),
                        icon: const Icon(Icons.edit_outlined)),
                    IconButton(
                        onPressed: isOpen ? null : () => deleteTable(table),
                        icon: const Icon(Icons.delete_outline)),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
