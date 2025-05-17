import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/customNavigationBar.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../../data/services/notification_services.dart';
import '../../text/controllers/text_controller.dart';
import '../controllers/audio_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/views/dashboard_view.dart';

class AudioPlayerView extends StatelessWidget {
  final String fileName; // Parameter to accept the selected file
  final String filepath;

  const AudioPlayerView({super.key, required this.fileName, required this.filepath});

  @override
  Widget build(BuildContext context) {
    // Use a unique tag to ensure a fresh controller instance for each file
    final controller = Get.put(AudioPlayerController(), tag: filepath, permanent: false);
    final textController = Get.put(ConvertToTextController());

    // Initialize and play the audio file
    _initializeAudio(controller);

    return PopScope(
      onPopInvokedWithResult: (canPop, result) async {
        if (canPop) {
          await controller.stopAudio(); // Stop audio when navigating away
          // Update DashboardController to "Recordings" tab (index 1)
          final dashboardController = Get.find<DashboardController>();
          dashboardController.updateIndex(1); // Set to "Recordings" tab
          Get.offAll(() => const DashboardView(), arguments: 1); // Pass index 1
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "CLEVERTALK",
          onFirstIconPressed: () {
            print("First icon pressed");
          },
          onSecondIconPressed: () {
            print("Second icon pressed");
          },
        ),
        bottomNavigationBar: CustomNavigationBar(
          onItemTapped: (index) {
            // Pause audio before navigating if it's playing
            if (controller.isPlaying.value) {
              controller.pauseAudio();
            }
            // Update the DashboardController's currentIndex before navigating
            final dashboardController = Get.find<DashboardController>();
            dashboardController.updateIndex(index); // Set the desired index
            // Navigate to DashboardView, clear stack, and pass the index
            Get.offAll(() => const DashboardView(), arguments: index);
          },
        ),
        body: Stack(
          children: [
            Center(
              child: Obx(
                    () => SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      // Timer display
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            controller.formatTime(
                              controller.currentPosition.value.toInt(),
                              (controller.currentPosition.value * 1000).toInt() % 1000,
                            ),
                            style: h3.copyWith(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Waveform with animated gray lines (same as RecordView)
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: ClipRect(
                          child: Stack(
                            children: [
                              Positioned(
                                left: controller.waveformOffset.value,
                                top: 0,
                                bottom: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: List.generate(100, (index) {
                                    return Container(
                                      width: (index % 2 == 0 ? 3 : 4).toDouble(),
                                      height: (index % 2 == 0 ? 100 : 60).toDouble(),
                                      color: AppColors.blurtext,
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                    );
                                  }),
                                ),
                              ),
                              Positioned(
                                left: 200,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 3,
                                  color: AppColors.appColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Text(
                        controller.audioFiles.isNotEmpty && controller.currentIndex.value >= 0
                            ? controller.audioFiles[controller.currentIndex.value]['file_name']
                            : fileName,
                        style: h1.copyWith(fontSize: 18, color: AppColors.textHeader),
                      ),
                      const SizedBox(height: 30),
                      Slider(
                        value: controller.currentPosition.value,
                        min: 0,
                        max: controller.totalDuration.value,
                        onChanged: (value) async {
                          await controller.seekAudio(Duration(seconds: value.toInt()));
                        },
                        activeColor: AppColors.appColor,
                        inactiveColor: Colors.grey,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgIcon(
                            height: 40,
                            svgPath: 'assets/images/audio/previous_icon.svg',
                            onTap: controller.playPrevious,
                          ),
                          SvgIcon(
                            height: 20,
                            svgPath: 'assets/images/audio/previous_10_icon.svg',
                            onTap: () async {
                              final newPosition = (controller.currentPosition.value - 10)
                                  .clamp(0, controller.totalDuration.value);
                              await controller.seekAudio(Duration(seconds: newPosition.toInt()));
                            },
                          ),
                          SvgIcon(
                            height: 60,
                            svgPath: controller.isPlaying.value
                                ? 'assets/images/audio/pause_icon.svg'
                                : 'assets/images/audio/play_icon.svg',
                            color: controller.isPlaying.value ? null : AppColors.appColor,
                            onTap: () async {
                              if (controller.isPlaying.value) {
                                await controller.pauseAudio();
                              } else {
                                await controller.resumeAudio();
                              }
                            },
                          ),
                          SvgIcon(
                            height: 20,
                            svgPath: 'assets/images/audio/next_10_icon.svg',
                            onTap: () async {
                              final newPosition = (controller.currentPosition.value + 10)
                                  .clamp(0, controller.totalDuration.value);
                              await controller.seekAudio(Duration(seconds: newPosition.toInt()));
                            },
                          ),
                          SvgIcon(
                            height: 40,
                            svgPath: 'assets/images/audio/next_icon.svg',
                            onTap: controller.playNext,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CustomButton(
                          text: 'convert_to_text'.tr,
                          onPressed: () async {
                            await controller.pauseAudio();
                            Get.snackbar(
                              duration: const Duration(seconds: 4),
                              'transcription_in_progress'.tr,
                              'transcription_notification'.tr,
                            );
                            await textController.fetchMessages(filepath).then((_) {
                              NotificationService.showNotification(
                                title: 'transcription_ready'.tr,
                                body: 'click_to_view_transcription'.tr,
                                payload: "Conversion",
                                keyPoints: filepath,
                                fileName: fileName,
                                filePath: filepath,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.appColor),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to initialize and play audio
  void _initializeAudio(AudioPlayerController controller) {
    controller.fetchAudioFiles().then((_) {
      final index = controller.audioFiles.indexWhere((file) => file['file_name'] == fileName);
      if (index != -1) {
        controller.currentIndex.value = index;
        controller.playAudio();
      } else {
        controller.audioFiles.add({'file_name': fileName, 'file_path': filepath});
        controller.currentIndex.value = controller.audioFiles.length - 1;
        controller.playAudio(filePath: filepath);
      }
    });
  }
}