import 'dart:convert';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database_helper.dart';

class SummaryKeyPointController extends GetxController {
  final String keyPoints;
  final String fileName;

  SummaryKeyPointController({required this.keyPoints, required this.fileName});

  late TextEditingController titleController;
  late TextEditingController dateController;
  List<Map<String, String>> mainPoints = [];
  List<Map<String, String>> conclusions = [];
  List<TextEditingController> mainPointTitleControllers = [];
  List<TextEditingController> mainPointValueControllers = [];
  List<TextEditingController> conclusionTitleControllers = [];
  List<TextEditingController> conclusionValueControllers = [];
  RxBool isEditing = false.obs;
  RxBool isLoading = true.obs; // Add a loading state
  String parsedDate = "Unknown Date";

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers immediately
    titleController = TextEditingController();
    dateController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.query(
        'audio_files',
        columns: ['parsed_date'],
        where: 'file_name = ?',
        whereArgs: [fileName],
      );

      if (result.isNotEmpty) {
        parsedDate = result.first['parsed_date']?.toString() ?? "Unknown Date";
      }

      // Validate and clean JSON before parsing
      String cleanedJson = keyPoints.replaceAll(RegExp(r',\s*}'), "}").replaceAll(RegExp(r',\s*\]'), "]");

      final Map<String, dynamic> data = json.decode(cleanedJson);

      titleController.text = data["Title"]?.toString() ?? "No Title";
      dateController.text = parsedDate;

      mainPoints = (data["Main Points"] as List?)
          ?.map((e) => (e as Map<String, dynamic>).map(
              (key, value) => MapEntry(key.toString(), value.toString())))
          .toList() ??
          [];

      conclusions = (data["Conclusions"] as List?)
          ?.map((e) => (e as Map<String, dynamic>).map(
              (key, value) => MapEntry(key.toString(), value.toString())))
          .toList() ??
          [];

      _initializeControllers();
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e");
      print(':::::::::::::::::::Error: $e');
    } finally {
      isLoading.value = false; // Data loading is complete
    }
  }


  void _initializeControllers() {
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

  /// Generates and shares the PDF
  Future<void> generateAndSharePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titleController.text,
                style: pw.TextStyle(
                  fontSize: 20,
                ),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            pw.Text(
              "Key Points :",
              style: pw.TextStyle(fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            for (var point in mainPoints)
              pw.Text("${point.keys.first}:\n${point.values.first}\n\n",
                  style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text(
              "Conclusions :",
              style: pw.TextStyle(fontSize: 18),
            ),
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
