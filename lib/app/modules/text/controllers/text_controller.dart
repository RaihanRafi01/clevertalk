import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../audio/controllers/audio_controller.dart';

class ConvertToTextController extends GetxController {
  var messages = <Map<String, String>>[].obs;
  var highlightedTimestamp = ''.obs;
  var currentHighlightedIndex = (-1).obs;
  var isLoading = false.obs;
  final ScrollController scrollController = ScrollController();

  /*Future<void> fetchMessages(String filePath) async {
    final ApiService _apiService = ApiService();
    try {
      isLoading.value = true;
      final response = await _apiService.fetchTranscription(filePath);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['Data'] as List;
        messages.value = data.map<Map<String, String>>((entry) {
          final speakerName = entry['Speaker_Name'] as String;
          final transcript = entry['Transcript'] as String;
          final startTime = formatTimestamp(entry['Start_time'] as double);
          final endTime = formatTimestamp(entry['End_time'] as double);
          return {
            'name': speakerName,
            'time': '$startTime - $endTime',
            'description': transcript,
          };
        }).toList();

        // Start scrolling based on timestamps when data is fetched
        final audioController = Get.find<AudioPlayerController>();
        audioController.playAudio();
        syncScrollingWithAudio(audioController);
      } else {
        Get.snackbar('Error', 'Failed to fetch data: ${response.reasonPhrase}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching messages: $e');
    } finally {
      isLoading.value = false;
    }
  }*/


  Future<void> fetchMessages(String filePath) async {
    final ApiService _apiService = ApiService();
    try {
      isLoading.value = true;

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Check if the file exists in the database
      final result = await db.query(
        'audio_files',
        where: 'file_path = ?',
        whereArgs: [filePath],
      );

      if (result.isNotEmpty) {
        final existingTranscription = result.first['transcription'];

        if (existingTranscription != null && existingTranscription.toString().isNotEmpty) {
          // If transcription exists, use it
          final data = json.decode(existingTranscription.toString()) as List;
          messages.value = data.map<Map<String, String>>((entry) {
            final speakerName = entry['Speaker_Name'] as String;
            final transcript = entry['Transcript'] as String;
            final startTime = formatTimestamp(entry['Start_time'] as double);
            final endTime = formatTimestamp(entry['End_time'] as double);
            return {
              'name': speakerName,
              'time': '$startTime - $endTime',
              'description': transcript,
            };
          }).toList();

          // Start scrolling based on timestamps
          final audioController = Get.find<AudioPlayerController>();
          audioController.playAudio();
          syncScrollingWithAudio(audioController);
        } else {
          // Fetch transcription from the API
          final response = await _apiService.fetchTranscription(filePath);

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            final data = jsonData['Data'] as List;

            // Update the transcription in the database
            await db.update(
              'audio_files',
              {'transcription': json.encode(data)},
              where: 'file_path = ?',
              whereArgs: [filePath],
            );

            messages.value = data.map<Map<String, String>>((entry) {
              final speakerName = entry['Speaker_Name'] as String;
              final transcript = entry['Transcript'] as String;
              final startTime = formatTimestamp(entry['Start_time'] as double);
              final endTime = formatTimestamp(entry['End_time'] as double);
              return {
                'name': speakerName,
                'time': '$startTime - $endTime',
                'description': transcript,
              };
            }).toList();

            // Start scrolling based on timestamps
            final audioController = Get.find<AudioPlayerController>();
            audioController.playAudio();
            syncScrollingWithAudio(audioController);
          } else {
            Get.snackbar('Error', 'Failed to fetch data: ${response.reasonPhrase}');
          }
        }
      } else {
        // File not found in the database
        Get.snackbar('Error', 'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching messages: $e');
    } finally {
      isLoading.value = false;
    }
  }


  void syncScrollingWithAudio(AudioPlayerController audioController) {
    audioController.currentPosition.listen((position) {
      final currentTimestamp = position; // Use the value directly as it is in seconds

      // Find the message that matches the current timestamp
      final index = messages.indexWhere((msg) {
        final times = msg['time']!.split(' - ');
        final startTime = parseTimeToSeconds(times[0]);
        final endTime = parseTimeToSeconds(times[1]);

        return currentTimestamp >= startTime && currentTimestamp <= (endTime + 0.5);
      });

      if (index != -1 && currentHighlightedIndex.value != index) {
        currentHighlightedIndex.value = index;

        // Scroll to the highlighted message
        final scrollPosition = index * 125.0; // Adjust based on your UI
        scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }



  double parseTimeToSeconds(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);
    return (hours * 3600 + minutes * 60 + seconds).toDouble();
  }


  String formatTimestamp(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }
}

class TextViewController extends GetxController {
  var textFiles = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTextFiles();
  }

  Future<void> fetchTextFiles() async {
    final dbHelper = DatabaseHelper();
    final files = await dbHelper.fetchAudioFiles();
    textFiles.value = files;
  }
}