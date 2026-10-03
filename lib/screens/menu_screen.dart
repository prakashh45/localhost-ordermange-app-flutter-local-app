import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/common.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Product> products = [];
  List<Category> categories = [];

  String search = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await DatabaseService.instance.getAllProductsForManagement();

    final c = await DatabaseService.instance.getCategories();

    if (!mounted) return;

    setState(() {
      products = p;
      categories = c;
    });
  }

  Future<void> addItem() async {
    final result = await showDialog(
      context: context,
      builder: (_) => ProductDialog(
        categories: categories,
      ),
    );

    if (result == true) {
      await load();
    }
  }

  Future<void> editItem(Product product) async {
    final result = await showDialog(
      context: context,
      builder: (_) => ProductDialog(
        categories: categories,
        product: product,
      ),
    );

    if (result == true) {
      await load();
    }
  }

  Future<void> deleteItem(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Item?'),
        content: Text(
          'Do you want to hide "${product.name}" from new orders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deactivateProduct(product.id);

      await load();
    }
  }

  Future<void> addStock(Product product) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Add Stock',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${product.name} • ${product.unit}',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final qty = double.tryParse(controller.text) ?? 0;

    if (qty <= 0) return;

    await DatabaseService.instance.addStock(product.id, qty);

    await load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Stock added successfully',
        ),
      ),
    );
  }

  Future<String?> _askForCategoryName({Category? category}) async {
    final controller = TextEditingController();
    controller.text = category?.name ?? '';
    var isClosing = false;
    var errorText = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (errorText.isNotEmpty) setDialogState(() => errorText = '');
            },
            decoration: InputDecoration(
              labelText: 'Category name',
              hintText: 'Example: Whisky',
              errorText: errorText.isEmpty ? null : errorText,
              prefixIcon: const Icon(Icons.category_outlined),
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
                          () => errorText = 'Category name is required',
                        );
                        return;
                      }
                      isClosing = true;
                      Navigator.of(dialogContext).pop(value);
                    },
              child: Text(category == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    return result?.trim().isEmpty == true ? null : result?.trim();
  }

  Future<void> addCategory() async {
    final name = await _askForCategoryName();
    if (name == null) return;

    try {
      await DatabaseService.instance.addCategory(name);

      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Category added successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  Future<void> editCategory(Category category) async {
    final name = await _askForCategoryName(category: category);
    if (name == null) return;

    try {
      await DatabaseService.instance.updateCategory(category.id, name);
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete ${category.name}?'),
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

    if (confirmed != true) return;

    try {
      await DatabaseService.instance.deleteCategory(category.id);
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) {
      return p.name.toLowerCase().contains(search.toLowerCase());
    }).toList();

    final activeProducts = products.where((p) => p.active).toList();

    final lowStock = activeProducts
        .where(
          (p) => p.stock > 0 && p.stock <= p.lowStockAt,
        )
        .length;

    final outOfStock = activeProducts.where((p) => p.stock <= 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu & Stock'),
        actions: [
          IconButton(
            tooltip: 'Add Category',
            onPressed: addCategory,
            icon: const Icon(
              Icons.category_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            14,
            14,
            14,
            100,
          ),
          children: [
            const SectionTitle(
              title: 'Menu Management',
              subtitle: 'Manage products, prices and inventory',
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search item...',
              ),
            ),
            const SizedBox(height: 14),
            if (categories.isNotEmpty) ...[
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map(
                      (category) => Container(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.black.withOpacity(.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category.name),
                            IconButton(
                              tooltip: 'Edit ${category.name}',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => editCategory(category),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Delete ${category.name}',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => deleteCategory(category),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.restaurant_menu,
                    title: 'Items',
                    value: '${activeProducts.length}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.warning_amber_rounded,
                    title: 'Low',
                    value: '$lowStock',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.remove_shopping_cart,
                    title: 'Out',
                    value: '$outOfStock',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${filtered.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...filtered.map(
              (product) => _ProductCard(
                product: product,
                onEdit: () => editItem(product),
                onDelete: () => deleteItem(product),
                onStock: () => addStock(product),
              ),
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No items found',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY
// ============================================================

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: primary,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRODUCT CARD
// ============================================================

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStock;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onStock,
  });

  @override
  Widget build(BuildContext context) {
    final out = product.stock <= 0;

    final low = !out && product.stock <= product.lowStockAt;

    final Color stockColor;

    if (out) {
      stockColor = Colors.red;
    } else if (low) {
      stockColor = Colors.orange;
    } else {
      stockColor = accent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              product.name.toLowerCase().contains('snack')
                  ? Icons.restaurant
                  : Icons.local_bar,
              color: primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.unit} • ${money(product.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  out
                      ? 'Out of stock'
                      : low
                          ? 'Low stock'
                          : 'Available',
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                out ? 'OUT' : '${product.stock.toStringAsFixed(0)} left',
                style: TextStyle(
                  color: stockColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: primary,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: onStock,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                    ),
                  ),
                  child: const Text(
                    '+ Stock',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD / EDIT PRODUCT DIALOG
// ============================================================

class ProductDialog extends StatefulWidget {
  final List<Category> categories;
  final Product? product;

  const ProductDialog({
    super.key,
    required this.categories,
    this.product,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController lowStockController;

  int? categoryId;

  String unit = '30ml';

  final units = [
    '30ml',
    '60ml',
    '90ml',
    '650ml',
    'Bottle',
    'Plate',
    'Glass',
    'Piece',
    'Pack',
  ];

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    nameController = TextEditingController(
      text: p?.name ?? '',
    );

    priceController = TextEditingController(
      text: p?.price.toStringAsFixed(0) ?? '',
    );

    stockController = TextEditingController(
      text: p?.stock.toStringAsFixed(0) ?? '0',
    );

    lowStockController = TextEditingController(
      text: p?.lowStockAt.toStringAsFixed(0) ?? '10',
    );

    categoryId = p?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);

    unit = p?.unit ?? '30ml';

    if (!units.contains(unit)) {
      unit = 'Piece';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    lowStockController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
        ),
      );
      return;
    }

    final price = double.tryParse(
          priceController.text,
        ) ??
        0;

    final stock = double.tryParse(
          stockController.text,
        ) ??
        0;

    final lowStock = double.tryParse(
          lowStockController.text,
        ) ??
        0;

    try {
      if (widget.product == null) {
        await DatabaseService.instance.addProduct(
          categoryId: categoryId!,
          name: nameController.text,
          unit: unit,
          price: price,
          stock: stock,
          lowStockAt: lowStock,
        );
      } else {
        await DatabaseService.instance.updateProduct(
          productId: widget.product!.id,
          categoryId: categoryId!,
          name: nameController.text,
          unit: unit,
          price: price,
          lowStockAt: lowStock,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;

    return AlertDialog(
      title: Text(
        editing ? 'Edit Item' : 'Add New Item',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'Example: Royal Stag',
                prefixIcon: Icon(Icons.local_bar),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  categoryId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: unit,
              decoration: const InputDecoration(
                labelText: 'Serving / Unit',
                prefixIcon: Icon(Icons.straighten),
              ),
              items: units
                  .map(
                    (u) => DropdownMenuItem<String>(
                      value: u,
                      child: Text(u),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  unit = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              enabled: !editing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Opening Stock',
                prefixIcon: Icon(Icons.inventory_2),
                helperText: 'For new items only',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lowStockController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Low Stock Alert At',
                prefixIcon: Icon(Icons.warning_amber),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save),
          label: Text(
            editing ? 'Update' : 'Save',
          ),
        ),
      ],
    );
  }
}
