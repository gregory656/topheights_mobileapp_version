import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  static const _databaseName = 'top_heights_local.db';
  static const _databaseVersion = 5;
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
    await _createEnergyStudio(db);
    await _createProjects(db);
  }

  Future<void> _createProjects(Database db) async {
    await db.execute('''CREATE TABLE quote_drafts (
      id TEXT PRIMARY KEY, assessment_id TEXT, title TEXT NOT NULL,
      current_version INTEGER NOT NULL DEFAULT 1, status TEXT NOT NULL DEFAULT 'Draft saved locally',
      accepted_at TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE quote_versions (
      quote_id TEXT NOT NULL REFERENCES quote_drafts(id) ON DELETE CASCADE,
      version INTEGER NOT NULL, snapshot TEXT NOT NULL, created_at TEXT NOT NULL,
      PRIMARY KEY(quote_id, version)
    )''');
    await db.execute('''CREATE TABLE site_visit_requests (
      id TEXT PRIMARY KEY, assessment_id TEXT, project_id TEXT, preferred_windows TEXT NOT NULL,
      contact_name TEXT NOT NULL, contact_phone TEXT NOT NULL, contact_email TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL, site_notes TEXT NOT NULL DEFAULT '', access_constraints TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'Request saved locally', created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE projects (
      id TEXT PRIMARY KEY, quote_id TEXT, request_id TEXT, assessment_id TEXT,
      title TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Planned locally',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE project_milestones (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
      title TEXT NOT NULL, details TEXT NOT NULL DEFAULT '', state TEXT NOT NULL DEFAULT 'Planned locally',
      target_date TEXT NOT NULL DEFAULT '', sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE project_events (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
      event_type TEXT NOT NULL, summary TEXT NOT NULL, created_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE project_documents (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
      name TEXT NOT NULL, kind TEXT NOT NULL, reference TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL
    )''');
    await db.execute(
      'CREATE INDEX quote_history_idx ON quote_drafts(updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX project_history_idx ON projects(updated_at DESC)',
    );
  }

  Future<void> _createEnergyStudio(Database db) async {
    await db.execute('''CREATE TABLE appliance_library (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, watts INTEGER NOT NULL CHECK(watts > 0),
      basis TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE energy_assessments (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, payload TEXT NOT NULL,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )''');
    await db.execute(
      'CREATE INDEX energy_assessment_history_idx ON energy_assessments(updated_at DESC)',
    );
    final now = DateTime.now().toUtc().toIso8601String();
    const starters = [
      ['light', 'LED light', 9],
      ['fan', 'Ceiling fan', 75],
      ['router', 'Wi-Fi router', 12],
      ['tv', 'Television', 100],
      ['fridge', 'Refrigerator', 150],
      ['laptop', 'Laptop', 65],
      ['pump', 'Water pump', 750],
      ['kettle', 'Electric kettle', 1500],
    ];
    for (final item in starters) {
      await db.insert('appliance_library', {
        'id': item[0],
        'name': item[1],
        'watts': item[2],
        'basis': 'illustrative_default',
        'created_at': now,
        'updated_at': now,
      });
    }
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
    await db.execute(
      'CREATE INDEX local_order_history_idx ON local_orders(created_at DESC)',
    );
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
    await db.execute(
      'CREATE INDEX products_name_idx ON products(name COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX products_sku_idx ON products(sku COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX products_category_idx ON products(category_id)',
    );
    await db.execute('''CREATE TABLE product_favourites (
      product_id TEXT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE, created_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE recently_viewed (
      product_id TEXT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE, viewed_at TEXT NOT NULL
    )''');
    final now = DateTime.now().toUtc().toIso8601String();
    const names = [
      'Solar panels',
      'Inverters',
      'Batteries',
      'Electrical equipment',
      'Lighting',
      'Solar heating & pumps',
      'Efficiency products',
      'Kits',
    ];
    for (var i = 0; i < names.length; i++) {
      await db.insert('categories', {
        'id': 'cat_${i + 1}',
        'name': names[i],
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
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
        case 4:
          await _createEnergyStudio(db);
        case 5:
          await _createProjects(db);
      }
    }
  }
}
