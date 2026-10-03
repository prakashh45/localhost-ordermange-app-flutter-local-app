import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  static const _requiredTables = [
    'tables',
    'customers',
    'categories',
    'products',
    'orders',
    'order_items',
    'payments',
    'stock_transactions',
  ];

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'gavthan_bar_restro.db'),
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<String> get databasePath async {
    final dir = await getDatabasesPath();
    return join(dir, 'gavthan_bar_restro.db');
  }

  Future<Map<String, int>> getDatabaseCounts() async {
    final d = await db;
    final counts = <String, int>{};
    for (final table in [
      'tables',
      'products',
      'customers',
      'orders',
      'payments',
    ]) {
      final result = await d.rawQuery('SELECT COUNT(*) AS count FROM $table');
      counts[table] = (result.first['count'] as num).toInt();
    }
    return counts;
  }

  Future<void> close() async {
    final current = _db;
    _db = null;
    await current?.close();
  }

  Future<bool> validateBackupFile(String path) async {
    if (!await File(path).exists()) return false;
    Database? backup;
    try {
      backup = await openDatabase(path, readOnly: true);
      final rows = await backup.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = rows.map((row) => row['name'] as String).toSet();
      return _requiredTables.every(names.contains);
    } catch (_) {
      return false;
    } finally {
      await backup?.close();
    }
  }

  Future<File> createDatabaseBackup(String destinationPath) async {
    final current = await db;
    await current.rawQuery('PRAGMA wal_checkpoint(FULL)');
    final source = File(await databasePath);
    if (!await source.exists()) throw Exception('Database is not available');
    return source.copy(destinationPath);
  }

  Future<void> restoreDatabase(String backupPath) async {
    if (!await validateBackupFile(backupPath)) {
      throw Exception('This file is not a valid Gavthan database backup');
    }

    final targetPath = await databasePath;
    final rollbackPath = '$targetPath.restore_backup';
    final target = File(targetPath);
    final rollback = File(rollbackPath);

    await close();
    try {
      if (await target.exists()) await target.copy(rollbackPath);
      await File(backupPath).copy(targetPath);
      await db;
      if (await rollback.exists()) await rollback.delete();
    } catch (error) {
      if (await rollback.exists()) {
        await rollback.copy(targetPath);
      }
      await close();
      await db;
      throw Exception('Restore failed: $error');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tables(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'FREE',
        running_total REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        stock REAL NOT NULL DEFAULT 0,
        low_stock_at REAL NOT NULL DEFAULT 5,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        created_at TEXT NOT NULL,
        closed_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty REAL NOT NULL,
        price REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        bill_no TEXT NOT NULL,
        mode TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        order_id INTEGER,
        type TEXT NOT NULL,
        qty REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    for (var i = 1; i <= 8; i++) {
      await db.insert('tables', {'name': 'Table $i'});
    }

    final categoryIds = <String, int>{};
    for (final name in ['Whisky', 'Beer', 'Food', 'Beverages', 'Soft Drinks']) {
      categoryIds[name] = await db.insert('categories', {'name': name});
    }

    final seed = [
      ['Royal Stag', 'Whisky', '30ml', 120.0, 80.0],
      ['Royal Stag', 'Whisky', '60ml', 240.0, 60.0],
      ['Royal Stag', 'Whisky', '90ml', 360.0, 40.0],
      ['Blender Pride', 'Whisky', '30ml', 140.0, 50.0],
      ['Blender Pride', 'Whisky', '60ml', 280.0, 40.0],
      ['Blender Pride', 'Whisky', '90ml', 420.0, 30.0],
      ['Beer', 'Beer', '650ml', 180.0, 70.0],
      ['Snacks (Plate)', 'Food', 'Plate', 150.0, 100.0],
      ['Water Bottle', 'Beverages', 'Bottle', 30.0, 100.0],
      ['Cold Drink', 'Soft Drinks', 'Bottle', 60.0, 80.0],
    ];

    for (final x in seed) {
      await db.insert('products', {
        'category_id': categoryIds[x[1] as String],
        'name': x[0],
        'unit': x[2],
        'price': x[3],
        'stock': x[4],
        'low_stock_at': 10,
      });
      await db.insert('stock_transactions', {
        'product_id': await db
            .rawQuery('SELECT last_insert_rowid()')
            .then((r) => r.first.values.first),
        'type': 'OPENING',
        'qty': x[4],
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE stock_transactions ADD COLUMN order_id INTEGER',
      );
    }
  }

  Future<List<RestaurantTable>> getTables() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT t.*, COALESCE(SUM(oi.qty * oi.price),0) running_total,
             COUNT(DISTINCT o.customer_id) active_customer_count
      FROM tables t
      LEFT JOIN orders o ON o.table_id=t.id AND o.status='DRAFT'
      LEFT JOIN order_items oi ON oi.order_id=o.id
      GROUP BY t.id ORDER BY t.id
    ''');
    return rows.map(RestaurantTable.fromMap).toList();
  }

  Future<List<Customer>> getCustomers(int tableId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT c.* FROM customers c
      JOIN orders o ON o.customer_id=c.id
      WHERE c.table_id=? AND o.status='DRAFT'
      GROUP BY c.id ORDER BY c.id
    ''', [tableId]);
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> createCustomer(int tableId, String name) async {
    final d = await db;
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Customer name is required');
    }

    return d.transaction((txn) async {
      final id = await txn.insert('customers', {
        'table_id': tableId,
        'name': cleanName,
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.insert('orders', {
        'table_id': tableId,
        'customer_id': id,
        'status': 'DRAFT',
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.update('tables', {'status': 'OPEN'},
          where: 'id=?', whereArgs: [tableId]);
      return id;
    });
  }

  Future<int?> getDraftOrderId(int customerId) async {
    final d = await db;
    final rows = await d.query('orders',
        where: 'customer_id=? AND status=?',
        whereArgs: [customerId, 'DRAFT'],
        limit: 1);
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<void> cancelDraft(int customerId) async {
    final d = await db;
    await d.transaction((txn) async {
      final rows = await txn.query(
        'orders',
        columns: ['id', 'table_id'],
        where: 'customer_id=? AND status=?',
        whereArgs: [customerId, 'DRAFT'],
        limit: 1,
      );

      if (rows.isEmpty) return;

      final orderId = rows.first['id'] as int;
      final tableId = rows.first['table_id'] as int;

      await txn.delete(
        'order_items',
        where: 'order_id=?',
        whereArgs: [orderId],
      );
      await txn.delete('orders', where: 'id=?', whereArgs: [orderId]);
      await txn.delete('customers', where: 'id=?', whereArgs: [customerId]);

      final open = await txn.rawQuery(
        "SELECT COUNT(*) AS count FROM orders WHERE table_id=? AND status='DRAFT'",
        [tableId],
      );
      if ((open.first['count'] as int) == 0) {
        await txn.update(
          'tables',
          {'status': 'FREE', 'running_total': 0},
          where: 'id=?',
          whereArgs: [tableId],
        );
      }
    });
  }

  Future<List<Product>> getProducts({String? category}) async {
    final d = await db;
    final rows = category == null
        ? await d.rawQuery(
            'SELECT * FROM products WHERE active=1 ORDER BY name, unit')
        : await d.rawQuery('''
          SELECT p.* FROM products p JOIN categories c ON c.id=p.category_id
          WHERE p.active=1 AND c.name=? ORDER BY p.name,p.unit
        ''', [category]);
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Category>> getCategories() async {
    final d = await db;
    final rows = await d.query('categories', orderBy: 'id');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT oi.*, p.name product_name, p.unit
      FROM order_items oi JOIN products p ON p.id=oi.product_id
      WHERE oi.order_id=? ORDER BY oi.id
    ''', [orderId]);
    return rows.map(OrderItem.fromMap).toList();
  }

  Future<void> addItem(int orderId, Product product) async {
    final d = await db;
    await d.transaction((txn) async {
      final orderRows = await txn.query(
        'orders',
        columns: ['id', 'status'],
        where: 'id=?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (orderRows.isEmpty || orderRows.first['status'] != 'DRAFT') {
        throw Exception('This order is no longer editable');
      }

      final productRows = await txn.query(
        'products',
        columns: ['name', 'stock'],
        where: 'id=? AND active=1',
        whereArgs: [product.id],
        limit: 1,
      );
      if (productRows.isEmpty) throw Exception('Item is no longer available');

      final stock = (productRows.first['stock'] as num).toDouble();
      final existing = await txn.query(
        'order_items',
        where: 'order_id=? AND product_id=? AND price=?',
        whereArgs: [orderId, product.id, product.price],
        limit: 1,
      );
      final currentQty =
          existing.isEmpty ? 0.0 : (existing.first['qty'] as num).toDouble();

      if (currentQty + 1 > stock) {
        throw Exception('${productRows.first['name']} stock is insufficient');
      }

      if (existing.isEmpty) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': product.id,
          'qty': 1,
          'price': product.price,
        });
      } else {
        await txn.update(
          'order_items',
          {'qty': currentQty + 1},
          where: 'id=?',
          whereArgs: [existing.first['id']],
        );
      }
    });
  }

  Future<void> changeQty(int itemId, double delta) async {
    final d = await db;
    await d.transaction((txn) async {
      final rows = await txn.rawQuery('''
        SELECT oi.qty, oi.order_id, p.name, p.stock, o.status
        FROM order_items oi
        JOIN products p ON p.id=oi.product_id
        JOIN orders o ON o.id=oi.order_id
        WHERE oi.id=?
      ''', [itemId]);
      if (rows.isEmpty) return;
      if (rows.first['status'] != 'DRAFT') {
        throw Exception('This order is no longer editable');
      }

      final current = (rows.first['qty'] as num).toDouble();
      final next = current + delta;
      final stock = (rows.first['stock'] as num).toDouble();
      if (next > stock) {
        throw Exception('${rows.first['name']} stock is insufficient');
      }

      if (next <= 0) {
        await txn.delete('order_items', where: 'id=?', whereArgs: [itemId]);
      } else {
        await txn.update(
          'order_items',
          {'qty': next},
          where: 'id=?',
          whereArgs: [itemId],
        );
      }
    });
  }

  Future<Map<String, dynamic>> finalizeOrder(
      int orderId, String mode, String billNo) async {
    final d = await db;
    return d.transaction((txn) async {
      final orderRows = await txn.query('orders',
          where: 'id=?', whereArgs: [orderId], limit: 1);
      if (orderRows.isEmpty) throw Exception('Draft order not found');
      final order = orderRows.first;
      if (order['status'] != 'DRAFT') {
        throw Exception('This order has already been finalized');
      }
      final itemRows = await txn.rawQuery('''
        SELECT oi.*, p.name product_name, p.stock
        FROM order_items oi JOIN products p ON p.id=oi.product_id
        WHERE oi.order_id=?
      ''', [orderId]);
      if (itemRows.isEmpty) throw Exception('Add at least one item');

      double total = 0;
      for (final row in itemRows) {
        final qty = (row['qty'] as num).toDouble();
        final stock = (row['stock'] as num).toDouble();
        if (stock < qty)
          throw Exception('${row['product_name']} stock is insufficient');
        total += qty * (row['price'] as num).toDouble();
      }

      final now = DateTime.now().toIso8601String();
      await txn.update('orders', {'status': 'CLOSED', 'closed_at': now},
          where: 'id=?', whereArgs: [orderId]);
      await txn.insert('payments', {
        'order_id': orderId,
        'bill_no': billNo,
        'mode': mode,
        'amount': total,
        'paid_at': now,
      });

      for (final row in itemRows) {
        final qty = (row['qty'] as num).toDouble();
        final productId = row['product_id'] as int;
        final changed = await txn.rawUpdate(
          'UPDATE products SET stock=stock-? WHERE id=? AND stock>=?',
          [qty, productId, qty],
        );
        if (changed != 1) {
          throw Exception('${row['product_name']} stock is insufficient');
        }
        await txn.insert('stock_transactions', {
          'product_id': productId,
          'order_id': orderId,
          'type': 'SALE',
          'qty': -qty,
          'created_at': now,
        });
      }

      final open = await txn.rawQuery(
          "SELECT COUNT(*) c FROM orders WHERE table_id=? AND status='DRAFT'",
          [order['table_id']]);
      if ((open.first['c'] as int) == 0) {
        await txn.update('tables', {'status': 'FREE', 'running_total': 0},
            where: 'id=?', whereArgs: [order['table_id']]);
      }
      return {
        'total': total,
        'tableId': order['table_id'],
        'customerId': order['customer_id']
      };
    });
  }

  Future<Map<String, dynamic>> todaySummary() async {
    final d = await db;
    final start =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .toIso8601String();
    final row = (await d.rawQuery('''
      SELECT COUNT(*) bills, COALESCE(SUM(amount),0) sales
      FROM payments WHERE paid_at>=?
    ''', [start])).first;
    final open =
        (await d.rawQuery("SELECT COUNT(*) c FROM tables WHERE status='OPEN'"))
            .first['c'] as int;
    final draft =
        (await d.rawQuery("SELECT COUNT(*) c FROM orders WHERE status='DRAFT'"))
            .first['c'] as int;
    final low = (await d.rawQuery(
            'SELECT COUNT(*) c FROM products WHERE active=1 AND stock<=low_stock_at'))
        .first['c'] as int;
    return {
      'bills': row['bills'] ?? 0,
      'sales': ((row['sales'] ?? 0) as num).toDouble(),
      'open': open,
      'draft': draft,
      'low': low,
    };
  }

  Future<List<Bill>> getBills({DateTime? day}) async {
    final d = await db;
    final target = day ?? DateTime.now();
    final start =
        DateTime(target.year, target.month, target.day).toIso8601String();
    final end =
        DateTime(target.year, target.month, target.day + 1).toIso8601String();
    final rows = await d.rawQuery('''
      SELECT pay.id, pay.order_id, pay.bill_no, t.name table_name,
              c.name customer_name, o.created_at created_at,
              o.closed_at finalized_at,
             pay.amount total, pay.mode payment_mode
      FROM payments pay
      JOIN orders o ON o.id=pay.order_id
      JOIN tables t ON t.id=o.table_id
      JOIN customers c ON c.id=o.customer_id
      WHERE pay.paid_at>=? AND pay.paid_at<?
      ORDER BY pay.id DESC
    ''', [start, end]);
    return rows.map(Bill.fromMap).toList();
  }

  Future<List<Bill>> getAllBills() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT pay.id, pay.order_id, pay.bill_no, t.name table_name,
              c.name customer_name, o.created_at created_at,
              o.closed_at finalized_at,
             pay.amount total, pay.mode payment_mode
      FROM payments pay
      JOIN orders o ON o.id=pay.order_id
      JOIN tables t ON t.id=o.table_id
      JOIN customers c ON c.id=o.customer_id
      ORDER BY pay.id DESC
    ''');
    return rows.map(Bill.fromMap).toList();
  }

  Future<void> deleteBill(int paymentId) async {
    final d = await db;
    await d.transaction((txn) async {
      final rows = await txn.rawQuery('''
        SELECT pay.order_id, o.customer_id, o.status
        FROM payments pay
        JOIN orders o ON o.id=pay.order_id
        WHERE pay.id=?
      ''', [paymentId]);

      if (rows.isEmpty) throw Exception('Bill not found');
      if (rows.first['status'] != 'CLOSED') {
        throw Exception('Only finalized bills can be deleted');
      }

      final orderId = rows.first['order_id'] as int;
      final customerId = rows.first['customer_id'] as int;

      await txn.delete(
        'stock_transactions',
        where: 'order_id=? AND type=?',
        whereArgs: [orderId, 'SALE'],
      );
      await txn.delete('payments', where: 'id=?', whereArgs: [paymentId]);
      await txn
          .delete('order_items', where: 'order_id=?', whereArgs: [orderId]);
      await txn.delete('orders', where: 'id=?', whereArgs: [orderId]);
      await txn.delete('customers', where: 'id=?', whereArgs: [customerId]);
    });
  }

  Future<void> deleteAllHistory() async {
    final d = await db;
    await d.transaction((txn) async {
      final closedOrders = await txn.query(
        'orders',
        columns: ['id', 'customer_id'],
        where: 'status=?',
        whereArgs: ['CLOSED'],
      );

      for (final order in closedOrders) {
        final orderId = order['id'] as int;
        await txn.delete(
          'stock_transactions',
          where: 'order_id=? AND type=?',
          whereArgs: [orderId, 'SALE'],
        );
        await txn.delete('payments', where: 'order_id=?', whereArgs: [orderId]);
        await txn
            .delete('order_items', where: 'order_id=?', whereArgs: [orderId]);
        await txn.delete('orders', where: 'id=?', whereArgs: [orderId]);
        await txn.delete(
          'customers',
          where: 'id=?',
          whereArgs: [order['customer_id']],
        );
      }
    });
  }

  Future<void> addStock(int productId, double qty) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.rawUpdate(
          'UPDATE products SET stock=stock+? WHERE id=?', [qty, productId]);
      await txn.insert('stock_transactions', {
        'product_id': productId,
        'type': 'RESTOCK',
        'qty': qty,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // ============================================================
// ITEM MANAGEMENT
// ============================================================

  Future<int> addCategory(String name) async {
    final d = await db;

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Category name is required');
    }

    try {
      return await d.insert(
        'categories',
        {
          'name': cleanName,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw Exception('Category already exists');
    }
  }

  Future<void> updateCategory(
    int categoryId,
    String name,
  ) async {
    final d = await db;

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Category name is required');
    }

    final existing = await d.query(
      'categories',
      where: 'LOWER(name)=LOWER(?) AND id!=?',
      whereArgs: [cleanName, categoryId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('Category already exists');
    }

    await d.update(
      'categories',
      {
        'name': cleanName,
      },
      where: 'id=?',
      whereArgs: [categoryId],
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final d = await db;

    final products = await d.query(
      'products',
      where: 'category_id=?',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (products.isNotEmpty) {
      throw Exception(
        'This category has items. Move or deactivate those items first.',
      );
    }

    await d.delete(
      'categories',
      where: 'id=?',
      whereArgs: [categoryId],
    );
  }

  Future<int> addProduct({
    required int categoryId,
    required String name,
    required String unit,
    required double price,
    required double stock,
    required double lowStockAt,
  }) async {
    final d = await db;

    if (name.trim().isEmpty) {
      throw Exception('Item name is required');
    }

    if (unit.trim().isEmpty) {
      throw Exception('Unit / serving size is required');
    }

    if (price <= 0) {
      throw Exception('Price must be greater than 0');
    }

    if (stock < 0) {
      throw Exception('Stock cannot be negative');
    }

    final id = await d.insert(
      'products',
      {
        'category_id': categoryId,
        'name': name.trim(),
        'unit': unit.trim(),
        'price': price,
        'stock': stock,
        'low_stock_at': lowStockAt,
        'active': 1,
      },
    );

    if (stock > 0) {
      await d.insert(
        'stock_transactions',
        {
          'product_id': id,
          'type': 'OPENING',
          'qty': stock,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }

    return id;
  }

  Future<void> updateProduct({
    required int productId,
    required int categoryId,
    required String name,
    required String unit,
    required double price,
    required double lowStockAt,
  }) async {
    final d = await db;

    if (name.trim().isEmpty) {
      throw Exception('Item name is required');
    }

    if (unit.trim().isEmpty) {
      throw Exception('Unit / serving size is required');
    }

    if (price <= 0) {
      throw Exception('Price must be greater than 0');
    }

    await d.update(
      'products',
      {
        'category_id': categoryId,
        'name': name.trim(),
        'unit': unit.trim(),
        'price': price,
        'low_stock_at': lowStockAt,
      },
      where: 'id=?',
      whereArgs: [productId],
    );
  }

  Future<void> deactivateProduct(int productId) async {
    final d = await db;

    await d.update(
      'products',
      {
        'active': 0,
      },
      where: 'id=?',
      whereArgs: [productId],
    );
  }

  Future<void> reactivateProduct(int productId) async {
    final d = await db;

    await d.update(
      'products',
      {
        'active': 1,
      },
      where: 'id=?',
      whereArgs: [productId],
    );
  }

  Future<List<Product>> getAllProductsForManagement() async {
    final d = await db;

    final rows = await d.query(
      'products',
      orderBy: 'name ASC, unit ASC',
    );

    return rows.map(Product.fromMap).toList();
  }
// ============================================================
// TABLE MANAGEMENT
// ============================================================

  Future<List<RestaurantTable>> getAllTablesForManagement() async {
    final d = await db;

    final rows = await d.query(
      'tables',
      orderBy: 'id ASC',
    );

    return rows.map(RestaurantTable.fromMap).toList();
  }

  Future<int> addTable(String name) async {
    final d = await db;

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Table name is required');
    }

    // Prevent duplicate table names.
    final existing = await d.query(
      'tables',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [cleanName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('A table with this name already exists');
    }

    return await d.insert(
      'tables',
      {
        'name': cleanName,
        'status': 'FREE',
      },
    );
  }

  Future<void> updateTable(
    int tableId,
    String name,
  ) async {
    final d = await db;

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Table name is required');
    }

    final existing = await d.query(
      'tables',
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [cleanName, tableId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('A table with this name already exists');
    }

    await d.update(
      'tables',
      {
        'name': cleanName,
      },
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  Future<void> deleteTable(int tableId) async {
    final d = await db;

    final tableRows = await d.query(
      'tables',
      where: 'id = ?',
      whereArgs: [tableId],
      limit: 1,
    );

    if (tableRows.isEmpty) {
      throw Exception('Table not found');
    }

    final table = tableRows.first;

    final status = table['status']?.toString() ?? 'FREE';

    // Never delete an active table.
    if (status == 'OPEN') {
      throw Exception(
        'This table is currently open. Finish the active order before deleting it.',
      );
    }

    // Check for unfinished orders.
    final activeOrders = await d.query(
      'orders',
      where: 'table_id = ? AND status = ?',
      whereArgs: [tableId, 'DRAFT'],
      limit: 1,
    );

    if (activeOrders.isNotEmpty) {
      throw Exception(
        'This table has a draft order. Finish or cancel the order first.',
      );
    }

    await d.delete(
      'tables',
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }
}
