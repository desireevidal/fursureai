import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../features/results/data/prediction_record.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'fursure.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE predictions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            catName TEXT,
            breed TEXT,
            breedConfidence REAL,
            gender TEXT,
            genderConfidence REAL,
            timestamp TEXT NOT NULL,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertPrediction(PredictionRecord record) async {
    final db = await database;
    return db.insert('predictions', record.toMap());
  }

  Future<List<PredictionRecord>> getRecentPredictions({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'predictions',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map(PredictionRecord.fromMap).toList();
  }

  Future<void> deletePrediction(int id) async {
    final db = await database;
    await db.delete('predictions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePrediction(PredictionRecord record) async {
    final db = await database;
    if (record.id == null) return;
    final values = Map<String, dynamic>.from(record.toMap())..remove('id');

    await db.update(
      'predictions',
      values,
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<bool> predictionExistsAt(String timestamp) async {
    final db = await database;
    final rows = await db.query(
      'predictions',
      columns: ['id'],
      where: 'timestamp = ?',
      whereArgs: [timestamp],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
