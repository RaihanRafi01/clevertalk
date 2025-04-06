import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../../data/services/notification_services.dart';
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
  String? _currentFilePath;
  RxBool isSeeking = false.obs;
  RxDouble waveformOffset = 0.0.obs;
  Timer? _animationTimer;

  @override
  void onInit() {
    super.onInit();
    fetchAudioFiles();
    _setupAudioPlayerListeners();
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position.inSeconds.toDouble();
    });

    _audioPlayer.durationStream.listen((duration) {
      totalDuration.value = duration?.inSeconds.toDouble() ?? 1.0;
    });

    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.playing) {
        _startWaveformAnimation();
      } else {
        _stopWaveformAnimation();
      }
    });
  }

  void _startWaveformAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (isPlaying.value) {
        waveformOffset.value -= 2; // Same as RecordController
        if (waveformOffset.value <= -Get.width) {
          waveformOffset.value = 0.0; // Reset to 0 when it reaches screen width
        }
      }
    });
  }

  void _stopWaveformAnimation() {
    _animationTimer?.cancel();
  }

  Future<void> fetchAudioFiles() async {
    final dbHelper = DatabaseHelper();
    final files = await dbHelper.fetchAudioFiles();
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
    isSeeking.value = true; // Set seeking flag
    print('Seeking to: ${position.inSeconds}');
    await _audioPlayer.seek(position);
    isSeeking.value = false; // Reset flag after seek
  }

  Future<void> pauseAudio() async {
    print('Pausing audio... Current position: ${currentPosition.value}');
    await _audioPlayer.pause();
    isPlaying.value = false;
    print('Paused. Position: ${currentPosition.value}');
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
      print('Setting file path: $filePath');
      _currentFilePath = filePath; // Store the current file path
      await _audioPlayer.setFilePath(filePath);
      print('Starting playback...');
      await _audioPlayer.play();
      isPlaying.value = true;
    } else {
      print('File does not exist: $filePath');
      Get.snackbar('Error', 'File does not exist');
    }
  }

  Future<void> resumeAudio({String? filePath}) async {
    if (_audioPlayer.audioSource == null || (filePath != null && filePath != _currentFilePath)) {
      print('Audio source not set or file changed. Re-setting file path: $filePath');
      if (filePath == null) {
        if (audioFiles.isNotEmpty && currentIndex.value >= 0) {
          filePath = audioFiles[currentIndex.value]['file_path'];
        } else {
          Get.snackbar('Error', 'No audio file available to resume');
          return;
        }
      }
      await playAudio(filePath: filePath); // Re-start playback if source is lost
      return;
    }

    print('Resuming audio from position: ${currentPosition.value}');
    await _audioPlayer.seek(Duration(seconds: currentPosition.value.toInt())); // Ensure position
    await _audioPlayer.play();
    isPlaying.value = true;
    print('Resume completed. Position: ${currentPosition.value}');
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
    print('Stopping audio...');
    await _audioPlayer.stop();
    currentPosition.value = 0.0;
    isPlaying.value = false;
    _currentFilePath = null; // Clear the current file path
    _stopWaveformAnimation(); // Ensure animation stops
  }

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
          Get.to(() => ConvertView(
            text: existingTranscription.toString(),
            filePath: filePath,
            fileName: fileName,
          ));
          Get.snackbar('Success', 'Loaded transcription from database');
        } else {
          await fetchTranscriptionFromApi(filePath, fileName, db);
        }
      } else {
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

        await db.update(
          'audio_files',
          {'transcription': json.encode(data)},
          where: 'file_path = ?',
          whereArgs: [filePath],
        );

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

  Future<void> fetchKeyPoints(String filePath, String fileName) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.query(
        'audio_files',
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        final existingKeypoint = result.first['key_point'];

        if (existingKeypoint != null && existingKeypoint.toString().isNotEmpty) {
          print('::::::::existingKeypoint::::::::::::::::::${existingKeypoint.toString()}');
          Get.to(() => SummaryKeyPointView(fileName: fileName, filePath: filePath));
        } else {
          Get.snackbar(
            'Summarization in progress...',
            'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to use the app while you wait.',
            duration: Duration(seconds: 4),
          );
          final response = await _apiService.fetchKeyPoints(filePath, fileName);

          print('::::::::::statusCode::::::::::::::::${response.statusCode}');
          print('::::::::body1::::::::::::::::::${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final jsonResponse = json.decode(response.body);
            final keyPointText = jsonResponse['Data']['content'];

            await db.update(
              'audio_files',
              {'key_point': keyPointText},
              where: 'file_name = ?',
              whereArgs: [fileName],
            );

            NotificationService.showNotification(
              title: "Summary Ready!",
              body: "Click to view Summary",
              payload: "Summary",
              keyPoints: keyPointText,
              fileName: fileName,
              filePath: filePath,
            );
          } else {
            Get.snackbar('Error', 'Failed to fetch keyPoint: ${response.body}');
          }
        }
      } else {
        Get.snackbar('Error', 'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    }
  }

  String formatTime(int seconds, int milliseconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}