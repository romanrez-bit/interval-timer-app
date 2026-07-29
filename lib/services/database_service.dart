import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/saved_timer.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'interval_timer.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создаём сразу все 3 таблицы из ТЗ (раздел 6),
    // хотя пока используем только saved_timers — чтобы не переделывать базу
    // отдельным шагом, когда дойдём до экранов Итога и Истории.
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_duration INTEGER NOT NULL,
        avg_rpe REAL,
        prep_seconds INTEGER NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        num_circuits INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE circuit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        circuit_number INTEGER NOT NULL,
        rpe REAL NOT NULL,
        extra_pause_seconds INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_timers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        prep_seconds INTEGER NOT NULL,
        num_circuits INTEGER NOT NULL,
        description_work TEXT NOT NULL DEFAULT '',
        description_rest TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<int> insertSavedTimer(SavedTimer timer) async {
    final db = await database;
    return db.insert('saved_timers', timer.toMap());
  }

  Future<List<SavedTimer>> getSavedTimers() async {
    final db = await database;
    final rows = await db.query('saved_timers', orderBy: 'id DESC');
    return rows.map((row) => SavedTimer.fromMap(row)).toList();
  }

  Future<int> updateSavedTimer(SavedTimer timer) async {
    final db = await database;
    return db.update('saved_timers', timer.toMap(),
        where: 'id = ?', whereArgs: [timer.id]);
  }

  Future<int> deleteSavedTimer(int id) async {
    final db = await database;
    return db.delete('saved_timers', where: 'id = ?', whereArgs: [id]);
  }
}