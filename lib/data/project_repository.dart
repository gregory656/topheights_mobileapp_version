import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// Local-only quote, site visit and project records. No method sends data away.
class ProjectRepository {
  Future<Database> get _db => LocalDatabase.instance.database;
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  String _now() => DateTime.now().toUtc().toIso8601String();

  Future<List<Map<String, Object?>>> assessments() async =>
      (await (await _db).query(
            'energy_assessments',
            orderBy: 'updated_at DESC',
          ))
          .map((r) => {...r, 'payload': jsonDecode(r['payload'] as String)})
          .toList();

  Future<List<Map<String, Object?>>> products() async =>
      (await (await _db).query(
        'products',
        orderBy: 'name COLLATE NOCASE',
      )).toList();

  Future<List<Map<String, Object?>>> quotes() async {
    final db = await _db;
    final rows = await db.query('quote_drafts', orderBy: 'updated_at DESC');
    return Future.wait(
      rows.map((r) async {
        final versions = await db.query(
          'quote_versions',
          where: 'quote_id = ?',
          whereArgs: [r['id']],
          orderBy: 'version DESC',
        );
        return {
          ...r,
          'versions': versions
              .map(
                (v) => {
                  'version': v['version'],
                  'created_at': v['created_at'],
                  'snapshot': jsonDecode(v['snapshot'] as String),
                },
              )
              .toList(),
        };
      }),
    );
  }

