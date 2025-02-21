import 'dart:convert';
import 'dart:io';
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
  final String fileName; // We only need fileName now, not keyPoints

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
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Fetch the latest key_point and parsed_date from the database
      final result = await db.query(
        'audio_files',
        columns: ['key_point', 'parsed_date'],
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        parsedDate = result.first['parsed_date']?.toString() ?? "Unknown Date";
        String? keyPointText = result.first['key_point']?.toString();

        if (keyPointText != null && keyPointText.isNotEmpty) {
          String cleanedJson = keyPointText
              .replaceAll(RegExp(r',\s*}'), "}")
              .replaceAll(RegExp(r',\s*\]'), "]")
              .replaceAll(RegExp(r'\s+'), " ")
              .trim();

          final Map<String, dynamic> data = json.decode(cleanedJson);

          titleController.text = data["Title"]?.toString() ?? "No Title";
          dateController.text = parsedDate;

          mainPoints.value = (data["Main Points"] as List?)
              ?.map((e) => (e as Map<String, dynamic>).map(
                  (key, value) => MapEntry(key.toString().trim(), value.toString().trim())))
              .toList() ??
              [];
          conclusions.value = (data["Conclusions"] as List?)
              ?.map((e) => (e as Map<String, dynamic>).map(
                  (key, value) => MapEntry(key.toString().trim(), value.toString().trim())))
              .toList() ??
              [];
        } else {
          // Handle case where key_point is null or empty
          titleController.text = "No Title";
          dateController.text = parsedDate;
          mainPoints.clear();
          conclusions.clear();
        }
      } else {
        // No record found in the database
        titleController.text = "No Title";
        dateController.text = "Unknown Date";
        mainPoints.clear();
        conclusions.clear();
      }

      _initializeControllers();
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e");
      print(':::::::::::::::::::Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> summaryRegenerate(String filePath, String fileName) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      Get.snackbar('Summarization Regenerate in progress...', 'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to using the app while you wait.');
      final response = await _apiService.fetchKeyPoints(filePath, fileName);

      print('::::::::::statusCode::::::::::::::::${response.statusCode}');
      print('::::::::body1::::::::::::::::::${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final keyPointText = jsonResponse['Data']['content'];

        // Update the database
        await db.update(
          'audio_files',
          {'key_point': keyPointText},
          where: 'file_name = ?',
          whereArgs: [fileName],
        );
        // Reload data from the database and update UI
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
      Get.snackbar('Error', 'Error fetching transcription: $e');
    }
  }

  void _initializeControllers() {
    // Dispose old controllers to prevent memory leaks
    mainPointTitleControllers.forEach((controller) => controller.dispose());
    mainPointValueControllers.forEach((controller) => controller.dispose());
    conclusionTitleControllers.forEach((controller) => controller.dispose());
    conclusionValueControllers.forEach((controller) => controller.dispose());

    // Reinitialize controllers with new data
    mainPointTitleControllers = mainPoints
        .map((point) => TextEditingController(text: point.keys.first))
        .toList();
    mainPointValueControllers = mainPoints
        .map((point) => TextEditingController(text: point.values.first))
        .toList();
    conclusionTitleControllers = conclusions
        .map((point) => TextEditingController(text: point.keys.first))
        .toList();
    conclusionValueControllers = conclusions
        .map((point) => TextEditingController(text: point.values.first))
        .toList();
  }

  Future<void> saveKeyPoints() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    for (int i = 0; i < mainPoints.length; i++) {
      mainPoints[i] = {
        mainPointTitleControllers[i].text: mainPointValueControllers[i].text
      };
    }

    for (int i = 0; i < conclusions.length; i++) {
      conclusions[i] = {
        conclusionTitleControllers[i].text: conclusionValueControllers[i].text
      };
    }

    final updatedData = {
      "Title": titleController.text,
      "Main Points": mainPoints,
      "Conclusions": conclusions,
    };

    final updatedJson = json.encode(updatedData);

    await db.update(
      'audio_files',
      {
        'key_point': updatedJson,
        'parsed_date': dateController.text,
      },
      where: 'file_name = ?',
      whereArgs: [fileName],
    );

    Get.snackbar("Success", "Key Points updated successfully!");
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
        context: Get.context!,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        dateController.text =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
      }
    }
  }

  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titleController.text,
                style: pw.TextStyle(fontSize: 20),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            pw.Text("Key Points :", style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            for (var point in mainPoints)
              pw.Text("${point.keys.first}:\n${point.values.first}\n\n",
                  style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text("Conclusions :", style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            for (var conclusion in conclusions)
              pw.Text("${conclusion.keys.first}:\n${conclusion.values.first}\n\n",
                  style: pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/summary.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: "Summary Key Points PDF");
  }

  @override
  void onClose() {
    titleController.dispose();
    dateController.dispose();
    mainPointTitleControllers.forEach((controller) => controller.dispose());
    mainPointValueControllers.forEach((controller) => controller.dispose());
    conclusionTitleControllers.forEach((controller) => controller.dispose());
    conclusionValueControllers.forEach((controller) => controller.dispose());
    super.onClose();
  }
}

class LanguageController extends GetxController {
  RxString selectedLanguage = 'Spanish'.obs;

  void updateLanguage(String? newValue) {
    if (newValue != null) {
      selectedLanguage.value = newValue;
      update();
    }
  }
}