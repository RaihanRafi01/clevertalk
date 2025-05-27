import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../common/localization/localization_controller.dart';
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
  RxInt currentIndex = (-1).obs;
  RxBool isLoading = false.obs;
  String? _currentFilePath;
  RxBool isSeeking = false.obs;
  RxDouble waveformOffset = 0.0.obs;
  Timer? _animationTimer;

  @override
  void onInit() {
    super.onInit();
    print('AudioPlayerController onInit called');
    _setupAudioPlayerListeners();
    fetchAudioFiles();
  }

  @override
  void onClose() {
    print('AudioPlayerController onClose called');
    _animationTimer?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }

  void _setupAudioPlayerListeners() {
    print('Setting up AudioPlayer listeners');
    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position.inSeconds.toDouble();
    });

    _audioPlayer.durationStream.listen((duration) {
      totalDuration.value = duration?.inSeconds.toDouble() ?? 1.0;
    });

    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      print(
          'AudioPlayer state: playing=${state.playing}, processingState=${state.processingState}');
      if (state.playing) {
        _startWaveformAnimation();
      } else {
        _stopWaveformAnimation();
      }

      if (state.processingState == ProcessingState.completed) {
        _stopWaveformAnimation();
        currentPosition.value = 0.0;
        isPlaying.value = false;
      } else if (state.processingState == ProcessingState.ready) {
        print('AudioPlayer is ready to play');
      } else if (state.processingState == ProcessingState.buffering) {
        print('AudioPlayer is buffering...');
      } else if (state.processingState == ProcessingState.idle) {
        print('AudioPlayer is idle');
      }
    });

    _audioPlayer.playbackEventStream.listen((event) {
      print('Playback event: $event');
    }, onError: (Object e, StackTrace st) {
      print('Playback error: $e');
      Get.snackbar('error'.tr, 'failed_to_play_audio'.tr);
      isPlaying.value = false;
    });
  }

  void _startWaveformAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (isPlaying.value) {
        waveformOffset.value -= 2;
        if (waveformOffset.value <= -Get.width) {
          waveformOffset.value = 0.0;
        }
      }
    });
  }

  void _stopWaveformAnimation() {
    _animationTimer?.cancel();
  }

  Future<void> fetchAudioFiles({String? fileName}) async {
    print('Fetching audio files...');
    final dbHelper = DatabaseHelper();
    final files = await dbHelper.fetchAudioFiles();
    audioFiles.assignAll(files);

    if (files.isNotEmpty) {
      if (fileName != null) {
        currentIndex.value =
            files.indexWhere((file) => file['file_name'] == fileName);
      }
      if (currentIndex.value == -1) {
        currentIndex.value = 0; // Fallback to first file if fileName not found
      }
    } else {
      currentIndex.value = -1;
    }
    print('Audio files fetched: ${audioFiles.length}');
  }

  Duration get currentAudioPosition => _audioPlayer.position;

  Future<void> seekAudio(Duration position) async {
    isSeeking.value = true;
    print('Seeking to: ${position.inSeconds}');
    await _audioPlayer.seek(position);
    isSeeking.value = false;
  }

  Future<void> pauseAudio() async {
    print('Pausing audio... Current position: ${currentPosition.value}');
    await _audioPlayer.pause();
    isPlaying.value = false;
    print('Paused. Position: ${currentPosition.value}');
  }

  Future<void> playAudio({String? filePath}) async {
    try {
      if (filePath == null) {
        if (audioFiles.isEmpty ||
            currentIndex.value < 0 ||
            currentIndex.value >= audioFiles.length) {
          Get.snackbar('error'.tr, 'no_file_to_play'.tr);
          return;
        }
        filePath = audioFiles[currentIndex.value]['file_path'];
      }

      final file = File(filePath!);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        Get.snackbar('error'.tr, 'file_not_exist'.tr);
        return;
      }

      try {
        final canRead = await file.openRead().isEmpty;
        print('File is readable: $canRead');
      } catch (e) {
        print('Cannot read file: $e');
        Get.snackbar('error'.tr, 'cannot_read_file'.tr);
        return;
      }

      print('Setting file path: $filePath');
      _currentFilePath = filePath;

      // Ensure the AudioPlayer is in a valid state
      if (_audioPlayer.playing ||
          _audioPlayer.processingState != ProcessingState.idle) {
        print('AudioPlayer is not idle, stopping...');
        await _audioPlayer.stop();
      }
      print('AudioPlayer stopped');

      // Set the audio source
      await _audioPlayer.setFilePath(filePath);
      print('Audio source set successfully');

      // Reset position to start
      await _audioPlayer.seek(Duration.zero);
      currentPosition.value = 0.0;
      print('Position reset to 0');

      // Start playback
      print('Starting playback...');
      await _audioPlayer.play();
      isPlaying.value = true;
      print('Playback started');
    } catch (e, stackTrace) {
      print('Error in playAudio: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar('Error', 'Failed to play audio: $e');
      isPlaying.value = false;
    }
  }

  Future<void> resumeAudio({String? filePath}) async {
    try {
      if (_audioPlayer.audioSource == null ||
          (filePath != null && filePath != _currentFilePath)) {
        print(
            'Audio source not set or file changed. Re-setting file path: $filePath');
        if (filePath == null) {
          if (audioFiles.isNotEmpty && currentIndex.value >= 0) {
            filePath = audioFiles[currentIndex.value]['file_path'];
          } else {
            Get.snackbar('error'.tr, 'no_audio_file_available'.tr);
            return;
          }
        }
        await playAudio(filePath: filePath);
        return;
      }

      print('Resuming audio from position: ${currentPosition.value}');
      await _audioPlayer.seek(Duration(seconds: currentPosition.value.toInt()));
      await _audioPlayer.play();
      isPlaying.value = true;
      print('Resume completed. Position: ${currentPosition.value}');
    } catch (e) {
      print('Error in resumeAudio: $e');
      Get.snackbar('error'.tr, 'failed_to_resume_audio'.tr);
      isPlaying.value = false;
    }
  }

  void playPrevious() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      playAudio();
    } else {
      Get.snackbar('error'.tr, 'first_track'.tr);
    }
  }

  void playNext() {
    if (currentIndex.value < audioFiles.length - 1) {
      currentIndex.value++;
      playAudio();
    } else {
      Get.snackbar('error'.tr, 'last_track'.tr);
    }
  }

  Future<void> stopAudio() async {
    try {
      print('Stopping audio...');
      await _audioPlayer.stop();
      currentPosition.value = 0.0;
      isPlaying.value = false;
      _currentFilePath = null;
      _stopWaveformAnimation();
      print('Audio stopped');
    } catch (e) {
      print('Error in stopAudio: $e');
    }
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

      isLoading.value = true;

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

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
      isLoading.value = false;
    }
  }*/

  /*Future<void> fetchTranscriptionFromApi(String filePath, String fileName, Database db) async {
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
  }*/

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

        if (existingKeypoint != null &&
            existingKeypoint.toString().isNotEmpty) {
          print(
              '::::::::existingKeypoint::::::::::::::::::${existingKeypoint.toString()}');
          Get.to(() =>
              SummaryKeyPointView(fileName: fileName, filePath: filePath));
        } else {
          Get.snackbar(
            'summarization_in_progress'.tr,
            'summarization_notification'.tr,
            duration: Duration(seconds: 4),
          );
          final response = await _apiService.fetchKeyPoints(filePath, fileName);

          print('::::::::::statusCode::::::::::::::::${response.statusCode}');
          print('::::::::body1::::::::::::::::::${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final jsonResponse = json.decode(response.body);
            final keyPointText = jsonResponse['Data']['content'];
            //final language_summary = jsonResponse['nil_vai_shakil_vai'];

            String languageCode = jsonResponse['nil_vai_shakil_vai'];
            String language_summary = LocalizationController.languageMap[languageCode] ?? languageCode;

            print(':::::::::nil_vai_shakil_vai::::::::::::language_summary::::::::::::::::::::: $language_summary');
            await db.update(
              'audio_files',
              {
                'key_point': keyPointText,
                //'language_summary': language_summary
              },
              where: 'file_name = ?',
              whereArgs: [fileName],
            );

            NotificationService.showNotification(
              title: 'summary_ready'.tr,
              body: 'click_to_view_summary'.tr,
              payload: "Summary",
              keyPoints: keyPointText,
              fileName: fileName,
              filePath: filePath,
            );
          } else {
            Get.snackbar('error'.tr, 'failed_to_fetch_keypoint'.tr);
          }
        }
      } else {
        Get.snackbar('Error',
            'File not found in the database. Please add the file first.');
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
