import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/audio_text/customListTile.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/database_helper.dart';
import 'package:intl/intl.dart';
import '../controllers/audio_controller.dart';

class AudioView extends StatelessWidget {
  const AudioView({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioPlayerController audioController = Get.put(AudioPlayerController());

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
              child: Obx(() {
                if (audioController.audioFiles.isEmpty) {
                  return Center(
                    child: Text(
                      'No audio files available',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                } else {
                  return ListView.separated(
                    itemCount: audioController.audioFiles.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final audioFile = audioController.audioFiles[index];
                      final fileName = audioFile['file_name'] ?? 'Unknown Title';
                      final parsedDate = audioFile['parsed_date'] ?? 'Unknown Date';
                      final id = audioFile['id'];
                      return CustomListTile(
                        title: fileName,
                        subtitle: parsedDate,
                        duration: audioFile['duration'] ?? '00:00:00',
                        id: id,
                        onUpdate: audioController.fetchAudioFiles, // Pass the refresh callback
                      );
                    },
                  );
                }
              }),
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
}
