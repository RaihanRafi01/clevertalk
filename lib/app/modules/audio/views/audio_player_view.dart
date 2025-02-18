import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../../data/services/notification_services.dart';
import '../../text/controllers/text_controller.dart';
import '../../text/views/convert_to_text_view.dart';
import '../controllers/audio_controller.dart';

class AudioPlayerView extends StatelessWidget {
  final String fileName; // Parameter to accept the selected file
  final String filepath;

  const AudioPlayerView({Key? key, required this.fileName,required this.filepath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudioPlayerController(), permanent: true);
    final textController = Get.put(ConvertToTextController());

    // Fetch files and set the selected file as the current index
    controller.fetchAudioFiles().then((_) {
      final index = controller.audioFiles.indexWhere((file) => file['file_name'] == fileName);
      if (index != -1) {
        controller.currentIndex.value = index; // Set the current index to the selected file
        controller.playAudio(); // Automatically play the selected file
      }
    });

    return PopScope(
      onPopInvokedWithResult: (canPop, result) async {
        if (canPop) {
          await controller.stopAudio(); // Stop audio when navigating away
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
        body: Stack(
          children: [
            Center(
              child: Obx(
                    () => SingleChildScrollView(
                  child: Column(
                    children: [
                      SvgPicture.asset('assets/images/audio/audio_icon.svg'),
                      const SizedBox(height: 10),
                      Text(
                        controller.audioFiles.isNotEmpty && controller.currentIndex.value >= 0
                            ? controller.audioFiles[controller.currentIndex.value]['file_name']
                            : 'No File Selected',
                        style: h1.copyWith(fontSize: 20, color: AppColors.textHeader),
                      ),
                      const SizedBox(height: 20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgIcon(
                            height: 30,
                            svgPath: 'assets/images/audio/previous_icon.svg',
                            onTap: controller.playPrevious,
                          ),
                          SvgIcon(
                            height: 30,
                            svgPath: 'assets/images/audio/previous_10_icon.svg',
                            onTap: () async {
                              final newPosition = (controller.currentAudioPosition.inSeconds - 10)
                                  .clamp(0, controller.totalDuration.value.toInt());
                              await controller.seekAudio(Duration(seconds: newPosition));
                            },
                          ),
                          SvgIcon(
                            height: 76,
                            svgPath: controller.isPlaying.value
                                ? 'assets/images/audio/pause_icon.svg'
                                : 'assets/images/audio/play_icon.svg',
                            color: controller.isPlaying.value ? null : AppColors.appColor,
                            onTap: () async {
                              if (controller.isPlaying.value) {
                                await controller.pauseAudio();
                              } else {
                                await controller.playAudio();
                              }
                            },
                          ),
                          SvgIcon(
                            height: 30,
                            svgPath: 'assets/images/audio/next_10_icon.svg',
                            onTap: () async {
                              final newPosition = (controller.currentAudioPosition.inSeconds + 10)
                                  .clamp(0, controller.totalDuration.value.toInt());
                              await controller.seekAudio(Duration(seconds: newPosition));
                            },
                          ),
                          SvgIcon(
                            height: 30,
                            svgPath: 'assets/images/audio/next_icon.svg',
                            onTap: controller.playNext,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CustomButton(
                          text: 'Convert To Text',
                          onPressed: () async {
                            await controller.pauseAudio();
                            Get.snackbar('Transcription in progress...', 'This may take some time, but don\'t worry! We\'ll notify you as soon as it\'s ready. Feel free to using the app while you wait.');
                            //await textController.fetchMessages(filepath);
                            await textController.fetchMessages(filepath).then((_) {
                              NotificationService.showNotification(
                                title: "Conversion Ready!",
                                body: "Click to view Conversion",
                                payload: "Conversion",
                                keyPoints: filepath,
                                fileName: fileName,
                              );
                            });
                            //Get.to(ConvertToTextView(fileName: fileName, filePath: filepath,));
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Loading indicator
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
}
