import 'dart:async';
import 'package:clevertalk/app/modules/audio/controllers/audio_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  //final AudioPlayerController audioPlayerController = Get.put(AudioPlayerController());
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<bool> hasTranscription(String fileName) async {
    final db = await database;
    final result = await db.query(
      'audio_files',
      columns: ['transcription'],
      where: 'file_name = ?',
      whereArgs: [fileName],
    );

    if (result.isNotEmpty) {
      final transcription = result.first['transcription'] as String?;
      return transcription != null && transcription.isNotEmpty;
    }
    return false;
  }


  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'audio_files.db');
    return await openDatabase(
      path,
      version: 1, // Keep version as 1 since you're starting from scratch
      onCreate: (db, version) async {
        await db.execute(
            '''
        CREATE TABLE audio_files (
          id INTEGER PRIMARY KEY,
          file_name TEXT,
          file_path TEXT,
          duration TEXT,
          saved_date TEXT,
          parsed_date TEXT,
          summary TEXT,
          key_point TEXT,
          transcription TEXT
        )
        '''
        );
      },
    );
  }


  Future<void> insertAudioFile(
      BuildContext context, String fileName, String filePath, String duration, bool isLocal , String localParsedDate) async {
    final db = await database;
    final date = DateTime.now().toIso8601String();
    //final parsedDate = parseFileNameToDate(fileName); // Parse date from file name

    final parsedDate = isLocal ? localParsedDate : parseFileNameToDate(fileName);


    await db.insert('audio_files', {
      'file_name': fileName,
      'file_path': filePath,
      'duration': duration,
      'saved_date': date,
      'parsed_date': parsedDate, // Save parsed date
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio file "$fileName" inserted successfully!')),
    );
    //audioPlayerController.fetchAudioFiles();
  }

  Future<List<Map<String, dynamic>>> fetchAudioFiles() async {
    final db = await database;
    final files = await db.query('audio_files');
    /*ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${files.length} audio files fetched successfully!')),
    );*/
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
      {
        'file_name': newFileName,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio file renamed successfully!')),
    );
  }

  Future<void> updateFileParsedDate(int id, String parsedDate) async {
    final db = await database;
    await db.update(
      'audio_files',
      {'parsed_date': parsedDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  String parseFileNameToDate(String fileName) {
    try {
      final dateTimePart = fileName.substring(1, fileName.indexOf('.'));
      final datePart = dateTimePart.split('-')[0]; // e.g., 20250112
      final timePart = dateTimePart.split('-')[1]; // e.g., 142010

      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(timePart.substring(0, 2));
      final minute = int.parse(timePart.substring(2, 4));
      final second = int.parse(timePart.substring(4, 6));

      final dateTime = DateTime(year, month, day, hour, minute, second);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Unknown Date';
    }
  }
}
