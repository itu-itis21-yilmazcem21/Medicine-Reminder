import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'medicine_reminder.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicine(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        notes TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE schedule(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        time_of_day TEXT NOT NULL,
        days_mask INTEGER NOT NULL,
        FOREIGN KEY(medicine_id) REFERENCES medicine(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE intake_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        scheduled_at TEXT NOT NULL,
        taken_at TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY(medicine_id) REFERENCES medicine(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_intake_unique
      ON intake_log(medicine_id, scheduled_at);
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_intake_unique
        ON intake_log(medicine_id, scheduled_at);
      ''');
    }
  }

  Future<int> insertMedicine(Medicine m, List<ScheduleItem> schedules) async {
    final database = await db;
    return await database.transaction<int>((txn) async {
      final id = await txn.insert('medicine', m.toMap());
      for (final s in schedules) {
        await txn.insert('schedule', s.copyWith(medicineId: id).toMap());
      }
      return id;
    });
  }

  Future<void> updateMedicine(Medicine m, List<ScheduleItem> schedules) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.update('medicine', m.toMap(), where: 'id=?', whereArgs: [m.id]);
      await txn.delete('schedule', where: 'medicine_id=?', whereArgs: [m.id]);
      for (final s in schedules) {
        await txn.insert('schedule', s.copyWith(medicineId: m.id!).toMap());
      }
    });
  }

  Future<void> deleteMedicine(int id) async {
    final database = await db;
    await database.delete('medicine', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Medicine>> getMedicines() async {
    final database = await db;
    final list =
        await database.query('medicine', orderBy: 'name COLLATE NOCASE');
    return list.map(Medicine.fromMap).toList();
  }

  Future<List<ScheduleItem>> getSchedulesFor(int medicineId) async {
    final database = await db;
    final list = await database
        .query('schedule', where: 'medicine_id=?', whereArgs: [medicineId]);
    return list.map(ScheduleItem.fromMap).toList();
  }

  Future<void> ensurePendingLog(int medicineId, DateTime scheduledAt) async {
    final database = await db;
    final exists = await database.query(
      'intake_log',
      columns: ['id'],
      where: 'medicine_id=? AND scheduled_at=?',
      whereArgs: [medicineId, scheduledAt.toIso8601String()],
      limit: 1,
    );
    if (exists.isNotEmpty) return;
    await database.insert('intake_log', {
      'medicine_id': medicineId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': 'missed',
    });
  }

  Future<void> insertLog(IntakeLog log) async {
    final database = await db;
    await database.insert('intake_log', log.toMap());
  }

  Future<void> updateLogStatus(
    int medicineId,
    DateTime scheduledAt,
    String status, {
    DateTime? takenAt,
  }) async {
    final database = await db;
    final count = await database.update(
      'intake_log',
      {'status': status, 'taken_at': takenAt?.toIso8601String()},
      where: 'medicine_id=? AND scheduled_at=?',
      whereArgs: [medicineId, scheduledAt.toIso8601String()],
    );
    if (count == 0) {
      await insertLog(IntakeLog(
        medicineId: medicineId,
        scheduledAt: scheduledAt,
        takenAt: takenAt,
        status: status,
      ));
    }
  }

  Future<Map<String, int>> statsLast7Days() async {
    final database = await db;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final rows = await database.query('intake_log',
        where: 'scheduled_at >= ?',
        whereArgs: [sevenDaysAgo.toIso8601String()]);
    int taken = 0, missed = 0, snoozed = 0;
    for (final r in rows) {
      switch (r['status'] as String) {
        case 'taken':
          taken++;
          break;
        case 'missed':
          missed++;
          break;
        case 'snoozed':
          snoozed++;
          break;
      }
    }
    return {'taken': taken, 'missed': missed, 'snoozed': snoozed};
  }
}
