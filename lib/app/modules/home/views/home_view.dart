import 'package:clevertalk/app/modules/audio/controllers/audio_controller.dart';
import 'package:clevertalk/app/modules/home/views/record_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/audio_text/customListTile.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../notification_subscription/views/subscription_view.dart';
import '../controllers/home_controller.dart';
import 'before_connect_view.dart';
import 'connectUSB.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioPlayerController audioPlayerController = Get.put(AudioPlayerController());
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            // Top fixed section
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButton(
                        height: 40,
                        fontSize: 12,
                        text: 'Connect Clevertalk',
                        onPressed: () {
                          Get.to(BeforeConnectView());
                        },
                        borderRadius: 30,
                      ),
                    ),
                    SizedBox(width: 40),
                    Expanded(
                      child: CustomButton(
                        height: 40,
                        fontSize: 12,
                        text: 'Explore Plans',
                        onPressed: () {
                          Get.to(SubscriptionView());
                        },
                        borderRadius: 30,
                        //backgroundColor: AppColors.appColor2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: () {}, // Add your onTap functionality here
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Transparent background
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5), // Light gray border
                          width: 1, // Thin border
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '120 minutes remaining',
                          style: TextStyle(
                            color: Colors.black, // Black text
                            fontSize: 14, // Adjust font size as needed
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),

            // Middle Section (List or Centered Button)
            Expanded(
              child: Obx(() {
                if (audioPlayerController.audioFiles.isEmpty) {
                  // If no audio files, center the button
                  return Center(
                    child: CustomButton(
                      isBold: true,
                      width: 250,
                      borderRadius: 5,
                      text: 'START RECORDING',
                      onPressed: () => Get.to(() => RecordView()),
                    ),
                  );
                } else {
                  // Display list of audio files
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemCount: audioPlayerController.audioFiles.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final audioFile = audioPlayerController.audioFiles[index];
                        final fileName = audioFile['file_name'] ?? 'Unknown Title';
                        final filePath = audioFile['file_path'];
                        final parsedDate = audioFile['parsed_date'] ?? 'Unknown Date';
                        final id = audioFile['id'];

                        return GestureDetector(
                          onTap: (){
                            navigateBasedOnTranscription(context, fileName, filePath);
                          },
                          child: CustomListTile(
                            filepath: filePath,
                            title: fileName,
                            subtitle: parsedDate,
                            duration: audioFile['duration'] ?? '00:00:00',
                            id: id,
                            onUpdate: () => audioPlayerController.fetchAudioFiles(),
                          ),
                        );
                      },
                    ),
                  );
                }
              }),
            ),

            // Bottom Section (Only shown when audio files exist)
            Obx(() {
              if (audioPlayerController.audioFiles.isNotEmpty) {
                return Column(
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: CustomButton(
                          isBold: true,
                          borderRadius: 30,
                          text: 'START RECORDING',
                          onPressed: () => Get.to(() => RecordView()),
                        ),
                      ),
                    ),
                    SizedBox(height: 90),
                  ],
                );
              } else {
                return SizedBox.shrink(); // Hide if no audio files
              }
            }),
          ],
        ),
      ),
    );
  }
}
