import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/audio_text/customListTile.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/database_helper.dart';
import 'convert_to_text_view.dart';

class TextView extends StatefulWidget {
  const TextView({super.key});

  @override
  _TextViewState createState() => _TextViewState();
}

class _TextViewState extends State<TextView> {
  List<Map<String, dynamic>> _textFiles = [];

  @override
  void initState() {
    super.initState();
    _fetchTextFiles();
  }

  Future<void> _fetchTextFiles() async {
    final dbHelper = DatabaseHelper();
    final textFiles = await dbHelper.fetchAudioFiles(context);

    setState(() {
      _textFiles = textFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isSearch: true,
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          print("Second icon pressed");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Text', style: h1.copyWith(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _textFiles.isEmpty
                  ? Center(
                child: Text(
                  'No text files available',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.separated(
                itemCount: _textFiles.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.grey,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final textFile = _textFiles[index];
                  final fileName = textFile['file_name'] ?? 'Unknown Title';
                  final parsedDate = parseFileNameToDate(fileName);
                  final filePath = textFile['file_path'];

                  return GestureDetector(
                    onTap: () => Get.to(() => ConvertToTextView(fileName: fileName, filePath: filePath,)),
                    child: CustomListTile(
                      title: fileName,
                      subtitle: parsedDate,
                      duration: textFile['duration'] ?? '00:00:00',
                      showPlayIcon: false,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 58),
          ],
        ),
      ),
    );
  }

  String parseFileNameToDate(String fileName) {
    try {
      final dateTimePart = fileName.substring(1, fileName.indexOf('.'));
      final datePart = dateTimePart.split('-')[0]; // e.g., 20250112
      final timePart = dateTimePart.split('-')[1]; // e.g., 142010

      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(timePart.substring(0, 2));
      final minute = int.parse(timePart.substring(2, 4));
      final second = int.parse(timePart.substring(4, 6));

      final dateTime = DateTime(year, month, day, hour, minute, second);

      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Unknown Date';
    }
  }
}
