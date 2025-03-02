import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/audio_text/customUserText.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../audio/controllers/audio_controller.dart';
import '../controllers/text_controller.dart';

class ConvertToTextView extends StatelessWidget {
  final String fileName;
  final String filePath;

  const ConvertToTextView({super.key, required this.fileName, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.put(AudioPlayerController(), permanent: true);
    final textController = Get.put(ConvertToTextController());
    textController.fetchMessages(filePath);

    // Start transcription fetching and audio playback
    audioController.fetchAudioFiles().then((_) {
      final index = audioController.audioFiles.indexWhere((file) => file['file_name'] == fileName);
      if (index != -1) {
        audioController.currentIndex.value = index;
        textController.fetchMessages(filePath).then((_) {
          audioController.playAudio(filePath: filePath);
          textController.syncScrollingWithAudio(audioController);
        });
      }
    });

    return PopScope(
      onPopInvokedWithResult: (canPop, result) async {
        if (canPop) {
          await audioController.stopAudio(); // Stop audio when navigating away
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "CLEVERTALK",
          onFirstIconPressed: () => print("First icon pressed"),
          onSecondIconPressed: () => print("Second icon pressed"),
        ),
        body: Stack(
          children: [
            // Scrollable content
            Obx(() {
              if (textController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Positioned.fill(
                top: textController.isTranslate.value ? 330 : 290,
                bottom: 100,
                child: SingleChildScrollView(
                  controller: textController.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => textController.isEditing.value
                          ? _buildEditableList(textController)
                          : _buildReadOnlyList(textController)),
                    ],
                  ),
                ),
              );
            }),

            // Fixed header (audio player)
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
                                audioController.audioFiles.isNotEmpty &&
                                    audioController.currentIndex.value >= 0
                                    ? audioController.audioFiles[audioController.currentIndex.value]['file_name']
                                    : 'No File Selected',
                                style: h1.copyWith(fontSize: 20, color: AppColors.textHeader),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Slider(
                            value: audioController.currentPosition.value,
                            min: 0,
                            max: audioController.totalDuration.value,
                            onChanged: (value) async {
                              await audioController.seekAudio(Duration(seconds: value.toInt()));
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
                                onTap: audioController.playPrevious,
                              ),
                              SvgIcon(
                                height: 22,
                                svgPath: 'assets/images/audio/previous_10_icon.svg',
                                onTap: () async {
                                  final newPosition = (audioController.currentAudioPosition.inSeconds - 10)
                                      .clamp(0, audioController.totalDuration.value.toInt());
                                  await audioController.seekAudio(Duration(seconds: newPosition));
                                },
                              ),
                              SvgIcon(
                                height: 54,
                                svgPath: audioController.isPlaying.value
                                    ? 'assets/images/audio/pause_icon.svg'
                                    : 'assets/images/audio/play_icon.svg',
                                color: audioController.isPlaying.value ? null : AppColors.appColor,
                                onTap: () async {
                                  if (audioController.isPlaying.value) {
                                    await audioController.pauseAudio();
                                  } else {
                                    await audioController.playAudio();
                                  }
                                },
                              ),
                              SvgIcon(
                                height: 22,
                                svgPath: 'assets/images/audio/next_10_icon.svg',
                                onTap: () async {
                                  final newPosition = (audioController.currentAudioPosition.inSeconds + 10)
                                      .clamp(0, audioController.totalDuration.value.toInt());
                                  await audioController.seekAudio(Duration(seconds: newPosition));
                                },
                              ),
                              SvgIcon(
                                height: 22,
                                svgPath: 'assets/images/audio/next_icon.svg',
                                onTap: audioController.playNext,
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
                              ? audioController.audioFiles[audioController.currentIndex.value]['file_name']
                              : 'Please wait for a while...',
                          style: h1.copyWith(fontSize: 20, color: AppColors.textHeader),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),

            // Fixed editing and translation controls
            Positioned(
              top: 250, // Positioned below the audio player
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!textController.isEditing.value) ...[
                        GestureDetector(
                          onTap: () => textController.editSpeakerName(context, filePath),
                          child: SvgPicture.asset('assets/images/summary/speaker_edit_icon.svg'),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            textController.isTranslate.toggle();
                            print('isTranslate toggled to: ${textController.isTranslate.value}'); // Debug
                          },
                          child: SvgPicture.asset('assets/images/summary/translate_icon.svg'),
                        ),
                        const SizedBox(width: 16),
                      ],
                      GestureDetector(
                        onTap: () {
                          if (textController.isEditing.value) {
                            textController.saveTranscription(filePath, true);
                          }
                          textController.isTranslate.value = false;
                          textController.isEditing.toggle();
                        },
                        child: SvgPicture.asset(
                          textController.isEditing.value
                              ? 'assets/images/summary/save_icon.svg'
                              : 'assets/images/summary/edit_icon.svg',
                        ),
                      ),
                    ],
                  ),
                  Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300), // Increased duration for visibility
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.0, -0.5),
                        end: const Offset(0.0, 0.0),
                      ).animate(animation);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                    child: textController.isTranslate.value
                        ? Container(
                      key: const ValueKey('translateRow'),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomButton(
                            text: textController.currentLanguage.value.isEmpty
                                ? 'English'
                                : textController.currentLanguage.value,
                            onPressed: () {},
                            height: 26,
                            width: 70,
                            fontSize: 12,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SvgPicture.asset('assets/images/summary/arrow_icon.svg'),
                          ),
                          Obx(() => Container(
                            height: 30,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.appColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButton<String>(
                              value: textController.selectedLanguage.value,
                              onChanged: (value) => textController.selectedLanguage.value = value!,
                              borderRadius: BorderRadius.circular(20),
                              dropdownColor: AppColors.appColor,
                              underline: const SizedBox(),
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              items: <String>[
                                'English', 'Spanish', 'French', 'German', 'Italian',
                                'Portuguese', 'Chinese', 'Hindi', 'Dutch', 'Ukrainian', 'Russian'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: h4.copyWith(fontSize: 12, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                          )),
                          const Spacer(),
                          CustomButton(
                            text: 'Translate',
                            onPressed: () => textController.translateText(filePath, fileName),
                            height: 26,
                            width: 70,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    )
                        : const SizedBox(height: 20, key: ValueKey('empty')),
                  )),
                ],
              ),
            ),

            // Fixed bottom buttons
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CustomButton(
                    backgroundColor: AppColors.appColor3,
                    text: 'Summary',
                    onPressed: () async {
                      await audioController.pauseAudio();
                      audioController.fetchKeyPoints(filePath, fileName);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Loading overlay
            Positioned(
              left: 10,
              right: 10,
              top: 0,
              bottom: 0,
              child: Obx(() {
                if (audioController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.appColor),
                  );
                }
                return const SizedBox.shrink();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableList(ConvertToTextController controller) {
    return Column(
      children: List.generate(controller.messages.length, (index) {
        final msg = controller.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller.nameControllers[index],
                style: h4.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: "Speaker Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.descControllers[index],
                style: h4.copyWith(fontSize: 15),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Transcription",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              Text(msg['time']!, style: h4.copyWith(fontSize: 12)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReadOnlyList(ConvertToTextController controller) {
    return Column(
      children: List.generate(controller.messages.length, (index) {
        final msg = controller.messages[index];
        return Obx(() {
          bool isHighlighted = index == controller.currentHighlightedIndex.value;
          return CustomUserText(
            name: msg['name']!,
            time: msg['time']!,
            UserColor: msg['name'] == 'l' ? AppColors.green : AppColors.textUserColor,
            description: msg['description']!,
            isHighlighted: isHighlighted,
          );
        });
      }),
    );
  }
}