import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/saved_timer.dart';
import '../models/workout.dart';

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
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        total_duration INTEGER NOT NULL,
        avg_rpe REAL,
        prep_seconds INTEGER NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        num_circuits INTEGER NOT NULL,
        completed_circuits INTEGER NOT NULL DEFAULT 0,
        total_extra_pause_seconds INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE circuit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        circuit_number INTEGER NOT NULL,
        rpe REAL,
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

  /// Обновление структуры базы у тех, у кого уже стоит старая версия.
  /// Сохранённые шаблоны при этом не теряются.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS circuit_logs');
      await db.execute('DROP TABLE IF EXISTS workouts');
      await db.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL DEFAULT '',
          date TEXT NOT NULL,
          total_duration INTEGER NOT NULL,
          avg_rpe REAL,
          prep_seconds INTEGER NOT NULL,
          work_seconds INTEGER NOT NULL,
          rest_seconds INTEGER NOT NULL,
          num_circuits INTEGER NOT NULL,
          completed_circuits INTEGER NOT NULL DEFAULT 0,
          total_extra_pause_seconds INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE circuit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL,
          circuit_number INTEGER NOT NULL,
          rpe REAL,
          extra_pause_seconds INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- Шаблоны ---

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

  // --- Проведённые тренировки ---

  /// Сохраняет тренировку вместе с логами кругов, возвращает id тренировки.
  Future<int> saveWorkout(Workout workout, List<CircuitLog> logs) async {
    final db = await database;
    final workoutId = await db.insert('workouts', workout.toMap());
    for (final log in logs) {
      final logMap = log.toMap();
      logMap['workout_id'] = workoutId;
      await db.insert('circuit_logs', logMap);
    }
    return workoutId;
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final rows = await db.query('workouts', orderBy: 'id DESC');
    return rows.map((row) => Workout.fromMap(row)).toList();
  }

  Future<int> deleteWorkout(int id) async {
    final db = await database;
    await db.delete('circuit_logs', where: 'workout_id = ?', whereArgs: [id]);
    return db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CircuitLog>> getCircuitLogs(int workoutId) async {
    final db = await database;
    final rows = await db.query('circuit_logs',
        where: 'workout_id = ?',
        whereArgs: [workoutId],
        orderBy: 'circuit_number ASC');
    return rows.map((row) => CircuitLog.fromMap(row)).toList();
  }
}