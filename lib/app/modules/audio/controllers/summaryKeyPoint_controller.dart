import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../common/localization/localization_controller.dart';
import '../../../../config/secrets.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../../data/services/notification_services.dart';

class SummaryKeyPointController extends GetxController {
  final String fileName;
  final String filePath;

  SummaryKeyPointController({required this.fileName, required this.filePath});

  final ApiService _apiService = ApiService();
  late TextEditingController titleController;
  late TextEditingController dateController;

  RxList<Map<String, String>> mainPoints = <Map<String, String>>[].obs;
  RxList<Map<String, String>> conclusions = <Map<String, String>>[].obs;

  List<TextEditingController> mainPointTitleControllers = [];
  List<TextEditingController> mainPointValueControllers = [];
  List<TextEditingController> conclusionTitleControllers = [];
  List<TextEditingController> conclusionValueControllers = [];

  RxBool isEditing = false.obs;
  RxBool isTranslate = false.obs;
  RxBool isLoading = true.obs;
  RxString selectedLanguage = 'English'.obs;
  RxString currentLanguage = 'English'.obs;
  String parsedDate = "Unknown Date";

  RxString keyPointsLabel = 'Key Points:'.obs;
  RxString conclusionsLabel = 'Conclusions:'.obs;

  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    dateController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    // Set loading state and clear existing data to prevent stale data display
    isLoading.value = true;
    mainPoints.clear();
    conclusions.clear();
    titleController.text = '';
    dateController.text = '';
    keyPointsLabel.value = 'Key Points:';
    conclusionsLabel.value = 'Conclusions:';
    mainPointTitleControllers.clear();
    mainPointValueControllers.clear();
    conclusionTitleControllers.clear();
    conclusionValueControllers.clear();

    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'audio_files',
        columns: ['key_point', 'parsed_date', 'language_summary', 'translated_labels'],
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        parsedDate = result.first['parsed_date']?.toString() ?? "Unknown Date";
        String? keyPointText = result.first['key_point']?.toString();
        currentLanguage.value = result.first['language_summary']?.toString() ?? 'English';

        String? translatedLabelsJson = result.first['translated_labels']?.toString();
        if (translatedLabelsJson != null && translatedLabelsJson.isNotEmpty) {
          final labels = json.decode(translatedLabelsJson);
          keyPointsLabel.value = labels['keyPointsLabel'] ?? 'Key Points:';
          conclusionsLabel.value = labels['conclusionsLabel'] ?? 'Conclusions:';
        } else {
          keyPointsLabel.value = 'Key Points:';
          conclusionsLabel.value = 'Conclusions:';
        }

        if (keyPointText != null && keyPointText.isNotEmpty) {
          final data = json.decode(keyPointText
              .replaceAll(RegExp(r',\s*}'), "}")
              .replaceAll(RegExp(r',\s*\]'), "]")
              .replaceAll(RegExp(r'\s+'), " ")
              .trim());

          titleController.text = data["Title"] ?? "No Title";
          dateController.text = parsedDate;
          mainPoints.value = (data["Main Points"] as List?)
              ?.map((e) => (e as Map<String, dynamic>)
              .map((k, v) => MapEntry(k.trim(), v.toString().trim())))
              .toList() ??
              [];
          conclusions.value = (data["Conclusions"] as List?)
              ?.map((e) => (e as Map<String, dynamic>)
              .map((k, v) => MapEntry(k.trim(), v.toString().trim())))
              .toList() ??
              [];
          print("Loaded Main Points: $mainPoints");
          print("Loaded Conclusions: $conclusions");
        }

        // Check if currentLanguage matches settings' language
        final localizationController = Get.find<LocalizationController>();
        if (currentLanguage.value != localizationController.selectedLanguage.value &&
            mainPoints.isNotEmpty) {
          selectedLanguage.value = localizationController.selectedLanguage.value;
          await translateText(filePath, fileName);
        }

