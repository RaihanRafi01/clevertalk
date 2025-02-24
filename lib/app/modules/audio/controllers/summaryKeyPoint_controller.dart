import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../../data/services/notification_services.dart';

class SummaryKeyPointController extends GetxController {
  final String fileName;

  SummaryKeyPointController({required this.fileName});

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

  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    dateController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'audio_files',
        columns: ['key_point', 'parsed_date', 'language_summary'],
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        parsedDate = result.first['parsed_date']?.toString() ?? "Unknown Date";
        String? keyPointText = result.first['key_point']?.toString();
        currentLanguage.value = result.first['language_summary']?.toString() ?? 'English';

        if (keyPointText != null && keyPointText.isNotEmpty) {
          final data = json.decode(keyPointText
              .replaceAll(RegExp(r',\s*}'), "}")
              .replaceAll(RegExp(r',\s*\]'), "]")
              .replaceAll(RegExp(r'\s+'), " ")
              .trim());

          titleController.text = data["Title"] ?? "No Title";
          dateController.text = parsedDate;
          mainPoints.value = (data["Main Points"] as List?)
              ?.map((e) => (e as Map<String, dynamic>).map(
                  (k, v) => MapEntry(k.trim(), v.toString().trim())))
              .toList() ??
              [];
          conclusions.value = (data["Conclusions"] as List?)
              ?.map((e) => (e as Map<String, dynamic>).map(
                  (k, v) => MapEntry(k.trim(), v.toString().trim())))
              .toList() ??
              [];
        }
      }

      _initializeControllers();
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e");
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> summaryRegenerate(String filePath, String fileName) async {
    final db = await DatabaseHelper().database;
    try {
      Get.snackbar('Regenerating Summary...', 'Please wait.');
      final response = await _apiService.fetchKeyPoints(filePath, fileName);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final keyPointText = json.decode(response.body)['Data']['content'];
        await db.update(
          'audio_files',
          {'key_point': keyPointText, 'language': 'English'}, // Reset to English on regen
          where: 'file_name = ?',
          whereArgs: [fileName],
        );
        await _loadData();
        NotificationService.showNotification(
          title: "Summary Ready!",
          body: "Click to view Summary",
          payload: "Summary",
          keyPoints: keyPointText,
          fileName: fileName,
        );
      } else {
        Get.snackbar('Error', 'Summary Failed: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    }
  }

  void _initializeControllers() {
    mainPointTitleControllers = mainPoints.map((p) => TextEditingController(text: p.keys.first)).toList();
    mainPointValueControllers = mainPoints.map((p) => TextEditingController(text: p.values.first)).toList();
    conclusionTitleControllers = conclusions.map((p) => TextEditingController(text: p.keys.first)).toList();
    conclusionValueControllers = conclusions.map((p) => TextEditingController(text: p.values.first)).toList();
  }

  Future<void> saveKeyPoints() async {
    final db = await DatabaseHelper().database;
    mainPoints.value = List.generate(mainPoints.length,
            (i) => {mainPointTitleControllers[i].text: mainPointValueControllers[i].text});
    conclusions.value = List.generate(conclusions.length,
            (i) => {conclusionTitleControllers[i].text: conclusionValueControllers[i].text});

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
        'language_summary': currentLanguage.value, // Save current language
      },
      where: 'file_name = ?',
      whereArgs: [fileName],
    );

    Get.snackbar("Success", "Key Points saved!");
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
      TimeOfDay? pickedTime = await showTimePicker(context: Get.context!, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
      }
    }
  }

  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titleController.text, style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 20),
          pw.Text("Key Points:", style: pw.TextStyle(fontSize: 18)),
          for (var point in mainPoints) pw.Text("${point.keys.first}: ${point.values.first}\n"),
          pw.SizedBox(height: 10),
          pw.Text("Conclusions:", style: pw.TextStyle(fontSize: 18)),
          for (var conclusion in conclusions) pw.Text("${conclusion.keys.first}: ${conclusion.values.first}\n"),
        ],
      ),
    ));

    final file = File("${(await getTemporaryDirectory()).path}/summary.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: "Summary Key Points PDF");
  }

  Future<void> translateText() async {
    try {
      isLoading.value = true;
      final textToTranslate = json.encode({
        "Title": titleController.text,
        "Main Points": mainPoints,
        "Conclusions": conclusions,
      });

      const apiKey = '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';
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
            {'role': 'system', 'content': 'You are a precise JSON translator.'},
            {
              'role': 'user',
              'content':
              'Translate the following JSON content from ${currentLanguage.value} to ${selectedLanguage.value} and return only the translated JSON:\n\n$textToTranslate',
            },
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final translatedText = json
            .decode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content']
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final translatedData = json.decode(translatedText);

        titleController.text = translatedData["Title"] ?? "No Title";
        mainPoints.value = (translatedData["Main Points"] as List?)
            ?.map((e) => (e as Map<String, dynamic>).map(
                (k, v) => MapEntry(k.trim(), v.toString().trim())))
            .toList() ??
            [];
        conclusions.value = (translatedData["Conclusions"] as List?)
            ?.map((e) => (e as Map<String, dynamic>).map(
                (k, v) => MapEntry(k.trim(), v.toString().trim())))
            .toList() ??
            [];

        _initializeControllers();
        currentLanguage.value = selectedLanguage.value; // Update language before saving
        await saveKeyPoints(); // Save with new language
        Get.snackbar('Success', 'Translated to ${selectedLanguage.value}');
      } else {
        Get.snackbar('Error', 'Translation failed: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Translation error: $e');
      print('Error: $e');
    } finally {
      isLoading.value = false;
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