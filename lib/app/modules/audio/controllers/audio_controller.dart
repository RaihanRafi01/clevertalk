import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sql.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../views/convert_view.dart';
import '../views/summary_key_point_view.dart';

class AudioPlayerController extends GetxController {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  RxDouble currentPosition = 0.0.obs;
  RxDouble totalDuration = 1.0.obs;
  RxBool isPlaying = false.obs;
  RxList<Map<String, dynamic>> audioFiles = <Map<String, dynamic>>[].obs;
  RxInt currentIndex = (-1).obs; // Default to -1 (no file selected)
  RxBool isLoading = false.obs; // Observable for loading state

  @override
  void onInit() {
    super.onInit();
    fetchAudioFiles();

    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position.inSeconds.toDouble();
    });

    _audioPlayer.durationStream.listen((duration) {
      totalDuration.value = duration?.inSeconds.toDouble() ?? 1.0;
    });

    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
  }

  Future<void> fetchAudioFiles() async {
    final dbHelper = DatabaseHelper();
    final files = await dbHelper.fetchAudioFiles(Get.context!);
    audioFiles.assignAll(files);

    if (files.isNotEmpty) {
      currentIndex.value = files.indexWhere((file) => file['file_name'] == Get.arguments);
      if (currentIndex.value == -1) {
        currentIndex.value = 0; // Default to the first file if no match is found
      }
    } else {
      currentIndex.value = -1; // No files available
    }
  }

  Duration get currentAudioPosition => _audioPlayer.position;

  Future<void> seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> playAudio({String? filePath}) async {
    if (filePath == null) {
      if (audioFiles.isEmpty || currentIndex.value < 0 || currentIndex.value >= audioFiles.length) {
        Get.snackbar('Error', 'No file to play');
        return;
      }
      filePath = audioFiles[currentIndex.value]['file_path'];
    }

    if (await File(filePath!).exists()) {
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } else {
      Get.snackbar('Error', 'File does not exist');
    }
  }

  void playPrevious() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      playAudio();
    } else {
      Get.snackbar('Error', 'This is the first track');
    }
  }

  void playNext() {
    if (currentIndex.value < audioFiles.length - 1) {
      currentIndex.value++;
      playAudio();
    } else {
      Get.snackbar('Error', 'This is the last track');
    }
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  /*Future<void> convertToText() async {
    try {
      if (audioFiles.isEmpty || currentIndex.value < 0) {
        throw Exception('No audio file selected');
      }

      final audioFile = audioFiles[currentIndex.value];
      final filePath = audioFile['file_path'];
      final fileName = audioFile['file_name'];


      print('::::::::::::::::::::::::::::::::::::filePath: $filePath');
      print('::::::::::::::::::::::::::::::::::::fileName: $fileName');

      isLoading.value = true; // Start loading

      final response = await _apiService.fetchTranscription(filePath);

      print('::::::::::::::::::::::::::::::::::::CODE: ${response.statusCode}');
      print('::::::::::::::::::::::::::::::::::::body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final extractedData = result['Data'];
        Get.to(() => ConvertView(text: extractedData, filePath: filePath, fileName: fileName,));

        Get.snackbar('Success', 'Text Conversion Success');
      } else {
        Get.snackbar('Error', 'Text Conversion Failed: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    }
    finally {
      isLoading.value = false; // Stop loading
    }
  }*/


  Future<void> convertToText() async {
    try {
      if (audioFiles.isEmpty || currentIndex.value < 0) {
        throw Exception('No audio file selected');
      }

      final audioFile = audioFiles[currentIndex.value];
      final filePath = audioFile['file_path'];
      final fileName = audioFile['file_name'];

      print('::::::::::::::::::::::::::::::::::::filePath: $filePath');
      print('::::::::::::::::::::::::::::::::::::fileName: $fileName');

      isLoading.value = true; // Start loading

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Check if the transcription exists in the database
      final result = await db.query(
        'audio_files',
        where: 'file_path = ?',
        whereArgs: [filePath],
      );

      if (result.isNotEmpty) {
        final existingTranscription = result.first['transcription'];

        if (existingTranscription != null && existingTranscription.toString().isNotEmpty) {
          print('::::::::::::::::::::::::::::::::::::Transcription found in database');

          // Decode the transcription and navigate to ConvertView
          //final data = json.decode(existingTranscription.toString()) as List;
          Get.to(() => ConvertView(
            text: existingTranscription.toString(),
            filePath: filePath,
            fileName: fileName,
          ));
          Get.snackbar('Success', 'Loaded transcription from database');
        } else {
          // Fetch transcription from the API if not available in the database
          await fetchTranscriptionFromApi(filePath, fileName, db);
        }
      } else {
        // File not found in the database
        Get.snackbar('Error', 'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false; // Stop loading
    }
  }

  Future<void> fetchTranscriptionFromApi(String filePath, String fileName, Database db) async {
    try {
      final response = await _apiService.fetchTranscription(filePath);

      print('::::::::::::::::::::::::::::::::::::CODE: ${response.statusCode}');
      print('::::::::::::::::::::::::::::::::::::body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final data = result['Data'];

        // Save the transcription to the database
        await db.update(
          'audio_files',
          {'transcription': json.encode(data)},
          where: 'file_path = ?',
          whereArgs: [filePath],
        );

        // Navigate to ConvertView with the fetched transcription
        Get.to(() => ConvertView(
          text: json.encode(data),
          filePath: filePath,
          fileName: fileName,
        ));

        Get.snackbar('Success', 'Text Conversion Success');
      } else {
        Get.snackbar('Error', 'Text Conversion Failed: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching transcription: $e');
    }
  }




  /*Future<void> fetchSummary(String filePath, String fileName) async {
    try {
      isLoading.value = true; // Start loading
      final response = await _apiService.fetchSummary(filePath, fileName);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Extract the "content" field from the "Data" object
        final summaryText = result['Data']['content'];

        // Navigate to SummaryKeyPointView with the extracted summary
        Get.to(() => SummaryKeyPointView(summary: summaryText, keyPoints: ''));
      } else {
        Get.snackbar('Error', 'Failed to fetch summary: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false; // Stop loading
    }
  }*/

  /*Future<void> fetchSummary(String filePath, String fileName) async {
    try {
      isLoading.value = true; // Start loading
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Check if the file exists in the database
      final result = await db.query(
        'audio_files',
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        final existingSummary = result.first['summary'];

        if (existingSummary != null && existingSummary.toString().isNotEmpty) {
          // If the summary already exists, show it
          Get.to(() => SummaryKeyPointView(summary: existingSummary.toString(), keyPoints: ''));
        } else {
          // If the summary is not available, fetch it from the API
          final response = await _apiService.fetchSummary(filePath, fileName);

          if (response.statusCode == 200) {
            final jsonResponse = json.decode(response.body);
            final summaryText = jsonResponse['Data']['content'];

            // Update the summary in the database
            await db.update(
              'audio_files',
              {'summary': summaryText},
              where: 'file_name = ?',
              whereArgs: [fileName],
            );

            // Navigate to SummaryKeyPointView with the new summary
            Get.to(() => SummaryKeyPointView(summary: summaryText, keyPoints: ''));
          } else {
            Get.snackbar('Error', 'Failed to fetch summary: ${response.body}');
          }
        }
      } else {
        // If the file doesn't exist in the database, show an error
        Get.snackbar('Error', 'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false; // Stop loading
    }
  }*/



  Future<void> fetchKeyPoints(String filePath, String fileName) async {
    try {
      isLoading.value = true; // Start loading
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Check if the file exists in the database
      final result = await db.query(
        'audio_files',
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        final existingKeypoint = result.first['key_point'];

        if (existingKeypoint != null && existingKeypoint.toString().isNotEmpty) {
          // If the summary already exists, show it
          Get.to(() => SummaryKeyPointView(keyPoints: existingKeypoint.toString()));
        } else {
          // If the summary is not available, fetch it from the API
          final response = await _apiService.fetchKeyPoints(filePath, fileName);


          print('::::::::::statusCode::::::::::::::::${response.statusCode}');
          print('::::::::body::::::::::::::::::${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final jsonResponse = json.decode(response.body);
            final keyPointText = jsonResponse['Data']['content'];

            // Update the summary in the database
            await db.update(
              'audio_files',
              {'key_point': keyPointText},
              where: 'file_name = ?',
              whereArgs: [fileName],
            );

            // Navigate to SummaryKeyPointView with the new summary
            Get.to(() => SummaryKeyPointView(keyPoints: keyPointText));
          } else {
            Get.snackbar('Error', 'Failed to fetch keyPoint: ${response.body}');
          }
        }
      } else {
        // If the file doesn't exist in the database, show an error
        Get.snackbar('Error', 'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false; // Stop loading
    }
  }

  /*Future<void> fetchKeyPoints(String filePath, String fileName) async {
    try {
      isLoading.value = true; // Start loading
      final response = await _apiService.fetchKeyPoints(filePath, fileName);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final keyPointsText = result['Data']['content'];
        Get.to(() => SummaryKeyPointView(isKey: true, keyPoints: keyPointsText, summary: '',));
      } else {
        Get.snackbar('Error', 'Failed to fetch key points: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      isLoading.value = false; // Stop loading
    }
  }*/

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
