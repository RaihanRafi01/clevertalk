import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'audio_files.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE audio_files (
            id INTEGER PRIMARY KEY,
            file_name TEXT,
            file_path TEXT,
            duration TEXT,
            saved_date TEXT
          )
          ''',
        );
      },
    );
  }

  Future<void> insertAudioFile(
      BuildContext context, String fileName, String filePath, String duration) async {
    final db = await database;
    final date = DateTime.now().toIso8601String();
    await db.insert('audio_files', {
      'file_name': fileName,
      'file_path': filePath,
      'duration': duration,
      'saved_date': date,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio file "$fileName" inserted successfully!')),
    );
  }

  Future<List<Map<String, dynamic>>> fetchAudioFiles(BuildContext context) async {
    final db = await database;
    final files = await db.query('audio_files');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${files.length} audio files fetched successfully!')),
    );
    return files;
  }

  Future<void> deleteAllAudioFiles(BuildContext context) async {
    final db = await database;
    await db.delete('audio_files');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All audio files deleted successfully!')),
    );
  }

  Future<void> deleteAudioFile(BuildContext context, int id) async {
    final db = await database;
    await db.delete(
      'audio_files',
      where: 'id = ?',
      whereArgs: [id],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio file deleted successfully!')),
    );
  }

  Future<void> renameAudioFile(BuildContext context, int id, String newFileName) async {
    final db = await database;
    await db.update(
      'audio_files',
      {'file_name': newFileName},
      where: 'id = ?',
      whereArgs: [id],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio file renamed successfully!')),
    );
  }


}
