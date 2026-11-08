import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'energy_calculator.dart';
import 'local_database.dart';

class AppliancePreset {
  const AppliancePreset(this.id, this.name, this.watts, this.basis);
  final String id, name;
  final int watts;
  final WattageBasis basis;
  factory AppliancePreset.fromMap(Map<String, Object?> m) => AppliancePreset(
    m['id'] as String,
    m['name'] as String,
    m['watts'] as int,
    WattageBasis.values.firstWhere(
      (v) => v.name == m['basis'],
      orElse: () => WattageBasis.illustrativeDefault,
    ),
  );
}

class SavedAssessment {
  const SavedAssessment({
    required this.id,
    required this.name,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, name, createdAt, updatedAt;
  final Map<String, Object?> payload;
  List<EnergyLoad> get loads => ((payload['loads'] as List?) ?? [])
      .map((e) => EnergyLoad.fromJson(Map<String, Object?>.from(e as Map)))
      .toList();
  factory SavedAssessment.fromMap(Map<String, Object?> m) => SavedAssessment(
    id: m['id'] as String,
    name: m['name'] as String,
    payload: Map<String, Object?>.from(
      jsonDecode(m['payload'] as String) as Map,
    ),
    createdAt: m['created_at'] as String,
    updatedAt: m['updated_at'] as String,
  );
}

class EnergyRepository {
  Future<Database> get _db async => LocalDatabase.instance.database;
  Future<List<AppliancePreset>> presets() async => (await (await _db).query(
    'appliance_library',
    orderBy: 'name COLLATE NOCASE',
  )).map(AppliancePreset.fromMap).toList();
  Future<void> savePreset(AppliancePreset preset) async {
    if (preset.name.trim().isEmpty ||
        preset.watts < 1 ||
        preset.watts > 100000) {
      throw ArgumentError('Enter a name and a wattage from 1 to 100,000 W.');
    }
    final db = await _db, now = DateTime.now().toUtc().toIso8601String();
    final existing = await db.query(
      'appliance_library',
      columns: ['created_at'],
      where: 'id = ?',
      whereArgs: [preset.id],
    );
    await db.insert('appliance_library', {
      'id': preset.id,
      'name': preset.name.trim(),
      'watts': preset.watts,
      'basis': preset.basis.name,
      'created_at': existing.isEmpty ? now : existing.first['created_at'],
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePreset(String id) async =>
      (await _db).delete('appliance_library', where: 'id = ?', whereArgs: [id]);
  Future<List<SavedAssessment>> assessments() async => (await (await _db).query(
    'energy_assessments',
    orderBy: 'updated_at DESC',
  )).map(SavedAssessment.fromMap).toList();
  Future<void> save({
    String? id,
    required String name,
    required Map<String, Object?> payload,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Give this scenario a name.');
    }
    final db = await _db,
        now = DateTime.now().toUtc().toIso8601String(),
        key = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final existing = id == null
        ? <Map<String, Object?>>[]
        : await db.query(
            'energy_assessments',
            columns: ['created_at'],
            where: 'id = ?',
            whereArgs: [id],
          );
    await db.insert('energy_assessments', {
      'id': key,
      'name': name.trim(),
      'payload': jsonEncode(payload),
      'created_at': existing.isEmpty ? now : existing.first['created_at'],
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async => (await _db).delete(
    'energy_assessments',
    where: 'id = ?',
    whereArgs: [id],
  );
}
