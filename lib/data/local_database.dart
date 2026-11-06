import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  static const _databaseName = 'top_heights_local.db';
  static const _databaseVersion = 3;
  Database? _database;

  Future<Database> get database async {
    if (_database case final db? when db.isOpen) return db;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async => openDatabase(
    await _resolvePath(),
    version: _databaseVersion,
    onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: _createSchema,
    onUpgrade: _upgradeSchema,
  );

  Future<String> _resolvePath() async {
    if (kIsWeb) return _databaseName;
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, _databaseName);
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''CREATE TABLE customer_profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      display_name TEXT NOT NULL DEFAULT '',
      business_name TEXT NOT NULL DEFAULT '',
      use_top_boss_greeting INTEGER NOT NULL DEFAULT 1 CHECK (use_top_boss_greeting IN (0, 1)),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE app_settings (
      setting_key TEXT PRIMARY KEY,
      setting_value TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert('customer_profile', {
      'id': 1,
      'display_name': '',
      'business_name': '',
      'use_top_boss_greeting': 1,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('app_settings', {
      'setting_key': 'local_demo_mode',
      'setting_value': 'true',
      'updated_at': now,
    });
    await _createCatalogue(db);
    await _createOrders(db);
  }

  Future<void> _createOrders(Database db) async {
    await db.execute('''CREATE TABLE cart_items (
      product_id TEXT PRIMARY KEY, product_name TEXT NOT NULL, quantity INTEGER NOT NULL CHECK(quantity > 0),
      unit_price_minor INTEGER NOT NULL CHECK(unit_price_minor >= 0), currency TEXT NOT NULL DEFAULT 'KES',
      added_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE local_orders (
      id TEXT PRIMARY KEY, reference TEXT NOT NULL UNIQUE, status TEXT NOT NULL CHECK(status IN ('Draft','Submitted locally','Cancelled')),
      customer_name TEXT NOT NULL, email TEXT NOT NULL, phone TEXT NOT NULL, address TEXT NOT NULL,
      delivery_preference TEXT NOT NULL, currency TEXT NOT NULL, subtotal_minor INTEGER NOT NULL,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE local_order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL REFERENCES local_orders(id) ON DELETE CASCADE,
      product_id TEXT NOT NULL, product_name TEXT NOT NULL, quantity INTEGER NOT NULL CHECK(quantity > 0),
      unit_price_minor INTEGER NOT NULL, currency TEXT NOT NULL
    )''');
    await db.execute('CREATE INDEX local_order_history_idx ON local_orders(created_at DESC)');
  }

  Future<void> _createCatalogue(Database db) async {
    await db.execute('''CREATE TABLE categories (
      id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE, description TEXT NOT NULL DEFAULT '',
      sort_order INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE products (
      id TEXT PRIMARY KEY, sku TEXT NOT NULL DEFAULT '', model TEXT NOT NULL DEFAULT '',
      name TEXT NOT NULL, category_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
      description TEXT NOT NULL DEFAULT '', price_minor INTEGER CHECK(price_minor IS NULL OR price_minor >= 0),
      stock_quantity INTEGER CHECK(stock_quantity IS NULL OR stock_quantity >= 0),
      availability TEXT NOT NULL DEFAULT 'unknown', professional_installation INTEGER NOT NULL DEFAULT 0,
      warranty TEXT NOT NULL DEFAULT '', image_ref TEXT NOT NULL DEFAULT '',
      specifications TEXT NOT NULL DEFAULT '{}', created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('CREATE INDEX products_name_idx ON products(name COLLATE NOCASE)');
    await db.execute('CREATE INDEX products_sku_idx ON products(sku COLLATE NOCASE)');
    await db.execute('CREATE INDEX products_category_idx ON products(category_id)');
    await db.execute('''CREATE TABLE product_favourites (
      product_id TEXT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE, created_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE recently_viewed (
      product_id TEXT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE, viewed_at TEXT NOT NULL
    )''');
    final now = DateTime.now().toUtc().toIso8601String();
    const names = ['Solar panels', 'Inverters', 'Batteries', 'Electrical equipment', 'Lighting', 'Solar heating & pumps', 'Efficiency products', 'Kits'];
    for (var i = 0; i < names.length; i++) {
      await db.insert('categories', {'id': 'cat_${i + 1}', 'name': names[i], 'sort_order': i, 'created_at': now, 'updated_at': now});
    }
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 1:
          await _createSchema(db, version);
        case 2:
          await _createCatalogue(db);
        case 3:
          await _createOrders(db);
      }
    }
  }
}
