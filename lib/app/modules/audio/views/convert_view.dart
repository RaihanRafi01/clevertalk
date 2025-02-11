import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../controllers/audio_controller.dart';

class ConvertView extends GetView<AudioPlayerController> {
  final String text;
  final String filePath;
  final String fileName;

  const ConvertView({
    Key? key,
    required this.text,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlayerController>();

    // Initialize the observable list for transcript messages
    var transcriptMessages = <Map<String, String>>[].obs;

    print('text ::::::::::::::::::::::::$text');

    try {
      // Decode the JSON data
      final data = json.decode(text) as List;

      // Map the data into a list of maps containing 'name' and 'description'
      transcriptMessages.value = data.map<Map<String, String>>((entry) {
        final speakerName = entry['Speaker_Name'] as String;
        final transcript = entry['Transcript'] as String;
        return {
          'name': speakerName,
          'description': transcript,
        };
      }).toList();
    } catch (e) {
      // Handle JSON decoding error
      print("Error decoding JSON: $e");
      return Scaffold(
        appBar: CustomAppBar(
          title: "CLEVERTALK",
          onFirstIconPressed: () => print("First icon pressed"),
          onSecondIconPressed: () => print("Second icon pressed"),
        ),
        body: Center(child: Text("Error decoding transcription data.")),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () => print("First icon pressed"),
        onSecondIconPressed: () => print("Second icon pressed"),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Feedback',
                      style: h1.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    // Loop through the transcriptMessages and display each speaker's name and transcript
                    Obx(() {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: transcriptMessages.map<Widget>((item) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['name']} says:',
                                style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item['description'] ?? '',
                                style: h4.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 20),
                    /*CustomButton(
                      backgroundColor: AppColors.appColor2,
                      text: 'Summary',
                      onPressed: () {
                        controller.fetchSummary(filePath, fileName);
                      },
                    ),
                    const SizedBox(height: 20),*/
                    CustomButton(
                      backgroundColor: AppColors.appColor2.withOpacity(.7),
                      text: 'Key Point',
                      onPressed: () {
                        controller.fetchKeyPoints(filePath, fileName);
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.appColor),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
