import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';
import 'add_order_screen.dart';
import 'final_bill_screen.dart';

class TableOrderScreen extends StatefulWidget {
  final RestaurantTable table;

  const TableOrderScreen({
    super.key,
    required this.table,
  });

  @override
  State<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends State<TableOrderScreen> {
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await DatabaseService.instance.getCustomers(widget.table.id);

    if (!mounted) return;

    setState(() {
      customers = x;
    });
  }

  Future<void> addCustomer() async {
    final controller = TextEditingController();
    var isClosing = false;
    const suggestions = [
      'Customer 1',
      'Customer 2',
      'Customer 3',
      'Customer 4',
      'Customer 5',
    ];

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var errorText = '';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: const Text('Add Customer'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (errorText.isNotEmpty) {
                          setDialogState(() => errorText = '');
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter customer name',
                        errorText: errorText.isEmpty ? null : errorText,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Quick Select',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions
                          .map(
                            (suggestion) => ActionChip(
                              label: Text(suggestion),
                              onPressed: () {
                                controller.text = suggestion;
                                controller.selection = TextSelection.collapsed(
                                  offset: controller.text.length,
                                );
                                setDialogState(() => errorText = '');
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
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
                        if (value.isEmpty) {
                          setDialogState(
                            () => errorText = 'Customer name is required',
                          );
                          return;
                        }

                        isClosing = true;
                        Navigator.of(dialogContext).pop(value);
                      },
                child: const Text('Start'),
              ),
            ],
          ),
        );
      },
    );

    // Let the dialog route finish detaching its TextField subtree first.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    await DatabaseService.instance.createCustomer(
      widget.table.id,
      name.trim(),
    );

    if (!mounted) return;

    await load();
  }

  Future<double> customerTotal(Customer customer) async {
    final orderId = await DatabaseService.instance.getDraftOrderId(
      customer.id,
    );

    if (orderId == null) return 0.0;

    final items = await DatabaseService.instance.getOrderItems(orderId);

    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  Future<void> openCustomer(Customer customer) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomerOrderScreen(
          table: widget.table,
          customer: customer,
        ),
      ),
    );

    if (!mounted) return;

    // Refresh table/customer data after returning.
    await load();

    if (result == true) {
      // Customer bill was completed.
      // Stay on TableOrderScreen so remaining customers can still be billed.
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.table.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('Customer'),
      ),
      body: customers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 70,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No active customer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: addCustomer,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Customer'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Text(
                  'Customers at ${widget.table.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Each customer has a separate draft. '
                  'Add more items anytime before final billing.',
                ),
                const SizedBox(height: 14),
                ...customers.map(
                  (customer) => FutureBuilder<double>(
                    future: customerTotal(customer),
                    builder: (_, snapshot) {
                      final total = snapshot.data ?? 0.0;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              customer.name.isEmpty
                                  ? '?'
                                  : customer.name[0].toUpperCase(),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Draft total: ${money(total)}',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: () => openCustomer(customer),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// CUSTOMER ORDER SCREEN
// ============================================================

class CustomerOrderScreen extends StatefulWidget {
  final RestaurantTable table;
  final Customer customer;

  const CustomerOrderScreen({
    super.key,
    required this.table,
    required this.customer,
  });

  @override
  State<CustomerOrderScreen> createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen> {
  int? orderId;
  List<OrderItem> items = [];

  final Set<int> _changingItemIds = {};

  bool _openingFinalBill = false;

  Future<void> cancelDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this draft?'),
        content: const Text(
          'This will remove the customer and all items in this draft. '
          'Nothing will be deducted from stock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Draft'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Draft'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await DatabaseService.instance.cancelDraft(widget.customer.id);

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final id = await DatabaseService.instance.getDraftOrderId(
      widget.customer.id,
    );

    List<OrderItem> loadedItems = [];

    if (id != null) {
      loadedItems = await DatabaseService.instance.getOrderItems(id);
    }

    if (!mounted) return;

    setState(() {
      orderId = id;
      items = loadedItems;
    });
  }

  double get total {
    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  Future<void> changeQuantity(
    OrderItem item,
    double delta,
  ) async {
    if (_changingItemIds.contains(item.id)) return;

    final nextQty = item.qty + delta;

    // Immediate UI update.
    setState(() {
      _changingItemIds.add(item.id);

      if (nextQty <= 0) {
        items = items.where((current) => current.id != item.id).toList();
      } else {
        items = items.map((current) {
          if (current.id != item.id) return current;

          return OrderItem(
            id: current.id,
            productId: current.productId,
            productName: current.productName,
            unit: current.unit,
            price: current.price,
            qty: nextQty,
          );
        }).toList();
      }
    });

    try {
      await DatabaseService.instance.changeQty(
        item.id,
        delta,
      );
    } catch (e) {
      // Reload from DB if something failed.
      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _changingItemIds.remove(item.id);
      });
    }
  }

  Future<void> openAddOrder() async {
    if (orderId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddOrderScreen(
          orderId: orderId!,
        ),
      ),
    );

    if (!mounted) return;

    await load();
  }

  Future<void> openFinalBill() async {
    if (orderId == null || total <= 0) return;

    if (_openingFinalBill) return;

    setState(() {
      _openingFinalBill = true;
    });

    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FinalBillScreen(
            table: widget.table,
            customer: widget.customer,
          ),
        ),
      );

      if (!mounted) return;

      // If the bill was successfully completed,
      // close CustomerOrderScreen and return to TableOrderScreen.
      if (result == true) {
        Navigator.of(context).pop(true);
        return;
      }

      // User came back without completing the bill.
      await load();
    } finally {
      if (mounted) {
        setState(() {
          _openingFinalBill = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            onPressed: cancelDraft,
            tooltip: 'Cancel Draft',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No items yet. Tap Add Order.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final changing = _changingItemIds.contains(item.id);

                      return Card(
                        child: ListTile(
                          title: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.unit} • ${money(item.price)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: changing
                                    ? null
                                    : () => changeQuantity(
                                          item,
                                          -1,
                                        ),
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                              ),
                              SizedBox(
                                width: 28,
                                child: Center(
                                  child: Text(
                                    item.qty % 1 == 0
                                        ? item.qty.toInt().toString()
                                        : item.qty.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: changing
                                    ? null
                                    : () => changeQuantity(
                                          item,
                                          1,
                                        ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                money(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Running Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        money(total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: orderId == null ? null : openAddOrder,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Order'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: total <= 0 || _openingFinalBill
                              ? null
                              : openFinalBill,
                          icon: _openingFinalBill
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.receipt_long,
                                ),
                          label: Text(
                            _openingFinalBill ? 'Opening...' : 'Final Bill',
                          ),
                        ),
                      ),
                    ],
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
