import 'dart:convert';
import 'dart:io';
import 'package:clevertalk/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../config/secrets.dart';
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
  String parsedDate = "Unknown Date";
  var title = ''.obs;
  var duration = ''.obs;
  final ItemScrollController itemScrollController = ItemScrollController();
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> descControllers = [];

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchMessages(String filePath) async {
    print(
        '::::::::::::::::::::::::::::::::::::HITTING TRANS ::::::::::::::::::::::::::::::');
    final ApiService _apiService = ApiService();
    try {
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
        title.value = result.first['file_name'].toString();
        parsedDate = result.first['parsed_date']?.toString() ?? "Unknown Date";

        duration.value = result.first['duration']?.toString() ?? "00:00:00";
        currentLanguage.value =
            result.first['language_transcription']?.toString() ?? 'English';

        print(':::::::::::duration.value::::::::duration.value:::::duration.value::::::::::::CODE: ${duration.value}');
        final homeController = Get.find<HomeController>();

        final durationParts = duration.value.split(':');
        final minutes = int.parse(durationParts[0]);
        final seconds = int.parse(durationParts[1]);
        final totalDurationSeconds = minutes * 60 + seconds;

        final totalMinutesLeftSeconds = homeController.total_minutes_left.value * 60;

        if (existingTranscription != null && existingTranscription.toString().isNotEmpty) {
          final data = json.decode(existingTranscription.toString()) as List;
          _updateMessages(data);
        }
        else if (totalMinutesLeftSeconds < totalDurationSeconds) {
          print('::::::::::::::::::::::Insufficient time left! Total time left (${homeController.total_minutes_left.value} minutes = ${totalMinutesLeftSeconds} seconds) is less than duration (${minutes} minutes ${seconds} seconds = ${totalDurationSeconds} seconds).');
        } else {
          final response = await _apiService.fetchTranscription(filePath);

          print(
              '::::::::::::::::::::::::::::::::::::CODE: ${response.statusCode}');
          print('::::::::::::::::::::::::::::::::::::body: ${response.body}');

          if (response.statusCode == 200) {
            //// UPDATE TIME

            final r1 = await _apiService.useMinute(duration.value);

            print(
                '::::::::::::::::::r1::::::::::::::::::CODE: ${r1.statusCode}');
            print('::::::::::::::::::r1::::::::::::::::::body: ${r1.body}');

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

  Future<void> saveTranscription(String filePath, bool snackBar) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    messages.value = List.generate(
      messages.length,
      (i) => {
        'name': nameControllers[i].text,
        'time': messages[i]['time']!,
        'description': descControllers[i].text,
      },
    );

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
    if (snackBar) {
      Get.snackbar("Success", "Transcription saved!");
    }
    isEditing.value = false;
  }

  Future<void> translateText(String filePath, String fileName) async {
    Get.snackbar(
      duration: const Duration(seconds: 4),
      'Translation in progress...',
      'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready.',
    );

    try {
      const apiUrl = 'https://api.openai.com/v1/chat/completions';
      const chunkSize = 20;

      final allMessages = messages.map((msg) {
        final times = msg['time']!.split(' - ');
        return {
          'Speaker_Name': msg['name'],
          'Transcript': msg['description'],
          'Start_time': parseTimeToSeconds(times[0]),
          'End_time': parseTimeToSeconds(times[1]),
        };
      }).toList();

      List<List<Map<String, dynamic>>> chunks = [];
      for (int i = 0; i < allMessages.length; i += chunkSize) {
        final end = (i + chunkSize < allMessages.length)
            ? i + chunkSize
            : allMessages.length;
        chunks.add(allMessages.sublist(i, end));
      }

      List<Map<String, dynamic>> translatedData = [];
      for (var chunk in chunks) {
        final textToTranslate = json.encode(chunk);

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
                    'You are a precise JSON translator. Return only valid JSON without additional text.',
              },
              {
                'role': 'user',
                'content':
                    'Translate the following JSON content from ${currentLanguage.value} to ${selectedLanguage.value}:\n\n$textToTranslate',
              },
            ],
            'max_tokens': 8000,
          }),
        );
        print(':::::::::::::::: -------------------->>> translation statusCode ${response.statusCode}');
        print(':::::::::::::::: -------------------->>> translation body ${response.body}');

        if (response.statusCode == 200) {
          final responseBody = utf8.decode(response.bodyBytes);
          final jsonData = json.decode(responseBody);
          final translatedText = jsonData['choices'][0]['message']['content'];
          final chunkData = json.decode(translatedText) as List;
          translatedData.addAll(chunkData.cast<Map<String, dynamic>>());
        } else {
          Get.snackbar('Error', 'Translation failed: ${response.statusCode}');
          return;
        }
      }

      _updateMessages(translatedData);
      currentLanguage.value = selectedLanguage.value;
      await saveTranscription(filePath, false);
      NotificationService.showNotification(
        title: "Translation Ready!",
        body: "Click to view Translation",
        payload: "Conversion",
        keyPoints: filePath,
        fileName: fileName,
        filePath: filePath,
      );
    } catch (e) {
      Get.snackbar('Error', 'Translation error: $e');
      print('Error: $e');
    }
  }

  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();

    final notoSansFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
    final notoSansSCFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSansSC-Regular.ttf"));
    final notoSansDevanagariFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf"));

    String date;
    String time;
    final dateTimeString = parsedDate;
    if (dateTimeString == "Unknown Date") {
      date = "Unknown Date";
      time = "Unknown Time";
    } else {
      try {
        final dateTime = DateTime.parse(dateTimeString);
        date = DateFormat('d MMMM y').format(dateTime);
        time = DateFormat('h:mm a').format(dateTime);
      } catch (e) {
        date = "Invalid Date";
        time = "Invalid Time";
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final List<pw.Widget> pageContent = [];
          final double pageHeight = PdfPageFormat.a4.height - 64;
          const double titleHeight = 60.0;
          const double itemSpacing = 10.0;
          double currentHeight = 0.0;
          List<pw.Widget> currentPageItems = [];
          bool isFirstPage = true;

          if (isFirstPage) {
            currentPageItems.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Transcription of ${title.value}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      font: notoSansFont,
                      fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Date: $date',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          font: notoSansFont,
                          fontFallback: [
                            notoSansSCFont,
                            notoSansDevanagariFont
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'Time: $time',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          font: notoSansFont,
                          fontFallback: [
                            notoSansSCFont,
                            notoSansDevanagariFont
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            );
            currentHeight += titleHeight;
            isFirstPage = false;
          }

          for (var msg in messages) {
            final item = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '• ',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        font: notoSansFont,
                        fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                      ),
                    ),
                    pw.Flexible(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: '${msg['name']}: ',
                              style: pw.TextStyle(
                                fontSize: 18,
                                font: notoSansFont,
                                fontWeight: pw.FontWeight.bold, // Bold the name
                                fontFallback: [
                                  notoSansSCFont,
                                  notoSansDevanagariFont
                                ],
                              ),
                            ),
                            pw.TextSpan(
                              text: msg['description'] ?? 'No description',
                              style: pw.TextStyle(
                                fontSize: 15,
                                font: notoSansFont,
                                fontFallback: [
                                  notoSansSCFont,
                                  notoSansDevanagariFont
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, top: 5),
                  child: pw.Text(
                    msg['time'] ?? 'No time',
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: notoSansFont,
                      fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            );

            const estimatedItemHeight = 50.0;
            if (currentHeight + estimatedItemHeight + itemSpacing >
                pageHeight) {
              pageContent.add(pw.Column(children: currentPageItems));
              currentPageItems = [item];
              currentHeight = estimatedItemHeight;
            } else {
              currentPageItems.add(item);
              currentHeight += estimatedItemHeight + itemSpacing;
            }
          }

          if (currentPageItems.isNotEmpty) {
            pageContent.add(pw.Column(children: currentPageItems));
          }

          return pageContent;
        },
      ),
    );

    final file =
        File("${(await getTemporaryDirectory()).path}/transcription.pdf");
    try {
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: "Transcription PDF");
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate or share PDF: $e');
      print('PDF generation/share error: $e');
    }
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
    ever(audioController.currentPosition, (position) {
      if (!isEditing.value) {
        // Prevents unnecessary updates while editing
        updateHighlightAndScroll(position.toDouble());
      }
    });
  }

  void updateHighlightAndScroll(double time) {
    int newHighlightIndex = -1;

    for (int i = 0; i < messages.length; i++) {
      final times = messages[i]['time']!.split(' - ');
      final startTime = parseTimeToSeconds(times[0]);
      final endTime = parseTimeToSeconds(times[1]);

      if (time >= startTime && time < endTime) {
        newHighlightIndex = i;
        break;
      }
    }

    if (newHighlightIndex != -1 &&
        currentHighlightedIndex.value != newHighlightIndex) {
      currentHighlightedIndex.value = newHighlightIndex;
      messages.refresh();

      if (itemScrollController.isAttached) {
        // If the user is seeking, instantly jump to the new position
        itemScrollController.jumpTo(index: newHighlightIndex);
      }
    }

    // Enable smooth scrolling only when audio is playing normally
    if (newHighlightIndex > 0 &&
        !Get.find<AudioPlayerController>().isSeeking.value) {
      _smoothAutoScroll();
    }
  }

  void _smoothAutoScroll() {
    if (!itemScrollController.isAttached) return;

    int nextIndex = currentHighlightedIndex.value + 1;

    // ✅ Ensure we do not scroll unnecessarily when at the first message
    if (nextIndex > 0 && nextIndex < messages.length) {
      itemScrollController.scrollTo(
        index: nextIndex,
        alignment: 0.7, // Moves downward slightly each time
        duration: const Duration(milliseconds: 10000),
        curve: Curves.linear,
      );
    }
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
