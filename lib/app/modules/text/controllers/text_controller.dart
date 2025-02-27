import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../../data/services/notification_services.dart';
import '../../audio/controllers/audio_controller.dart';

class ConvertToTextController extends GetxController {
  var messages = <Map<String, String>>[].obs;
  var highlightedTimestamp = ''.obs;
  var currentHighlightedIndex = (-1).obs;
  var isLoading = false.obs;
  var isEditing = false.obs;
  var isTranslate = false.obs;
  var selectedLanguage = 'English'.obs;
  var currentLanguage = 'English'.obs;
  final ScrollController scrollController = ScrollController();
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> descControllers = [];

  @override
  void onInit() {
    super.onInit();
    //fetchMessages(filePath!);
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
        currentLanguage.value =
            result.first['language_transcription']?.toString() ?? 'English';

        if (existingTranscription != null &&
            existingTranscription.toString().isNotEmpty) {
          // Parse existing transcription
          final data = json.decode(existingTranscription.toString()) as List;
          _updateMessages(data);
        } else {
          // Fetch transcription from the API
          final response = await _apiService.fetchTranscription(filePath);

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            final data = jsonData['Data'] as List;
            await db.update(
              'audio_files',
              {
                'transcription': json.encode(data),
                'language_transcription': 'English'
              },
              where: 'file_path = ?',
              whereArgs: [filePath],
            );
            _updateMessages(data);
          } else {
            Get.snackbar(
                'Error', 'Failed to fetch data: ${response.reasonPhrase}');
          }
        }
      } else {
        Get.snackbar('Error',
            'File not found in the database. Please add the file first.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching messages: $e');
      print(':::::::::::::::::::::::::::::::::Error : $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateMessages(List<dynamic> data) {
    List<Map<String, dynamic>> splitData = [];

    for (var entry in data) {
      final startTime = (entry['Start_time'] as num).toDouble();
      final endTime = (entry['End_time'] as num).toDouble();
      final duration = endTime - startTime;
      final speakerName =
          (entry['Speaker_Name'] ?? 'Unknown Speaker') as String;
      final transcript = (entry['Transcript'] ?? '') as String;

      // Split transcript into sentences based on . ! ?
      final sentences = transcript
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();

      if (duration <= 30 || sentences.length <= 1) {
        splitData.add(entry);
      } else {
        final timePerSentence = duration / sentences.length;
        double currentTime = startTime;
        List<String> currentChunkSentences = [];
        double currentChunkDuration = 0.0;

        for (int i = 0; i < sentences.length; i++) {
          currentChunkSentences.add(sentences[i]);
          currentChunkDuration += timePerSentence;

          if (currentChunkDuration >= 25.0 || i == sentences.length - 1) {
            final chunkEndTime = currentTime + currentChunkDuration;
            final clampedEndTime = chunkEndTime.clamp(currentTime, endTime);

            splitData.add({
              'Speaker_Name': speakerName,
              'Transcript': currentChunkSentences.join(' '),
              'Start_time': currentTime,
              'End_time': clampedEndTime,
            });

            currentTime = clampedEndTime;
            currentChunkSentences = [];
            currentChunkDuration = 0.0;
          }
        }
      }
    }

    messages.value = splitData.map<Map<String, String>>((entry) {
      final speakerName =
          (entry['Speaker_Name'] ?? 'Unknown Speaker') as String;
      final transcript = (entry['Transcript'] ?? '') as String;
      final startTimeFormatted =
          formatTimestamp((entry['Start_time'] as num).toDouble());
      final endTimeFormatted =
          formatTimestamp((entry['End_time'] as num).toDouble());

      return {
        'name': speakerName,
        'time': '$startTimeFormatted - $endTimeFormatted',
        'description': transcript,
      };
    }).toList();

    _initializeControllers();
  }

  void _initializeControllers() {
    nameControllers = messages
        .map((msg) => TextEditingController(text: msg['name']))
        .toList();
    descControllers = messages
        .map((msg) => TextEditingController(text: msg['description']))
        .toList();
  }

  Future<void> saveTranscription(String filePath,bool snackBar) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    messages.value = List.generate(
        messages.length,
        (i) => {
              'name': nameControllers[i].text,
              'time': messages[i]['time']!,
              'description': descControllers[i].text,
            });

    final updatedData = messages.map((msg) {
      final times = msg['time']!.split(' - ');
      return {
        'Speaker_Name': msg['name'],
        'Transcript': msg['description'],
        'Start_time': parseTimeToSeconds(times[0]),
        'End_time': parseTimeToSeconds(times[1]),
      };
    }).toList();

    await db.update(
      'audio_files',
      {
        'transcription': json.encode(updatedData),
        'language_transcription': currentLanguage.value,
      },
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
    if(snackBar){
      Get.snackbar("Success", "Transcription saved!");
    }
    isEditing.value = false;
  }

  Future<void> translateText(String filePath, String fileName) async {
    Get.snackbar('Translation in progress...', 'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to using the app while you wait.');
    try {
      final textToTranslate = json.encode(messages.map((msg) {
        final times = msg['time']!.split(' - ');
        return {
          'Speaker_Name': msg['name'],
          'Transcript': msg['description'],
          'Start_time': parseTimeToSeconds(times[0]),
          'End_time': parseTimeToSeconds(times[1]),
        };
      }).toList());

      const apiKey =
          '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'; // Replace with your OpenAI API key
      const apiUrl = 'https://api.openai.com/v1/chat/completions';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a precise JSON translator. Return only valid JSON without any additional text or markdown.'
            },
            {
              'role': 'user',
              'content':
                  'Translate the following JSON content from ${currentLanguage.value} to ${selectedLanguage.value} and return only the translated JSON:\n\n$textToTranslate',
            },
          ],
          'max_tokens': 8000,
        }),
      );

      if (response.statusCode == 200) {
        // Print raw response for debugging
        print('Raw response: ${response.body}');

        final responseBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(responseBody);
        final translatedText = jsonData['choices'][0]['message']['content']
          ..replaceAll('```json', '').replaceAll('```', '').trim();

        // Print processed text for debugging
        print('Processed text: $translatedText');

        // Attempt to decode translatedText as JSON
        final translatedData = json.decode(translatedText) as List;

        _updateMessages(translatedData);
        currentLanguage.value = selectedLanguage.value;
        await saveTranscription(filePath,false);
        NotificationService.showNotification(
          title: "Translation Ready!",
          body: "Click to view Conversion",
          payload: "Conversion",
          keyPoints: filePath,
          fileName: fileName,
          filePath: filePath,
        );
        // Get.snackbar('Success', 'Translated to ${selectedLanguage.value}');
      } else {
        Get.snackbar('Error',
            'Translation failed: ${response.statusCode} \nPlease Try again later.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Translation error: $e');
      print('Error: $e');
    }
  }

  void editFullTranscription(BuildContext context, String filePath) {
    TextEditingController transcriptionController = TextEditingController();

    String fullText = messages
        .map((msg) => "${msg['name']}: ${msg['description']}")
        .join('\n');
    transcriptionController.text = fullText;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Transcription'),
        content: TextField(
          controller: transcriptionController,
          maxLines: 10,
          decoration:
              const InputDecoration(labelText: 'Edit Full Transcription'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (transcriptionController.text.trim().isEmpty) {
                Get.snackbar("Error", "Transcription cannot be empty!");
                return;
              }

              List<Map<String, dynamic>> updatedMessages =
                  transcriptionController.text
                      .split('\n')
                      .where((line) => line.contains(': '))
                      .map((line) {
                final parts = line.split(': ');
                final speakerName = parts[0].trim();
                final transcript = parts.sublist(1).join(': ').trim();

                final originalEntry = messages.firstWhere(
                  (msg) => msg['name'] == speakerName,
                  orElse: () => {'time': '00:00:00 - 00:00:00'},
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

              if (updatedMessages.isEmpty) {
                Get.snackbar("Error", "Invalid transcription format.");
                return;
              }

              messages.value = updatedMessages
                  .map<Map<String, String>>((entry) => {
                        'name': entry['Speaker_Name'].toString(),
                        'time':
                            '${formatTimestamp(entry['Start_time'] as double)} - ${formatTimestamp(entry['End_time'] as double)}',
                        'description': entry['Transcript'].toString(),
                      })
                  .toList();

              messages.refresh();

              final dbHelper = DatabaseHelper();
              final db = await dbHelper.database;
              await db.update(
                'audio_files',
                {'transcription': json.encode(updatedMessages)},
                where: 'file_path = ?',
                whereArgs: [filePath],
              );

              await fetchMessages(filePath);
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void editSpeakerName(BuildContext context, String filePath) {
    TextEditingController speakerNameController = TextEditingController();
    Set<String> uniqueSpeakers = messages.map((msg) => msg['name']!).toSet();
    String selectedSpeaker =
        uniqueSpeakers.isNotEmpty ? uniqueSpeakers.first : "";

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Speaker Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedSpeaker.isNotEmpty ? selectedSpeaker : null,
              items: uniqueSpeakers.map((speaker) {
                return DropdownMenuItem(value: speaker, child: Text(speaker));
              }).toList(),
              onChanged: (value) {
                selectedSpeaker = value ?? '';
              },
              decoration: const InputDecoration(labelText: "Select Speaker"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: speakerNameController,
              decoration: const InputDecoration(labelText: 'New Speaker Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (speakerNameController.text.trim().isEmpty) {
                Get.snackbar("Error", "Speaker name cannot be empty!");
                return;
              }

              final newSpeakerName = speakerNameController.text.trim();

              for (var msg in messages) {
                if (msg['name'] == selectedSpeaker) {
                  msg['name'] = newSpeakerName;
                }
              }
              messages.refresh();

              final dbHelper = DatabaseHelper();
              final db = await dbHelper.database;
              final result = await db.query(
                'audio_files',
                where: 'file_path = ?',
                whereArgs: [filePath],
              );

              if (result.isNotEmpty) {
                final existingTranscription = result.first['transcription'];
                if (existingTranscription != null &&
                    existingTranscription.toString().isNotEmpty) {
                  List<dynamic> data =
                      json.decode(existingTranscription.toString());
                  for (var entry in data) {
                    if (entry['Speaker_Name'] == selectedSpeaker) {
                      entry['Speaker_Name'] = newSpeakerName;
                    }
                  }
                  await db.update(
                    'audio_files',
                    {'transcription': json.encode(data)},
                    where: 'file_path = ?',
                    whereArgs: [filePath],
                  );
                }
              }

              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void syncScrollingWithAudio(AudioPlayerController audioController) {
    audioController.currentPosition.listen((position) {
      final currentTimestamp = position;

      final index = messages.indexWhere((msg) {
        final times = msg['time']!.split(' - ');
        final startTime = parseTimeToSeconds(times[0]);
        final endTime = parseTimeToSeconds(times[1]);
        return currentTimestamp >= startTime &&
            currentTimestamp <= (endTime + 0.5);
      });

      if (index != -1 && currentHighlightedIndex.value != index) {
        currentHighlightedIndex.value = index;
        final scrollPosition = index * 125.0;
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

  @override
  void onClose() {
    nameControllers.forEach((c) => c.dispose());
    descControllers.forEach((c) => c.dispose());
    scrollController.dispose();
    super.onClose();
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
