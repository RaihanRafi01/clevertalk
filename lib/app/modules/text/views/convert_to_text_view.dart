import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/audio_text/customUserText.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/home/customPopUp.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../audio/controllers/audio_controller.dart';
import '../../audio/views/summary_key_point_view.dart';
import '../controllers/text_controller.dart';

class ConvertToTextView extends StatelessWidget {
  final String fileName;
  final String filePath;

  const ConvertToTextView({super.key, required this.fileName, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudioPlayerController(), permanent: true);
    final textController = Get.put(ConvertToTextController());

    controller.fetchAudioFiles().then((_) {
      final index = controller.audioFiles.indexWhere((file) => file['file_name'] == fileName);
      if (index != -1) {
        controller.currentIndex.value = index;
        controller.playAudio();
        textController.fetchMessages(filePath, fileName);
      }
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () => print("First icon pressed"),
        onSecondIconPressed: () => print("Second icon pressed"),
      ),
      body: Stack(
        children: [
          Obx(() => textController.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : Positioned.fill(
            top: 260,
            child: SingleChildScrollView(
              controller: textController.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: List.generate(textController.messages.length, (index) {
                  final msg = textController.messages[index];
                  return Obx(() {
                    bool isHighlighted = index == textController.currentHighlightedIndex.value;
                    if (isHighlighted) {
                      final position = index * 80.0;
                      textController.scrollController.animateTo(
                        position,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                    return CustomUserText(
                      name: msg['name']!,
                      time: msg['time']!,
                      UserColor: msg['name'] == 'Pial' ? AppColors.green : AppColors.textUserColor,
                      description: msg['description']!,
                      isHighlighted: isHighlighted,
                    );
                  });
                }),
              ),
            ),
          )),

          // Fixed header
          // audio player
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.appColor, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                  child: Obx(
                        () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              controller.audioFiles.isNotEmpty && controller.currentIndex.value >= 0
                                  ? controller.audioFiles[controller.currentIndex.value]['file_name']
                                  : 'No File Selected',
                              style: h1.copyWith(fontSize: 20, color: AppColors.textHeader),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                              height: 22,
                              svgPath: 'assets/images/audio/previous_icon.svg',
                              onTap: controller.playPrevious,
                            ),
                            SvgIcon(
                              height: 22,
                              svgPath: 'assets/images/audio/previous_10_icon.svg',
                              onTap: () async {
                                final newPosition = (controller.currentAudioPosition.inSeconds - 10)
                                    .clamp(0, controller.totalDuration.value.toInt());
                                await controller.seekAudio(Duration(seconds: newPosition));
                              },
                            ),
                            SvgIcon(
                              height: 54,
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
                              height: 22,
                              svgPath: 'assets/images/audio/next_10_icon.svg',
                              onTap: () async {
                                final newPosition = (controller.currentAudioPosition.inSeconds + 10)
                                    .clamp(0, controller.totalDuration.value.toInt());
                                await controller.seekAudio(Duration(seconds: newPosition));
                              },
                            ),
                            SvgIcon(
                              height: 22,
                              svgPath: 'assets/images/audio/next_icon.svg',
                              onTap: controller.playNext,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Spacer(),
                    Obx(
                          () => Text(
                        textController.messages.isNotEmpty
                            ? 'Transcription Data Available'
                            : 'No Transcription Data',
                        style: h1.copyWith(fontSize: 20, color: AppColors.textHeader),
                      ),
                    ),
                    const Spacer(),
                    SvgIcon(
                      svgPath: 'assets/images/audio/edit_icon.svg',
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return CustomPopup(
                              title: 'Edit',
                              isSecondInput: true,
                              hint1: 'Speaker 01',
                              hint2: 'Speaker 02',
                              onButtonPressed: () {
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                      height: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // summary ,key point , loading screen
          // Fixed bottom buttons
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Column(
              children: [
                CustomButton(
                  backgroundColor: AppColors.appColor2,
                  text: 'Summary',
                  onPressed: () => controller.fetchSummary(filePath, fileName),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  backgroundColor: AppColors.appColor3,
                  text: 'Key Point',
                  onPressed: () => controller.fetchKeyPoints(filePath, fileName),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 0,
            bottom: 0,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.appColor),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }
}