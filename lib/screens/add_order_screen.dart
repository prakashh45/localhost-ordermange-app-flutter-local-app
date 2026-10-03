import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AddOrderScreen extends StatefulWidget {
  final int orderId;
  const AddOrderScreen({super.key, required this.orderId});
  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  List<Category> cats = [];
  List<Product> products = [];
  Map<int, OrderItem> cartItems = {};
  String? selected;
  final Set<int> _addingProductIds = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final c = await DatabaseService.instance.getCategories();
    final p = await DatabaseService.instance.getProducts(category: selected);
    final items = await DatabaseService.instance.getOrderItems(widget.orderId);
    if (mounted)
      setState(() {
        cats = c;
        products = p;
        cartItems = {for (final item in items) item.productId: item};
      });
  }

  Future<void> changeItemQuantity(Product product, double delta) async {
    final current = cartItems[product.id];
    if (delta < 0 && current == null) return;
    if (_addingProductIds.contains(product.id)) return;

    setState(() => _addingProductIds.add(product.id));
    try {
      if (delta > 0) {
        await DatabaseService.instance.addItem(widget.orderId, product);
      } else {
        await DatabaseService.instance.changeQty(current!.id, delta);
      }
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingProductIds.remove(product.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Order')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                onChanged: (q) async {
                  final all = await DatabaseService.instance
                      .getProducts(category: selected);
                  if (mounted)
                    setState(() => products = all
                        .where((p) =>
                            p.name.toLowerCase().contains(q.toLowerCase()))
                        .toList());
                },
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search), hintText: 'Search item...'),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  ChoiceChip(
                      label: const Text('All'),
                      selected: selected == null,
                      onSelected: (_) {
                        setState(() => selected = null);
                        load();
                      }),
                  const SizedBox(width: 8),
                  ...cats.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                            label: Text(c.name),
                            selected: selected == c.name,
                            onSelected: (_) {
                              setState(() => selected = c.name);
                              load();
                            }),
                      )),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final p = products[i];
                  final out = p.stock <= 0;
                  final item = cartItems[p.id];
                  final quantity = item?.qty ?? 0;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: const Icon(Icons.local_bar)),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${p.unit} • ₹${p.price.toStringAsFixed(0)} • Stock ${p.stock.toStringAsFixed(0)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: quantity == 0 ||
                                    _addingProductIds.contains(p.id)
                                ? null
                                : () => changeItemQuantity(p, -1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          SizedBox(
                            width: 24,
                            child: Text(
                              quantity % 1 == 0
                                  ? quantity.toInt().toString()
                                  : quantity.toStringAsFixed(1),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: out || _addingProductIds.contains(p.id)
                                ? null
                                : () => changeItemQuantity(p, 1),
                            icon: const Icon(Icons.add_circle,
                                color: Colors.blue, size: 32),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}
