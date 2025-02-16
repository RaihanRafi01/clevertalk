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
          // Action for the first button
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          // Action for the second button
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
                  children: [
                    CustomButton(
                      text: 'Connect Clevertalk Recorder',
                      onPressed: () {
                        // Get.to(UsbFilePicker());
                        //connectUsbDevice(context); // Define this function or replace it with the appropriate logic
                        Get.to(BeforeConnectView());
                      },
                      width: 160,
                      borderRadius: 5,
                      height: 60,
                    ),
                    Spacer(),
                    CustomButton(
                      height: 60,
                      text: 'Explore Plan',
                      onPressed: () {
                        Get.to(SubscriptionView());
                      },
                      width: 160,
                      borderRadius: 5,
                      backgroundColor: AppColors.appColor2,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                CustomButton(
                  height: 40,
                  text: '120 minutes remaining',
                  onPressed: () {
                    // Action for the button
                  },
                  width: 250,
                  borderRadius: 5,
                  backgroundColor: AppColors.appColor2,
                ),
                SizedBox(height: 20),
              ],
            ),

            // Middle scrollable section
            Expanded(
              child: Obx(() {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(), // Ensures smooth scrolling
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
                    return CustomListTile(
                      filepath: filePath,
                      title: fileName,
                      subtitle: parsedDate,
                      duration: audioFile['duration'] ?? '00:00:00',
                      id: id,
                      onUpdate: () => audioPlayerController.fetchAudioFiles(), // Refresh the list
                    );
                  },
                );
              }),
            ),

            // Bottom fixed section
            Column(
              children: [
                SizedBox(height: 20),
                Center(
                  child: CustomButton(
                    width: 250,
                    borderRadius: 5,
                    text: 'Start Recording',
                    onPressed: () => Get.to(() => RecordView()),
                  ),
                ),
                SizedBox(height: 70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}