        _initializeControllers();
      } else {
        Get.snackbar("Error", "No data found for file: $fileName");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e");
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> summaryRegenerate(String filePath, String fileName) async {
    print('REGENERATE ::::: filePath ::::::::: $filePath');
    print('REGENERATE ::::: fileName ::::::::: $fileName');
    final db = await DatabaseHelper().database;
    try {
      Get.snackbar(
          duration: Duration(seconds: 4),
          'Regenerating Summary...',
          'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to using the app while you wait.');
      final response = await _apiService.fetchKeyPoints(filePath, fileName);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final keyPointText = json.decode(response.body)['Data']['content'];
        String languageCode = json.decode(response.body)['nil_vai_shakil_vai'];
        String language_summary = LocalizationController.languageMap[languageCode] ?? languageCode;

        print(':::::::::nil_vai_shakil_vai::::::::::::language_summary::::::::::::::::::::: $language_summary');
        await db.update(
          'audio_files',
          {
            'key_point': keyPointText,
            'language_summary': 'English',
            'translated_labels': json.encode({
              'keyPointsLabel': 'Key Points:',
              'conclusionsLabel': 'Conclusions:',
            }),
          },
          where: 'file_name = ?',
          whereArgs: [fileName],
        );
        await _loadData();
        NotificationService.showNotification(
            title: "Summary Ready!",
            body: "Click to view Summary",
            payload: "Summary",
            fileName: fileName,
            filePath: filePath);
      } else {
        Get.snackbar('Error', 'Summary Failed: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    }
  }

  void _initializeControllers() {
    mainPointTitleControllers = mainPoints
        .map((p) => TextEditingController(text: p.keys.first))
        .toList();
    mainPointValueControllers = mainPoints
        .map((p) => TextEditingController(text: p.values.first))
        .toList();
    conclusionTitleControllers = conclusions
        .map((p) => TextEditingController(text: p.keys.first))
        .toList();
    conclusionValueControllers = conclusions
        .map((p) => TextEditingController(text: p.values.first))
        .toList();
  }

  Future<void> saveKeyPoints(bool snackBar) async {
    final db = await DatabaseHelper().database;
    mainPoints.value = List.generate(
        mainPoints.length,
            (i) => {
          mainPointTitleControllers[i].text: mainPointValueControllers[i].text
        });
    conclusions.value = List.generate(
        conclusions.length,
            (i) => {
          conclusionTitleControllers[i].text: conclusionValueControllers[i].text
        });

    final updatedData = {
      "Title": titleController.text,
      "Main Points": mainPoints,
      "Conclusions": conclusions,
    };

    await db.update(
      'audio_files',
      {
        'key_point': json.encode(updatedData),
        'parsed_date': dateController.text,
        'language_summary': currentLanguage.value,
        'translated_labels': json.encode({
          'keyPointsLabel': keyPointsLabel.value,
          'conclusionsLabel': conclusionsLabel.value,
        }),
      },
      where: 'file_name = ?',
      whereArgs: [fileName],
    );

    if (snackBar) {
      Get.snackbar("Success", "Transcription saved!");
    }
    isEditing.value = false;
  }

  Future<void> pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
          context: Get.context!, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute));
      }
    }
  }

  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();

    // Load fonts from assets
    final notoSansFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
    final notoSansSCFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansSC-Regular.ttf"));
    final notoSansDevanagariFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf"));

    String date;
    String time;
    final dateTimeString = dateController.text;
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

    pdf.addPage(pw.MultiPage(
      build: (pw.Context context) => [
        // Title
        pw.Text(
          titleController.text,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            font: notoSansFont,
            fontFallback: [notoSansSCFont, notoSansDevanagariFont],
          ),
        ),
        pw.SizedBox(height: 20),
        // Key Points Section Label
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              'Date: $date',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: notoSansFont,
                fontFallback: [notoSansSCFont, notoSansDevanagariFont],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Text(
              'Time: $time',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: notoSansFont,
                fontFallback: [notoSansSCFont, notoSansDevanagariFont],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          keyPointsLabel.value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            font: notoSansFont,
            fontFallback: [notoSansSCFont, notoSansDevanagariFont],
          ),
        ),
        pw.SizedBox(height: 10),
        // Main Points
        ...mainPoints.map((point) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '\u2022 ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: notoSansFont,
                    fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    point.keys.first,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
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
                point.values.first,
                style: pw.TextStyle(
                  fontSize: 15,
                  font: notoSansFont,
                  fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                ),
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        )).toList(),
        // Conclusions Section (if not empty)
        if (conclusions.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            conclusionsLabel.value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: notoSansFont,
              fontFallback: [notoSansSCFont, notoSansDevanagariFont],
            ),
          ),
          pw.SizedBox(height: 10),
          ...conclusions.map((conclusion) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '\u2022 ',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      font: notoSansFont,
                      fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      conclusion.keys.first,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
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
                  conclusion.values.first,
                  style: pw.TextStyle(
                    fontSize: 15,
                    font: notoSansFont,
                    fontFallback: [notoSansSCFont, notoSansDevanagariFont],
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          )).toList(),
        ],
      ],
    ));

    final file = File("${(await getTemporaryDirectory()).path}/summary.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: "Summary Key Points PDF");
  }

  Future<void> translateText(String filePath, String fileName) async {
    Get.snackbar(
      duration: Duration(seconds: 4),
      'Translation in progress...',
      'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to use the app while you wait.',
    );
    try {
      // Ensure data is not empty before translating
      if (mainPoints.isEmpty && conclusions.isEmpty && titleController.text.isEmpty) {
        Get.snackbar('Error', 'No data available to translate');
        return;
      }

      // Prepare separate lists for keys and values, tightly trimmed
      List<String> mainPointKeys = mainPoints.map((point) => point.keys.first.trim()).toList();
      List<String> mainPointValues = mainPoints.map((point) => point.values.first.trim()).toList();
      List<String> conclusionKeys = conclusions.map((point) => point.keys.first.trim()).toList();
      List<String> conclusionValues = conclusions.map((point) => point.values.first.trim()).toList();

      final textToTranslate = json.encode({
        "Title": titleController.text.trim(),
        "MainPoints": {
          "Keys": mainPointKeys,
          "Values": mainPointValues,
        },
        "Conclusions": {
          "Keys": conclusionKeys,
          "Values": conclusionValues,
        },
        "Labels": {
          "Key Points:": keyPointsLabel.value.trim(),
          "Conclusions:": conclusionsLabel.value.trim(),
        },
      });

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
              'content': '''
            You are a precise JSON translator. Translate the provided JSON content from ${currentLanguage.value} to ${selectedLanguage.value}. 
            For "MainPoints" and "Conclusions", translate the "Keys" and "Values" lists separately. 
            Ensure all translated text has no leading or trailing spaces and is tightly formatted. 
            Return a JSON object with the same structure, containing translated "Title", "MainPoints" (with "Keys" and "Values"), "Conclusions" (with "Keys" and "Values"), and "Labels". 
            Return only valid JSON without additional text or markdown.
            '''
            },
            {
              'role': 'user',
              'content': textToTranslate,
            },
          ],
          'max_tokens': 8000,
        }),
      );

      if (response.statusCode == 200) {
        final translatedText = json.decode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'].trim();
        final translatedData = json.decode(translatedText);

        // Update title
        titleController.text = translatedData["Title"]?.trim() ?? "No Title";

        // Parse Main Points with tight trimming
        final translatedMainPointKeys = (translatedData["MainPoints"]["Keys"] as List<dynamic>).map((k) => k.toString().trim()).toList();
        final translatedMainPointValues = (translatedData["MainPoints"]["Values"] as List<dynamic>).map((v) => v.toString().trim()).toList();
        mainPoints.value = List.generate(
          translatedMainPointKeys.length,
              (i) => {translatedMainPointKeys[i]: translatedMainPointValues[i]},
        );

        // Parse Conclusions with tight trimming
        final translatedConclusionKeys = (translatedData["Conclusions"]["Keys"] as List<dynamic>).map((k) => k.toString().trim()).toList();
        final translatedConclusionValues = (translatedData["Conclusions"]["Values"] as List<dynamic>).map((v) => v.toString().trim()).toList();
        conclusions.value = List.generate(
          translatedConclusionKeys.length,
              (i) => {translatedConclusionKeys[i]: translatedConclusionValues[i]},
        );

        // Update labels with tight trimming
        final labels = translatedData["Labels"] as Map<String, dynamic>;
        keyPointsLabel.value = labels["Key Points:"]?.trim() ?? keyPointsLabel.value;
        conclusionsLabel.value = labels["Conclusions:"]?.trim() ?? conclusionsLabel.value;

        // Reinitialize controllers with translated data
        _initializeControllers();
        currentLanguage.value = selectedLanguage.value;
        await saveKeyPoints(false);

        NotificationService.showNotification(
          title: "Summary Translation Ready!",
          body: "Click to view Summary",
          payload: "Summary",
          fileName: fileName,
          filePath: filePath,
        );
      } else {
        Get.snackbar('Error', 'Translation failed: ${response.body}\nPlease try again later.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Translation error: $e');
      print('Error: $e');
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    dateController.dispose();
    mainPointTitleControllers.forEach((c) => c.dispose());
    mainPointValueControllers.forEach((c) => c.dispose());
    conclusionTitleControllers.forEach((c) => c.dispose());
    conclusionValueControllers.forEach((c) => c.dispose());
    super.onClose();
  }
}