  Future<void> saveQuote({
    String? id,
    required String title,
    required String? assessmentId,
    required Map<String, Object?> snapshot,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Add a quote name.');
    final db = await _db;
    final now = _now();
    await db.transaction((txn) async {
      if (id == null) {
        final key = _id();
        await txn.insert('quote_drafts', {
          'id': key,
          'assessment_id': assessmentId,
          'title': title.trim(),
          'current_version': 1,
          'status': 'Draft saved locally',
          'created_at': now,
          'updated_at': now,
        });
        await txn.insert('quote_versions', {
          'quote_id': key,
          'version': 1,
          'snapshot': jsonEncode(snapshot),
          'created_at': now,
        });
      } else {
        final existing = await txn.query(
          'quote_drafts',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (existing.isEmpty) {
          throw StateError('This quote is no longer available.');
        }
        final version = (existing.first['current_version'] as int) + 1;
        await txn.insert('quote_versions', {
          'quote_id': id,
          'version': version,
          'snapshot': jsonEncode(snapshot),
          'created_at': now,
        });
        await txn.update(
          'quote_drafts',
          {
            'assessment_id': assessmentId,
            'title': title.trim(),
            'current_version': version,
            'status': 'Draft saved locally',
            'accepted_at': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> recordQuoteAction(String id, String status) async {
    final db = await _db;
    final now = _now();
    final values = <String, Object?>{'status': status, 'updated_at': now};
    if (status == 'Accepted locally — pending business review') {
      values['accepted_at'] = now;
    }
    await db.transaction((txn) async {
      final rows = await txn.query(
        'quote_drafts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final version = rows.first['current_version'] as int;
      final snapshots = await txn.query(
        'quote_versions',
        where: 'quote_id = ? AND version = ?',
        whereArgs: [id, version],
        limit: 1,
      );
      if (snapshots.isNotEmpty) {
        final snapshot =
            jsonDecode(snapshots.first['snapshot'] as String)
                as Map<String, Object?>;
        snapshot['recordedStatus'] = status;
        snapshot['statusRecordedAt'] = now;
        await txn.update(
          'quote_versions',
          {'snapshot': jsonEncode(snapshot)},
          where: 'quote_id = ? AND version = ?',
          whereArgs: [id, version],
        );
      }
      await txn.update(
        'quote_drafts',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Map<String, Object?>>> visitRequests() async =>
      (await (await _db).query(
            'site_visit_requests',
            orderBy: 'updated_at DESC',
          ))
          .map(
            (r) => {
              ...r,
              'preferred_windows': jsonDecode(r['preferred_windows'] as String),
            },
          )
          .toList();

  Future<String> saveVisit({
    required String? assessmentId,
    required String contact,
    required String phone,
    required String email,
    required String address,
    required String notes,
    required String access,
    required List<String> windows,
  }) async {
    if (contact.trim().isEmpty ||
        phone.trim().isEmpty ||
        address.trim().isEmpty ||
        windows.isEmpty) {
      throw ArgumentError(
        'Add a contact name, phone, site address and at least one preferred window.',
      );
    }
    final id = _id(), now = _now();
    await (await _db).insert('site_visit_requests', {
      'id': id,
      'assessment_id': assessmentId,
      'preferred_windows': jsonEncode(windows),
      'contact_name': contact.trim(),
      'contact_phone': phone.trim(),
      'contact_email': email.trim(),
      'address': address.trim(),
      'site_notes': notes.trim(),
      'access_constraints': access.trim(),
      'status': 'Request saved locally — not sent',
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<List<Map<String, Object?>>> projects() async {
    final db = await _db;
    final rows = await db.query('projects', orderBy: 'updated_at DESC');
    return Future.wait(
      rows.map((r) async {
        final milestones = await db.query(
          'project_milestones',
          where: 'project_id = ?',
          whereArgs: [r['id']],
          orderBy: 'sort_order',
        );
        final events = await db.query(
          'project_events',
          where: 'project_id = ?',
          whereArgs: [r['id']],
          orderBy: 'created_at DESC',
        );
        final docs = await db.query(
          'project_documents',
          where: 'project_id = ?',
          whereArgs: [r['id']],
          orderBy: 'created_at DESC',
        );
        final quoteId = r['quote_id'] as String?;
        final quote = quoteId == null
            ? <String, Object?>{}
            : await _quoteSnapshot(db, quoteId);
        final assessmentId = r['assessment_id'] as String?;
        final assessmentRows = assessmentId == null
            ? <Map<String, Object?>>[]
            : await db.query(
                'energy_assessments',
                where: 'id = ?',
                whereArgs: [assessmentId],
                limit: 1,
              );
        final assessment = assessmentRows.isEmpty
            ? <String, Object?>{}
            : {
                ...assessmentRows.first,
                'payload': jsonDecode(
                  assessmentRows.first['payload'] as String,
                ),
              };
        return {
          ...r,
          'milestones': milestones,
          'events': events,
          'documents': docs,
          'quote': quote,
          'assessment': assessment,
        };
      }),
    );
  }

  Future<Map<String, Object?>> _quoteSnapshot(
    DatabaseExecutor db,
    String quoteId,
  ) async {
    final quotes = await db.query(
      'quote_drafts',
      where: 'id = ?',
      whereArgs: [quoteId],
      limit: 1,
    );
    if (quotes.isEmpty) return {};
    final versions = await db.query(
      'quote_versions',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'version DESC',
      limit: 1,
    );
    return {
      ...quotes.first,
      'snapshot': versions.isEmpty
          ? <String, Object?>{}
          : jsonDecode(versions.first['snapshot'] as String),
    };
  }

  Future<String> createProject({
    required String title,
    String? quoteId,
    String? requestId,
    String? assessmentId,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Add a project name.');
    final db = await _db, id = _id(), now = _now();
    await db.transaction((txn) async {
      await txn.insert('projects', {
        'id': id,
        'quote_id': quoteId,
        'request_id': requestId,
        'assessment_id': assessmentId,
        'title': title.trim(),
        'status': 'Planned locally',
        'created_at': now,
        'updated_at': now,
      });
      const defaults = ['Assessment', 'Quote review', 'Site work', 'Handover'];
      for (var i = 0; i < defaults.length; i++) {
        final state = i == 0 ? 'Requested' : 'Planned locally';
        await txn.insert('project_milestones', {
          'id': _id(),
          'project_id': id,
          'title': defaults[i],
          'state': state,
          'sort_order': i,
          'created_at': now,
          'updated_at': now,
        });
      }
      await txn.insert('project_events', {
        'id': _id(),
        'project_id': id,
        'event_type': 'Project created',
        'summary': 'Project created and planned locally.',
        'created_at': now,
      });
    });
    return id;
  }

  Future<void> updateMilestone(
    String projectId,
    String milestoneId,
    String title,
    String details,
    String state,
    String targetDate,
  ) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Milestone name is required.');
    }
    final db = await _db, now = _now();
    await db.transaction((txn) async {
      final before = await txn.query(
        'project_milestones',
        where: 'id = ?',
        whereArgs: [milestoneId],
      );
      if (before.isEmpty) return;
      await txn.update(
        'project_milestones',
        {
          'title': title.trim(),
          'details': details.trim(),
          'state': state,
          'target_date': targetDate.trim(),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [milestoneId],
      );
      await txn.update(
        'projects',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [projectId],
      );
      await txn.insert('project_events', {
        'id': _id(),
        'project_id': projectId,
        'event_type': 'Milestone updated',
        'summary':
            '${title.trim()}: ${before.first['state']} → $state${targetDate.trim().isEmpty ? '' : ' · target ${targetDate.trim()}'}',
        'created_at': now,
      });
    });
  }

  Future<void> setProjectStatus(String projectId, String status) async {
    final db = await _db, now = _now();
    await db.transaction((txn) async {
      await txn.update(
        'projects',
        {'status': status, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [projectId],
      );
      await txn.insert('project_events', {
        'id': _id(),
        'project_id': projectId,
        'event_type': 'Project status changed',
        'summary': 'Project status set to $status.',
        'created_at': now,
      });
    });
  }

  Future<void> addDocument(
    String projectId,
    String name,
    String kind,
    String reference,
  ) async {
    if (name.trim().isEmpty) throw ArgumentError('Document name is required.');
    final now = _now();
    await (await _db).insert('project_documents', {
      'id': _id(),
      'project_id': projectId,
      'name': name.trim(),
      'kind': kind,
      'reference': reference.trim(),
      'created_at': now,
    });
  }

  Future<void> deleteDocument(String id) async =>
      (await _db).delete('project_documents', where: 'id = ?', whereArgs: [id]);
}
