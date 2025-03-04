import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  var title = ''.obs;
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
        title.value = result.first['file_name'].toString();
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

  Future<void> saveTranscription(String filePath, bool snackBar) async {
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
    if (snackBar) {
      Get.snackbar("Success", "Transcription saved!");
    }
    isEditing.value = false;
  }

  Future<void> translateText(String filePath, String fileName) async {
    Get.snackbar(
      duration: Duration(seconds: 4),
      'Translation in progress...',
      'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to use the app while you wait.',
    );

    ;

    try {
      const apiKey =
          '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';
      const apiUrl = 'https://api.openai.com/v1/chat/completions';
      const chunkSize = 20; // Adjust based on testing (e.g., 5 messages per chunk)

      // Prepare the full list of messages
      final allMessages = messages.map((msg) {
        final times = msg['time']!.split(' - ');
        return {
          'Speaker_Name': msg['name'],
          'Transcript': msg['description'],
          'Start_time': parseTimeToSeconds(times[0]),
          'End_time': parseTimeToSeconds(times[1]),
        };
      }).toList();

      print('::::::::::::::::::::::::::::::::::::::::::::::: TOTAL messages ${allMessages.length}');

      // Split into chunks
      List<List<Map<String, dynamic>>> chunks = [];
      for (int i = 0; i < allMessages.length; i += chunkSize) {
        final end = (i + chunkSize < allMessages.length) ? i + chunkSize : allMessages.length;
        chunks.add(allMessages.sublist(i, end));
      }

      // Translate each chunk
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
                'You are a precise JSON translator. Return only valid JSON without any additional text or markdown. If the input is too long, process it and return a valid JSON response, even if partial.',
              },
              {
                'role': 'user',
                'content':
                'Translate the following JSON content from ${currentLanguage.value} to ${selectedLanguage.value} and return only the translated JSON:\n\n$textToTranslate',
              },
            ],
            'max_tokens': 8000, // Lowered to ensure response fits (adjust as needed)
          }),
        );

        if (response.statusCode == 200) {
          print('Raw response for chunk: ${response.body}');
          final responseBody = utf8.decode(response.bodyBytes);
          final jsonData = json.decode(responseBody);
          final translatedText = jsonData['choices'][0]['message']['content'];

          print('Processed text for chunk: $translatedText');

          try {
            final chunkData = json.decode(translatedText) as List;
            translatedData.addAll(chunkData.cast<Map<String, dynamic>>());
          } catch (e) {
            print('JSON decode error for chunk: $e');
            Get.snackbar('Error', 'Partial translation failed: $e');
            return;
          }
        } else {
          Get.snackbar('Error', 'Translation failed for chunk: ${response.statusCode}');
          return;
        }
      }

      // Update messages with the combined translated data
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

    // Load fonts from assets
    final notoSansFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
    final notoSansSCFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansSC-Regular.ttf"));
    final notoSansDevanagariFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf"));

    print('Generating PDF with messages: $messages');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32), // Add margins for better layout
        build: (pw.Context context) {
          final List<pw.Widget> pageContent = [];
          final double pageHeight = PdfPageFormat.a4.height - 64; // 778 points
          const double titleHeight = 60.0; // Estimated height for title section
          const double itemSpacing = 10.0; // Space between items
          double currentHeight = 0.0;
          List<pw.Widget> currentPageItems = [];
          bool isFirstPage = true; // Track if title has been added

          // Add title only on the first page
          if (isFirstPage) {
            currentPageItems.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Transcription of ${title.value}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      font: notoSansFont,
                      fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            );
            currentHeight += titleHeight;
            isFirstPage = false; // Ensure title is only added once
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
                      child: pw.Text(
                        '${msg['name']}: ${msg['description'] ?? 'No description'}',
                        style: pw.TextStyle(
                          fontSize: 15,
                          font: notoSansFont,
                          fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, top: 4),
                  child: pw.Text(
                    msg['time'] ?? 'No time',
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: notoSansFont,
                      fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                    ),
                  ),
                ),
              ],
            );

            // Estimate item height (rough approximation)
            const estimatedItemHeight = 50.0; // Adjust based on testing
            if (currentHeight + estimatedItemHeight + itemSpacing > pageHeight) {
              pageContent.add(pw.Column(children: currentPageItems));
              currentPageItems = [item];
              currentHeight = estimatedItemHeight;
            } else {
              currentPageItems.add(item);
              currentHeight += estimatedItemHeight + itemSpacing;
            }
          }

          // Add the last page if there are remaining items
          if (currentPageItems.isNotEmpty) {
            pageContent.add(pw.Column(children: currentPageItems));
          }

          print('Total pages generated: ${pageContent.length}');
          return pageContent;
        },
        // maxPages: 100, // Removed for now; reintroduce if needed
      ),
    );

    final file = File("${(await getTemporaryDirectory()).path}/transcription.pdf");
    try {
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: "Transcription PDF");
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate or share PDF: $e');
      print('PDF generation/share error: $e');
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
    audioController.currentPosition.listen((position) async {
      final currentTimestamp = position.toDouble(); // Audio position in seconds
      final totalDuration = audioController.totalDuration.value;

      // Find the message index for highlighting based on currentTimestamp
      int newHighlightIndex = -1;
      for (int i = 0; i < messages.length; i++) {
        final times = messages[i]['time']!.split(' - ');
        final startTime = parseTimeToSeconds(times[0]);
        final endTime = parseTimeToSeconds(times[1]);
        if (currentTimestamp >= startTime &&
            currentTimestamp <= (endTime + 0.5)) {
          newHighlightIndex = i;
          break;
        }
      }

      // Fallback near the end of the audio
      if (newHighlightIndex == -1 && currentTimestamp >= totalDuration - 1.0) {
        newHighlightIndex = messages.length - 1;
        print(
            'Near end detected, forcing highlight to last: $newHighlightIndex');
      }

      // Update highlighted index if changed
      if (currentHighlightedIndex.value != newHighlightIndex) {
        currentHighlightedIndex.value = newHighlightIndex;
        messages.refresh();
        print(
            'Highlighted index updated to: $newHighlightIndex at timestamp: $currentTimestamp');
      }

      // Ensure scroll controller is attached and has content to scroll
      if (!scrollController.hasClients) {
        print('ScrollController not attached yet, skipping scroll');
        return;
      }

      if (messages.isEmpty) {
        print('Messages list is empty, cannot scroll');
        return;
      }

      final maxScrollExtent = scrollController.position.maxScrollExtent;
      if (maxScrollExtent <= 0) {
        print('Max scroll extent is 0, no scrolling possible');
        return;
      }

      final viewportHeight = scrollController.position.viewportDimension;
      final currentScrollPosition = scrollController.offset;

      // Divide 1 hour into 5 parts (720s each) and calculate dynamic offset
      double dynamicOffset;
      const partDuration = 720.0; // 12 minutes per part
      if (currentTimestamp <= partDuration) {
        // Part 1: 0-12 minutes
        dynamicOffset = 10.0 + (currentTimestamp / 10).floor() * 0.05;
      } else if (currentTimestamp <= 2 * partDuration) {
        // Part 2: 12-24 minutes
        final offsetAtPart1 =
            10.0 + (partDuration / 10).floor() * 0.05; // 13.6 at 720s
        final additionalTime = currentTimestamp - partDuration;
        dynamicOffset = offsetAtPart1 + (additionalTime / 10).floor() * 0.05;
      } else if (currentTimestamp <= 3 * partDuration) {
        // Part 3: 24-36 minutes (includes 30min mark)
        final offsetAtPart2 =
            10.0 + (2 * partDuration / 10).floor() * 0.05; // 17.2 at 1440s
        final additionalTime = currentTimestamp - 2 * partDuration;
        dynamicOffset = offsetAtPart2 + (additionalTime / 10).floor() * 0.05;
      } else if (currentTimestamp <= 4 * partDuration) {
        // Part 4: 36-48 minutes
        final offsetAtPart3 =
            10.0 + (3 * partDuration / 10).floor() * 0.05; // 20.8 at 2160s
        final additionalTime = currentTimestamp - 3 * partDuration;
        dynamicOffset = offsetAtPart3 + (additionalTime / 10).floor() * 0.05;
      } else {
        // Part 5: 48-60 minutes
        final offsetAtPart4 =
            10.0 + (4 * partDuration / 10).floor() * 0.03; // 24.4 at 2880s
        final additionalTime = currentTimestamp - 4 * partDuration;
        dynamicOffset = offsetAtPart4 + (additionalTime / 10).floor() * 0.05;
      }

      // Adjust timestamp with dynamic offset
      final adjustedTimestamp =
      (currentTimestamp + dynamicOffset).clamp(0.0, totalDuration);

      // Calculate the proportional scroll position
      final proportion = adjustedTimestamp / totalDuration;
      double proportionalScrollOffset = proportion * maxScrollExtent;

      // Adjust scroll to prioritize the highlighted item
      double targetScrollOffset;
      if (newHighlightIndex != -1) {
        final estimatedItemHeight = maxScrollExtent / messages.length;
        double highlightScrollOffset =
            newHighlightIndex * estimatedItemHeight - (viewportHeight / 2);

        // At or beyond 30 minutes (middle of Part 3), prioritize highlight
        if (currentTimestamp >= 3 * partDuration / 2) {
          // 1080s (18min)
          targetScrollOffset =
              0.7 * highlightScrollOffset + 0.3 * proportionalScrollOffset;
        } else {
          targetScrollOffset =
              (highlightScrollOffset + proportionalScrollOffset) / 2;
        }
      } else {
        targetScrollOffset = proportionalScrollOffset;
      }

      // Clamp the offset
      targetScrollOffset = targetScrollOffset.clamp(0.0, maxScrollExtent);

      print('Scroll calculation - '
          'Timestamp: $currentTimestamp / $totalDuration, '
          'Dynamic Offset: $dynamicOffset, '
          'Adjusted Timestamp: $adjustedTimestamp, '
          'Proportion: $proportion, '
          'Proportional Offset: $proportionalScrollOffset, '
          'Highlighted Index: $newHighlightIndex, '
          'Target Offset: $targetScrollOffset, '
          'Viewport Height: $viewportHeight, '
          'Max Scroll Extent: $maxScrollExtent, '
          'Current Position: $currentScrollPosition');

      // Scroll if significant difference
      if ((targetScrollOffset - currentScrollPosition).abs() > 20.0) {
        try {
          await scrollController.animateTo(
            targetScrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          print('Successfully scrolled to: $targetScrollOffset');
        } catch (e) {
          print('Error during scroll animation: $e');
        }
      } else {
        print('No scroll needed, already near target: $targetScrollOffset');
      }
    }, onError: (error) {
      print('Error in position listener: $error');
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