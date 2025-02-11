import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../common/widgets/audio_text/customListTile.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/database_helper.dart';
import 'package:intl/intl.dart';

class AudioView extends StatefulWidget {
  const AudioView({super.key});

  @override
  _AudioViewState createState() => _AudioViewState();
}

class _AudioViewState extends State<AudioView> {
  List<Map<String, dynamic>> _audioFiles = [];

  @override
  void initState() {
    super.initState();
    _fetchAudioFiles();
  }

  Future<void> _fetchAudioFiles() async {
    final dbHelper = DatabaseHelper();
    final audioFiles = await dbHelper.fetchAudioFiles();

    setState(() {
      _audioFiles = audioFiles;
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
                child: Text('Audio', style: h1.copyWith(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _audioFiles.isEmpty
                  ? Center(
                child: Text(
                  'No audio files available',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.separated(
                itemCount: _audioFiles.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.grey,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final audioFile = _audioFiles[index];
                  final fileName = audioFile['file_name'] ?? 'Unknown Title';
                  final parsedDate = audioFile['parsed_date'] ?? 'Unknown Date';
                  final id = audioFile['id'];
                  return CustomListTile(
                    title: fileName,
                    subtitle: parsedDate,
                    duration: audioFile['duration'] ?? '00:00:00',
                    id: id,
                    onUpdate: _fetchAudioFiles, // Pass the refresh callback
                    /*onPlayPressed: () {
      _playAudio(audioFile); // Play audio
    },*/
                  );
                },
              ),
            ),
            SizedBox(height: 58),
          ],
        ),
      ),
    );
  }



  String parseFileNameToDate(String fileName) {
    try {
      // Extract the date and time part from the file name
      final dateTimePart = fileName.substring(1, fileName.indexOf('.'));
      final datePart = dateTimePart.split('-')[0]; // 20250112
      final timePart = dateTimePart.split('-')[1]; // 142010

      // Parse date and time components
      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(timePart.substring(0, 2));
      final minute = int.parse(timePart.substring(2, 4));
      final second = int.parse(timePart.substring(4, 6));

      // Create a DateTime object
      final dateTime = DateTime(year, month, day, hour, minute, second);

      // Format the DateTime object
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Unknown Date'; // Default fallback
    }
  }


/*void _playAudio(Map<String, dynamic> audioFile) async {
    final dbHelper = DatabaseHelper();
    try {
      final fileData = await dbHelper.getAudioFile(audioFile['file_name']);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${audioFile['file_name']}');
      await tempFile.writeAsBytes(fileData);

      print('Playing: ${tempFile.path}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }*/
}
