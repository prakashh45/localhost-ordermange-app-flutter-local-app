class RestaurantTable {
  final int id;
  final String name;
  final String status;
  final double runningTotal;
  final int activeCustomerCount;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.status,
    required this.runningTotal,
    required this.activeCustomerCount,
  });

  factory RestaurantTable.fromMap(Map<String, dynamic> m) => RestaurantTable(
        id: m['id'] as int,
        name: m['name'] as String,
        status: m['status'] as String,
        runningTotal: (m['running_total'] ?? 0).toDouble(),
        activeCustomerCount: (m['active_customer_count'] ?? 0) as int,
      );
}

class Customer {
  final int id;
  final int tableId;
  final String name;

  Customer({required this.id, required this.tableId, required this.name});

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as int,
        tableId: m['table_id'] as int,
        name: m['name'] as String,
      );
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> m) =>
      Category(id: m['id'] as int, name: m['name'] as String);
}

class Product {
  final int id;
  final int categoryId;
  final String name;
  final String unit;
  final double price;
  final double stock;
  final double lowStockAt;
  final bool active;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    required this.lowStockAt,
    required this.active,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int,
        categoryId: m['category_id'] as int,
        name: m['name'] as String,
        unit: m['unit'] as String,
        price: (m['price'] ?? 0).toDouble(),
        stock: (m['stock'] ?? 0).toDouble(),
        lowStockAt: (m['low_stock_at'] ?? 0).toDouble(),
        active: (m['active'] ?? 1) == 1,
      );
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String unit;
  final double price;
  final double qty;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.price,
    required this.qty,
  });

  double get amount => price * qty;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        id: m['id'] as int,
        productId: m['product_id'] as int,
        productName: m['product_name'] as String,
        unit: m['unit'] as String,
        price: (m['price'] ?? 0).toDouble(),
        qty: (m['qty'] ?? 0).toDouble(),
      );
}

class Bill {
  final int id;
  final int orderId;
  final String billNo;
  final String tableName;
  final String customerName;
  final String createdAt;
  final String finalizedAt;
  final double total;
  final String paymentMode;

  Bill({
    required this.id,
    required this.orderId,
    required this.billNo,
    required this.tableName,
    required this.customerName,
    required this.createdAt,
    required this.finalizedAt,
    required this.total,
    required this.paymentMode,
  });

  factory Bill.fromMap(Map<String, dynamic> m) => Bill(
        id: m['id'] as int,
        orderId: m['order_id'] as int,
        billNo: m['bill_no'] as String,
        tableName: m['table_name'] as String,
        customerName: m['customer_name'] as String,
        createdAt: m['created_at'] as String,
        finalizedAt: m['finalized_at'] as String,
        total: (m['total'] ?? 0).toDouble(),
        paymentMode: m['payment_mode'] as String,
      );

  String get dateTime => finalizedAt;
}
