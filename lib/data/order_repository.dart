import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class CartLine {
  const CartLine({required this.productId, required this.name, required this.quantity, required this.unitPriceMinor, required this.currency});
  final String productId, name, currency;
  final int quantity, unitPriceMinor;
  int get totalMinor => quantity * unitPriceMinor;
  factory CartLine.fromMap(Map<String, Object?> m) => CartLine(productId: m['product_id'] as String, name: m['product_name'] as String, quantity: m['quantity'] as int, unitPriceMinor: m['unit_price_minor'] as int, currency: m['currency'] as String);
}

class LocalOrder {
  const LocalOrder(this.id, this.reference, this.status, this.customerName, this.email, this.phone, this.address, this.preference, this.currency, this.subtotalMinor, this.createdAt, this.updatedAt, this.items);
  final String id, reference, status, customerName, email, phone, address, preference, currency, createdAt, updatedAt;
  final int subtotalMinor;
  final List<CartLine> items;
}

class OrderRepository {
  Future<Database> get _db async => LocalDatabase.instance.database;
  Future<List<CartLine>> cart() async => (await (await _db).query('cart_items', orderBy: 'added_at')).map(CartLine.fromMap).toList();
  Future<void> add(String id, String name, int? price) async {
    if (price == null) throw ArgumentError('A recorded price is needed to add this item.');
    if (price < 0) throw ArgumentError('Price cannot be negative.');
    final db = await _db, now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final rows = await txn.query('cart_items', where: 'product_id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) { await txn.insert('cart_items', {'product_id': id, 'product_name': name, 'quantity': 1, 'unit_price_minor': price, 'currency': 'KES', 'added_at': now, 'updated_at': now}); }
      else { await setQuantity(id, (rows.first['quantity'] as int) + 1, txn: txn); }
    });
  }
  Future<void> setQuantity(String id, int quantity, {Transaction? txn}) async {
    if (quantity < 1 || quantity > 999) throw ArgumentError('Quantity must be between 1 and 999.');
    final executor = txn ?? await _db;
    await executor.update('cart_items', {'quantity': quantity, 'updated_at': DateTime.now().toUtc().toIso8601String()}, where: 'product_id = ?', whereArgs: [id]);
  }
  Future<void> remove(String id) async => (await _db).delete('cart_items', where: 'product_id = ?', whereArgs: [id]);
  Future<List<LocalOrder>> orders() async {
    final db = await _db; final rows = await db.query('local_orders', orderBy: 'created_at DESC');
    return Future.wait(rows.map((r) async => _order(db, r)));
  }
  Future<LocalOrder> _order(DatabaseExecutor db, Map<String,Object?> r) async {
    final items = await db.query('local_order_items', where: 'order_id = ?', whereArgs: [r['id']]);
    return LocalOrder(r['id'] as String, r['reference'] as String, r['status'] as String, r['customer_name'] as String, r['email'] as String, r['phone'] as String, r['address'] as String, r['delivery_preference'] as String, r['currency'] as String, r['subtotal_minor'] as int, r['created_at'] as String, r['updated_at'] as String, items.map(CartLine.fromMap).toList());
  }
  Future<LocalOrder> saveOrder({required String name, required String email, required String phone, required String address, required String preference, required String status}) async {
    if (name.trim().isEmpty || phone.trim().isEmpty || address.trim().isEmpty) throw ArgumentError('Name, phone and delivery address are required.');
    final db = await _db; final id = DateTime.now().microsecondsSinceEpoch.toString();
    final ref = 'TH-${DateTime.now().toUtc().year}-${id.substring(id.length - 8).toUpperCase()}'; final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final lines = await txn.query('cart_items', orderBy: 'added_at');
      if (lines.isEmpty) throw StateError('Your cart is empty.');
      final subtotal = lines.fold<int>(0, (sum, l) => sum + (l['quantity'] as int) * (l['unit_price_minor'] as int));
      await txn.insert('local_orders', {'id': id, 'reference': ref, 'status': status, 'customer_name': name.trim(), 'email': email.trim(), 'phone': phone.trim(), 'address': address.trim(), 'delivery_preference': preference, 'currency': 'KES', 'subtotal_minor': subtotal, 'created_at': now, 'updated_at': now});
      for (final l in lines) { await txn.insert('local_order_items', {'order_id': id, 'product_id': l['product_id'], 'product_name': l['product_name'], 'quantity': l['quantity'], 'unit_price_minor': l['unit_price_minor'], 'currency': l['currency']}); }
      await txn.delete('cart_items');
    });
    return (await _order(db, (await db.query('local_orders', where: 'id = ?', whereArgs: [id])).first));
  }
  Future<void> changeStatus(String id, String status) async {
    if (!['Draft', 'Submitted locally', 'Cancelled'].contains(status)) throw ArgumentError('Invalid local order status.');
    await (await _db).update('local_orders', {'status': status, 'updated_at': DateTime.now().toUtc().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  }
}
