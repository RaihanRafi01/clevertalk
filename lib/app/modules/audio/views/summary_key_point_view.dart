import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/database_helper.dart';

class SummaryKeyPointView extends StatefulWidget {
  final String keyPoints;
  final String fileName; // Identify which file is being edited

  const SummaryKeyPointView({super.key, required this.keyPoints, required this.fileName});

  @override
  _SummaryKeyPointViewState createState() => _SummaryKeyPointViewState();
}

class _SummaryKeyPointViewState extends State<SummaryKeyPointView> {
  late TextEditingController titleController;
  List<Map<String, String>> mainPoints = [];
  List<Map<String, String>> conclusions = [];
  List<TextEditingController> mainPointTitleControllers = [];
  List<TextEditingController> mainPointValueControllers = [];
  List<TextEditingController> conclusionTitleControllers = [];
  List<TextEditingController> conclusionValueControllers = [];
  RxBool isEditing = false.obs; // Toggle Edit Mode

  @override
  void initState() {
    super.initState();

    // Parse JSON string
    final Map<String, dynamic> data = json.decode(widget.keyPoints);

    // Initialize title
    titleController = TextEditingController(text: data["Title"]?.toString() ?? "No Title");

    // Convert and initialize key points
    mainPoints = (data["Main Points"] as List?)
        ?.map((e) => (e as Map<String, dynamic>)
        .map((key, value) => MapEntry(key.toString(), value.toString())))
        .toList() ??
        [];

    // Convert and initialize conclusions
    conclusions = (data["Conclusions"] as List?)
        ?.map((e) => (e as Map<String, dynamic>)
        .map((key, value) => MapEntry(key.toString(), value.toString())))
        .toList() ??
        [];

    // Initialize controllers for key points and conclusions
    _initializeControllers();
  }

  void _initializeControllers() {
    mainPointTitleControllers = mainPoints.map((point) {
      return TextEditingController(text: point.keys.first);
    }).toList();

    mainPointValueControllers = mainPoints.map((point) {
      return TextEditingController(text: point.values.first);
    }).toList();

    conclusionTitleControllers = conclusions.map((point) {
      return TextEditingController(text: point.keys.first);
    }).toList();

    conclusionValueControllers = conclusions.map((point) {
      return TextEditingController(text: point.values.first);
    }).toList();
  }

  @override
  void dispose() {
    titleController.dispose();
    for (var controller in mainPointTitleControllers) {
      controller.dispose();
    }
    for (var controller in mainPointValueControllers) {
      controller.dispose();
    }
    for (var controller in conclusionTitleControllers) {
      controller.dispose();
    }
    for (var controller in conclusionValueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to save changes to database
  Future<void> saveKeyPoints() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Update main points with new values
    for (int i = 0; i < mainPoints.length; i++) {
      mainPoints[i] = {
        mainPointTitleControllers[i].text: mainPointValueControllers[i].text
      };
    }

    // Update conclusions with new values
    for (int i = 0; i < conclusions.length; i++) {
      conclusions[i] = {
        conclusionTitleControllers[i].text: conclusionValueControllers[i].text
      };
    }

    // Construct updated JSON
    final updatedData = {
      "Title": titleController.text,
      "Main Points": mainPoints,
      "Conclusions": conclusions,
    };

    final updatedJson = json.encode(updatedData);

    // Update the database
    await db.update(
      'audio_files',
      {'key_point': updatedJson},
      where: 'file_name = ?',
      whereArgs: [widget.fileName],
    );

    // Show success message
    Get.snackbar("Success", "Key Points updated successfully!");

    // Exit edit mode
    isEditing.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {},
        onSecondIconPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Edit Button
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() => IconButton(
                  icon: Icon(
                    isEditing.value ? Icons.save : Icons.edit,
                    color: Colors.blue,
                    size: 28,
                  ),
                  onPressed: () {
                    if (isEditing.value) {
                      saveKeyPoints(); // Save when exiting edit mode
                    }
                    isEditing.toggle(); // Toggle edit mode
                  },
                )),
              ),

              // Editable Title
              Obx(() => isEditing.value
                  ? TextField(
                controller: titleController,
                style: h1.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              )
                  : Text(
                titleController.text,
                style: h1.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
              )),
              SizedBox(height: 20),

              // Key Points
              Text(
                'Key Points:',
                style: h2.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Obx(() => isEditing.value
                  ? _buildEditableList(mainPoints, mainPointTitleControllers, mainPointValueControllers)
                  : _buildReadOnlyList(mainPoints)),

              SizedBox(height: 20),

              // Conclusions
              if (conclusions.isNotEmpty) ...[
                Text(
                  'Conclusions:',
                  style: h2.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Obx(() => isEditing.value
                    ? _buildEditableList(conclusions, conclusionTitleControllers, conclusionValueControllers)
                    : _buildReadOnlyList(conclusions)),
              ],

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Builds Editable List for Key Points & Conclusions (Title + Value)
  Widget _buildEditableList(List<Map<String, String>> list, List<TextEditingController> titleControllers, List<TextEditingController> valueControllers) {
    return Column(
      children: List.generate(list.length, (index) {
        TextEditingController titleController = titleControllers[index];
        TextEditingController valueController = valueControllers[index];

        return Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextField(
                controller: titleController,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Key Point Title",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Value Field
              TextField(
                controller: valueController,
                style: h4.copyWith(fontSize: 16),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Builds Read-Only List for Viewing Mode
  Widget _buildReadOnlyList(List<Map<String, String>> list) {
    return Column(
      children: list.map((point) {
        String key = point.keys.first;
        String value = point.values.first;

        return Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• $key", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 4),
                child: Text(value, style: h4.copyWith(fontSize: 18)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
