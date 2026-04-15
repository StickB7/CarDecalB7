import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../models/vault_file.dart';

/// SQLite database for file metadata.
/// The actual file bytes are stored on disk in the vault directory (encrypted).
class DatabaseService {
  static const _table = 'vault_files';
  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dir    = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, AppConstants.dbName);

    return openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id                  TEXT PRIMARY KEY,
        original_name       TEXT NOT NULL,
        encrypted_filename  TEXT NOT NULL,
        category            TEXT NOT NULL,
        file_size           INTEGER NOT NULL,
        mime_type           TEXT NOT NULL,
        created_at          INTEGER NOT NULL,
        modified_at         INTEGER NOT NULL
      )
    ''');
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> insertFile(VaultFile file) async {
    final db = await _database;
    await db.insert(_table, file.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<VaultFile?> getFileById(String id) async {
    final db   = await _database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return VaultFile.fromMap(maps.first);
  }

  /// Returns all files, newest first.
  Future<List<VaultFile>> getAllFiles({String? category}) async {
    final db = await _database;
    final maps = await db.query(
      _table,
      where: category != null && category != 'all' ? 'category = ?' : null,
      whereArgs: category != null && category != 'all' ? [category] : null,
      orderBy: 'created_at DESC',
    );
    return maps.map(VaultFile.fromMap).toList();
  }

  Future<void> deleteFile(String id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameFile(String id, String newName) async {
    final db = await _database;
    await db.update(
      _table,
      {'original_name': newName, 'modified_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countFiles({String? category}) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $_table'
      '${category != null && category != 'all' ? ' WHERE category = ?' : ''}',
      category != null && category != 'all' ? [category] : null,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
