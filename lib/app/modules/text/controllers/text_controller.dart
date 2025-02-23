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

  void editFullTranscription(BuildContext context,String filePath) {
    TextEditingController transcriptionController = TextEditingController();

    // Load current transcription text, keeping original timestamps
    String fullText = messages.map((msg) => "${msg['name']}: ${msg['description']}").join('\n');
    transcriptionController.text = fullText;

    Get.dialog(
      AlertDialog(
        title: Text('Edit Transcription'),
        content: TextField(
          controller: transcriptionController,
          maxLines: 10,
          decoration: InputDecoration(labelText: 'Edit Full Transcription'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (transcriptionController.text.trim().isEmpty) {
                Get.snackbar("Error", "Transcription cannot be empty!");
                return;
              }

              // Convert edited text into JSON format for storage
              List<Map<String, dynamic>> updatedMessages = transcriptionController.text
                  .split('\n')
                  .where((line) => line.contains(': ')) // Ensure valid format
                  .map((line) {
                final parts = line.split(': ');
                final speakerName = parts[0].trim();
                final transcript = parts.sublist(1).join(': ').trim();

                // Retrieve the original Start_time and End_time dynamically
                final originalEntry = messages.firstWhere(
                      (msg) => msg['name'] == speakerName,
                  orElse: () => {'time': '00:00:00 - 00:00:00'}, // Default
                );

                final times = originalEntry['time']!.split(' - ');
                final startTime = parseTimeToSeconds(times[0]);
                final endTime = parseTimeToSeconds(times[1]);

                return {
                  "Speaker_Name": speakerName,
                  "Transcript": transcript,
                  "Start_time": startTime,
                  "End_time": endTime,
                };
              }).toList();

              // Ensure we have valid data
              if (updatedMessages.isEmpty) {
                Get.snackbar("Error", "Invalid transcription format.");
                return;
              }

              // 🔹 Update the UI immediately before saving
              messages.value = updatedMessages.map<Map<String, String>>((entry) => {
                'name': entry['Speaker_Name'].toString(),
                'time': '${formatTimestamp(entry['Start_time'] as double)} - ${formatTimestamp(entry['End_time'] as double)}',
                'description': entry['Transcript'].toString(),
              }).toList();

              messages.refresh(); // 🔥 Ensure UI updates instantly

              // Save updated transcription to database
              final dbHelper = DatabaseHelper();
              final db = await dbHelper.database;
              await db.update(
                'audio_files',
                {'transcription': json.encode(updatedMessages)}, // Save as JSON
                where: 'file_path = ?',
                whereArgs: [filePath],
              );

              print("Updated transcription saved: ${json.encode(updatedMessages)}");

              // 🔹 Fetch messages again to reload the latest data
              await fetchMessages(filePath);

              Get.back(); // Close dialog
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }



  void editSpeakerName(BuildContext context,String filePath) {
    TextEditingController speakerNameController = TextEditingController();

    // 🔹 Extract unique speaker names
    Set<String> uniqueSpeakers = messages.map((msg) => msg['name']!).toSet();

    // 🔹 Ensure a valid default selection
    String selectedSpeaker = uniqueSpeakers.isNotEmpty ? uniqueSpeakers.first : "";

    Get.dialog(
      AlertDialog(
        title: Text('Edit Speaker Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown for selecting a speaker (only unique speakers)
            DropdownButtonFormField<String>(
              value: selectedSpeaker.isNotEmpty ? selectedSpeaker : null, // Ensure default value
              items: uniqueSpeakers.map((speaker) {
                return DropdownMenuItem(
                  value: speaker,
                  child: Text(speaker),
                );
              }).toList(),
              onChanged: (value) {
                selectedSpeaker = value ?? '';
              },
              decoration: InputDecoration(labelText: "Select Speaker"),
            ),
            const SizedBox(height: 10),
            // Text field to enter new speaker name
            TextField(
              controller: speakerNameController,
              decoration: InputDecoration(labelText: 'New Speaker Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (speakerNameController.text.trim().isEmpty) {
                Get.snackbar("Error", "Speaker name cannot be empty!");
                return;
              }

              final newSpeakerName = speakerNameController.text.trim();

              // 🔹 Update all instances of the selected speaker in `messages`
              for (var msg in messages) {
                if (msg['name'] == selectedSpeaker) {
                  msg['name'] = newSpeakerName;
                }
              }
              messages.refresh(); // 🔥 Ensure UI updates immediately

              // 🔹 Update the database
              final dbHelper = DatabaseHelper();
              final db = await dbHelper.database;

              // Fetch existing transcription from DB
              final result = await db.query(
                'audio_files',
                where: 'file_path = ?',
                whereArgs: [filePath],
              );

              if (result.isNotEmpty) {
                final existingTranscription = result.first['transcription'];

                if (existingTranscription != null && existingTranscription.toString().isNotEmpty) {
                  List<dynamic> data = json.decode(existingTranscription.toString());

                  // 🔹 Update speaker names in the database
                  for (var entry in data) {
                    if (entry['Speaker_Name'] == selectedSpeaker) {
                      entry['Speaker_Name'] = newSpeakerName;
                    }
                  }

                  // Save updated transcription back to the database
                  await db.update(
                    'audio_files',
                    {'transcription': json.encode(data)},
                    where: 'file_path = ?',
                    whereArgs: [filePath],
                  );

                  print("Updated speaker names saved: ${json.encode(data)}");
                }
              }

              Get.back(); // Close dialog
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }





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
          // Parse existing transcription
          final data = json.decode(existingTranscription.toString()) as List;
          List<Map<String, dynamic>> splitData = [];

          for (var entry in data) {
            final startTime = (entry['Start_time'] as num).toDouble();
            final endTime = (entry['End_time'] as num).toDouble();
            final duration = endTime - startTime;
            final speakerName = (entry['Speaker_Name'] ?? 'Unknown Speaker') as String;
            final transcript = (entry['Transcript'] ?? '') as String;

            // Split transcript into sentences based on . ! ?
            final sentences = transcript
                .split(RegExp(r'(?<=[.!?])\s+'))
                .where((s) => s.trim().isNotEmpty)
                .toList();

            if (duration <= 30 || sentences.length <= 1) {
              // If duration is 30s or less, or only one sentence, keep as one chunk
              splitData.add(entry);
            } else {
              // Calculate time per sentence and aim for ~30s chunks
              final timePerSentence = duration / sentences.length;
              double currentTime = startTime;
              List<String> currentChunkSentences = [];
              double currentChunkDuration = 0.0;

              for (int i = 0; i < sentences.length; i++) {
                currentChunkSentences.add(sentences[i]);
                currentChunkDuration += timePerSentence;

                // Check if we've reached ~30s or it's the last sentence
                if (currentChunkDuration >= 25.0 || i == sentences.length - 1) {
                  final chunkEndTime = currentTime + currentChunkDuration;
                  final clampedEndTime = chunkEndTime.clamp(currentTime, endTime);

                  splitData.add({
                    'Speaker_Name': speakerName,
                    'Transcript': currentChunkSentences.join(' '),
                    'Start_time': currentTime,
                    'End_time': clampedEndTime,
                  });

                  // Reset for next chunk
                  currentTime = clampedEndTime;
                  currentChunkSentences = [];
                  currentChunkDuration = 0.0;
                }
              }
            }
          }

          // Update messages with the split data
          messages.value = splitData.map<Map<String, String>>((entry) {
            final speakerName = (entry['Speaker_Name'] ?? 'Unknown Speaker') as String;
            final transcript = (entry['Transcript'] ?? '') as String;
            final startTimeFormatted = formatTimestamp((entry['Start_time'] as num).toDouble());
            final endTimeFormatted = formatTimestamp((entry['End_time'] as num).toDouble());

            return {
              'name': speakerName,
              'time': '$startTimeFormatted - $endTimeFormatted',
              'description': transcript,
            };
          }).toList();

          // Sync scrolling with audio
          final audioController = Get.find<AudioPlayerController>();
          audioController.playAudio();
          syncScrollingWithAudio(audioController);
        } else {
          // Fetch transcription from the API
          final response = await _apiService.fetchTranscription(filePath);

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            final data = jsonData['Data'] as List;
            List<Map<String, dynamic>> splitData = [];

            for (var entry in data) {
              final startTime = (entry['Start_time'] as num).toDouble();
              final endTime = (entry['End_time'] as num).toDouble();
              final duration = endTime - startTime;
              final speakerName = (entry['Speaker_Name'] ?? 'Unknown Speaker') as String;
              final transcript = (entry['Transcript'] ?? '') as String;

              // Split transcript into sentences based on . ! ?
              final sentences = transcript
                  .split(RegExp(r'(?<=[.!?])\s+'))
                  .where((s) => s.trim().isNotEmpty)
                  .toList();

              if (duration <= 30 || sentences.length <= 1) {
                // If duration is 30s or less, or only one sentence, keep as one chunk
                splitData.add(entry);
              } else {
                // Calculate time per sentence and aim for ~30s chunks
                final timePerSentence = duration / sentences.length;
                double currentTime = startTime;
                List<String> currentChunkSentences = [];
                double currentChunkDuration = 0.0;

                for (int i = 0; i < sentences.length; i++) {
                  currentChunkSentences.add(sentences[i]);
                  currentChunkDuration += timePerSentence;

                  // Check if we've reached ~30s or it's the last sentence
                  if (currentChunkDuration >= 25.0 || i == sentences.length - 1) {
                    final chunkEndTime = currentTime + currentChunkDuration;
                    final clampedEndTime = chunkEndTime.clamp(currentTime, endTime);

                    splitData.add({
                      'Speaker_Name': speakerName,
                      'Transcript': currentChunkSentences.join(' '),
                      'Start_time': currentTime,
                      'End_time': clampedEndTime,
                    });

                    // Reset for next chunk
                    currentTime = clampedEndTime;
                    currentChunkSentences = [];
                    currentChunkDuration = 0.0;
                  }
                }
              }
            }

            // Update the transcription in the database
            await db.update(
              'audio_files',
              {'transcription': json.encode(splitData)},
              where: 'file_path = ?',
              whereArgs: [filePath],
            );

            messages.value = splitData.map<Map<String, String>>((entry) {
              final speakerName = (entry['Speaker_Name'] ?? 'Unknown Speaker') as String;
              final transcript = (entry['Transcript'] ?? '') as String;
              final startTimeFormatted = formatTimestamp((entry['Start_time'] as num).toDouble());
              final endTimeFormatted = formatTimestamp((entry['End_time'] as num).toDouble());

              return {
                'name': speakerName,
                'time': '$startTimeFormatted - $endTimeFormatted',
                'description': transcript,
              };
            }).toList();

            // Sync scrolling with audio
            //final audioController = Get.find<AudioPlayerController>();
            //audioController.playAudio();
            //syncScrollingWithAudio(audioController);
          } else {
            Get.snackbar('Error', 'Failed to fetch data: ${response.reasonPhrase}');
          }
        }
      } else {
        Get.snackbar('Error', 'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching messages: $e');
      print(':::::::::::::::::::::::::::::::::Error : $e');
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