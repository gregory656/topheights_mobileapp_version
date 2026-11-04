import 'package:sqflite/sqflite.dart';

import 'customer_profile.dart';
import 'local_database.dart';

class ProfileRepository {
  ProfileRepository({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase.instance;
  final LocalDatabase _localDatabase;

  Future<CustomerProfile> load() async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      'customer_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert('customer_profile', {
        'id': 1,
        'display_name': '',
        'business_name': '',
        'use_top_boss_greeting': 1,
        'created_at': now,
        'updated_at': now,
      });
      return const CustomerProfile(
        displayName: '',
        businessName: '',
        useTopBossGreeting: true,
      );
    }
    return CustomerProfile.fromMap(rows.first);
  }

  Future<void> save(CustomerProfile profile) async {
    final db = await _localDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'customer_profile',
        columns: ['created_at'],
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      await txn.insert('customer_profile', {
        ...profile.toMap(updatedAt: now),
        'created_at': existing.isEmpty ? now : existing.first['created_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> clearLocalProfile() async {
    final db = await _localDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('customer_profile');
      await txn.insert('customer_profile', {
        'id': 1,
        'display_name': '',
        'business_name': '',
        'use_top_boss_greeting': 1,
        'created_at': now,
        'updated_at': now,
      });
    });
  }
}
