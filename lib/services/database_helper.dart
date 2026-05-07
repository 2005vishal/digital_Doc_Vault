import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/document_model.dart';

class DatabaseHelper {
  static Database? _database;

  // Database Instance Getter
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Database Initialize
  static Future<Database> _initDB() async {
    final dbDir = await getApplicationSupportDirectory();
    final path = p.join(dbDir.path, 'vault_pro_final.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            custom_name TEXT, 
            doc_number TEXT, 
            file_path TEXT, 
            folder_name TEXT, 
            date_added TEXT
          )
        ''');
      },
    );
  }

  // 1. Naya Document Insert
  static Future<int> insertDoc(DocumentModel doc) async {
    Database db = await database;
    return await db.insert('documents', doc.toMap());
  }

  // 2. RENAME LOGIC
  static Future<int> updateDocName(int id, String newName) async {
    final db = await database;
    return await db.update(
      'documents',
      {'custom_name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 3. Unique Folders For  Dashboard
  static Future<List<String>> getUniqueFolders() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('SELECT DISTINCT folder_name FROM documents');

    return List.generate(maps.length, (i) {
      return maps[i]['folder_name'] as String;
    });
  }

  // 4. Specific Folder
  static Future<List<DocumentModel>> getDocsByFolder(
    String folderName, {
    String searchQuery = "",
  }) async {
    Database db = await database;
    List<Map<String, dynamic>> maps;

    if (searchQuery.isEmpty) {
      maps = await db.query(
        'documents',
        where: 'folder_name = ?',
        whereArgs: [folderName],
      );
    } else {
      maps = await db.query(
        'documents',
        where: 'folder_name = ? AND (custom_name LIKE ? OR doc_number LIKE ?)',
        whereArgs: [folderName, '%$searchQuery%', '%$searchQuery%'],
      );
    }
    return List.generate(maps.length, (i) => DocumentModel.fromMap(maps[i]));
  }

  // 5. Document Delete karna
  static Future<void> deleteDoc(int id) async {
    Database db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // 6. RESTORE FIX
  static Future<bool> checkIfFileExists(String fileName) async {
    final db = await database;
    // check last of file path
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'file_path LIKE ?',
      whereArgs: ['%$fileName'],
    );
    return maps.isNotEmpty;
  }

  // 7. clean complete data on logout time
  static Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('documents');
  }
}
