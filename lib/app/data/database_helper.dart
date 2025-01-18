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
      version: 2, // Increment the version number
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE audio_files (
            id INTEGER PRIMARY KEY, 
            file_name TEXT, 
            file_data BLOB, 
            duration TEXT, 
            saved_date TEXT
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE audio_files ADD COLUMN duration TEXT');
          db.execute('ALTER TABLE audio_files ADD COLUMN saved_date TEXT');
        }
      },
    );
  }

  Future<void> insertAudioFile(
      BuildContext context, String fileName, List<int> fileData, String duration) async {
    final db = await database;
    final date = DateTime.now().toIso8601String();
    await db.insert('audio_files', {
      'file_name': fileName,
      'file_data': fileData,
      'duration': duration,
      'saved_date': date,
    });
    _showSnackbar(context, 'Audio file "$fileName" inserted successfully!');
  }

  Future<List<Map<String, dynamic>>> fetchAudioFiles(BuildContext context) async {
    final db = await database;
    final files = await db.query('audio_files');
    _showSnackbar(context, '${files.length} audio files fetched successfully!');
    return files;
  }

  Future<void> deleteAllAudioFiles(BuildContext context) async {
    final db = await database;
    await db.delete('audio_files');
    _showSnackbar(context, 'All audio files deleted successfully!');
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

