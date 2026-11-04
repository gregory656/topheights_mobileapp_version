import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class CatalogueCategory {
  const CatalogueCategory(this.id, this.name, this.description);
  final String id, name, description;
  factory CatalogueCategory.fromMap(Map<String, Object?> row) => CatalogueCategory(row['id'] as String, row['name'] as String, row['description'] as String? ?? '');
}

class CatalogueProduct {
  const CatalogueProduct({required this.id, required this.name, required this.categoryId, required this.sku, required this.model, required this.description, required this.priceMinor, required this.stock, required this.availability, required this.installation, required this.warranty, required this.imageRef, required this.specifications, this.favourite = false});
  final String id, name, categoryId, sku, model, description, availability, warranty, imageRef;
  final int? priceMinor, stock;
  final bool installation, favourite;
  final Map<String, String> specifications;
  factory CatalogueProduct.fromMap(Map<String, Object?> row) => CatalogueProduct(id: row['id'] as String, name: row['name'] as String, categoryId: row['category_id'] as String? ?? '', sku: row['sku'] as String? ?? '', model: row['model'] as String? ?? '', description: row['description'] as String? ?? '', priceMinor: row['price_minor'] as int?, stock: row['stock_quantity'] as int?, availability: row['availability'] as String? ?? 'unknown', installation: row['professional_installation'] == 1, warranty: row['warranty'] as String? ?? '', imageRef: row['image_ref'] as String? ?? '', specifications: (jsonDecode(row['specifications'] as String? ?? '{}') as Map).map((k, v) => MapEntry(k.toString(), v.toString())), favourite: row['favourite'] == 1);
  Map<String, Object?> toMap() => {'id': id, 'name': name.trim(), 'category_id': categoryId.isEmpty ? null : categoryId, 'sku': sku.trim(), 'model': model.trim(), 'description': description.trim(), 'price_minor': priceMinor, 'stock_quantity': stock, 'availability': availability, 'professional_installation': installation ? 1 : 0, 'warranty': warranty.trim(), 'image_ref': imageRef.trim(), 'specifications': jsonEncode(specifications)};
}

class CatalogueRepository {
  Future<Database> get _db => LocalDatabase.instance.database;
  Future<List<CatalogueCategory>> categories() async => (await (await _db).query('categories', orderBy: 'sort_order, name')).map(CatalogueCategory.fromMap).toList();
  Future<List<CatalogueProduct>> products({String query = '', String categoryId = '', bool favouritesOnly = false, String availability = '', String sort = 'name'}) async {
    final db = await _db;
    final args = <Object?>[];
    final clauses = <String>[];
    if (categoryId.isNotEmpty) { clauses.add('p.category_id = ?'); args.add(categoryId); }
    if (favouritesOnly) clauses.add('f.product_id IS NOT NULL');
    if (availability.isNotEmpty) { clauses.add('p.availability = ?'); args.add(availability); }
    if (query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      clauses.add('(p.name LIKE ? OR p.sku LIKE ? OR p.model LIKE ? OR p.description LIKE ? OR p.specifications LIKE ?)');
      args.addAll([q, q, q, q, q]);
    }
    final order = sort == 'price' ? 'p.price_minor IS NULL, p.price_minor, p.name COLLATE NOCASE' : sort == 'newest' ? 'p.created_at DESC' : 'p.name COLLATE NOCASE';
    final rows = await db.rawQuery('SELECT p.*, f.product_id IS NOT NULL AS favourite FROM products p LEFT JOIN product_favourites f ON f.product_id=p.id ${clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}'} ORDER BY $order', args);
    return rows.map(CatalogueProduct.fromMap).toList();
  }
  Future<void> saveProduct(CatalogueProduct p) async {
    if (p.name.trim().isEmpty) throw ArgumentError('Product name is required.');
    if (p.priceMinor != null && p.priceMinor! < 0 || p.stock != null && p.stock! < 0) throw ArgumentError('Price and stock cannot be negative.');
    final db = await _db; final now = DateTime.now().toUtc().toIso8601String(); final values = p.toMap()..['updated_at'] = now;
    final exists = await db.query('products', columns: ['id'], where: 'id = ?', whereArgs: [p.id]);
    if (exists.isEmpty) { values['created_at'] = now; await db.insert('products', values); } else { await db.update('products', values, where: 'id = ?', whereArgs: [p.id]); }
  }
  Future<void> deleteProduct(String id) async => (await _db).delete('products', where: 'id = ?', whereArgs: [id]);
  Future<void> toggleFavourite(CatalogueProduct p) async { final db = await _db; if (p.favourite) { await db.delete('product_favourites', where: 'product_id = ?', whereArgs: [p.id]); } else { await db.insert('product_favourites', {'product_id': p.id, 'created_at': DateTime.now().toUtc().toIso8601String()}); } }
  Future<void> markViewed(String id) async { final db = await _db; await db.insert('recently_viewed', {'product_id': id, 'viewed_at': DateTime.now().toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<CatalogueProduct>> recentlyViewed() async { final db = await _db; final rows = await db.rawQuery('SELECT p.*, f.product_id IS NOT NULL AS favourite FROM recently_viewed r JOIN products p ON p.id=r.product_id LEFT JOIN product_favourites f ON f.product_id=p.id ORDER BY r.viewed_at DESC LIMIT 8'); return rows.map(CatalogueProduct.fromMap).toList(); }
  Future<void> saveCategory(CatalogueCategory category) async { if (category.name.trim().isEmpty) throw ArgumentError('Category name is required.'); final db = await _db; final now = DateTime.now().toUtc().toIso8601String(); final values = {'name': category.name.trim(), 'description': category.description.trim(), 'updated_at': now}; final exists = await db.query('categories', columns: ['id'], where: 'id = ?', whereArgs: [category.id]); if (exists.isEmpty) { await db.insert('categories', {'id': category.id, ...values, 'sort_order': 99, 'created_at': now}); } else { await db.update('categories', values, where: 'id = ?', whereArgs: [category.id]); } }
  Future<void> deleteCategory(String id) async => (await _db).delete('categories', where: 'id = ?', whereArgs: [id]);
}
