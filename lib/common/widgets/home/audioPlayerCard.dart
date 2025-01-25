import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../app/modules/audio/controllers/audio_controller.dart';
import '../../appColors.dart';
import '../../customFont.dart';
import '../svgIcon.dart';

class AudioPlayerCard extends StatelessWidget {
  const AudioPlayerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudioPlayerController(), permanent: true);

    // Fetch the latest audio file when the card is built
    controller.fetchAudioFiles().then((_) {
      if (controller.audioFiles.isNotEmpty) {
        controller.currentIndex.value = controller.audioFiles.length - 1; // Set to the latest track
        //controller.playAudio(); // Automatically play the latest track
      }
    });

    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Row(
            children: [
              // Icon or Album Art Section
              SvgPicture.asset('assets/images/home/audio_card.svg'),
              // Info and Player Controls Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Recent Record',
                      style: h4.copyWith(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Obx(
                          () => Text(
                        controller.audioFiles.isNotEmpty && controller.currentIndex.value >= 0
                            ? controller.audioFiles[controller.currentIndex.value]['file_name']
                            : 'No File Selected',
                        style: h1.copyWith(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Slider and Controls Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                              () => Slider(
                            value: controller.currentPosition.value,
                            min: 0,
                            max: controller.totalDuration.value,
                            onChanged: (value) async {
                              await controller.seekAudio(Duration(seconds: value.toInt()));
                            },
                            activeColor: AppColors.appColor,
                            inactiveColor: Colors.grey,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center the buttons
                          children: [
                            SvgIcon(
                              height: 16,
                              svgPath: 'assets/images/audio/previous_icon.svg',
                              onTap: controller.playPrevious,
                            ),
                            SvgIcon(
                              height: 16,
                              svgPath: 'assets/images/audio/previous_10_icon.svg',
                              onTap: () async {
                                final newPosition = (controller.currentAudioPosition.inSeconds - 10)
                                    .clamp(0, controller.totalDuration.value.toInt());
                                await controller.seekAudio(Duration(seconds: newPosition));
                              },
                            ),
                            Obx(
                                  () => SvgIcon(
                                height: 30,
                                svgPath: controller.isPlaying.value
                                    ? 'assets/images/audio/pause_icon.svg'
                                    : 'assets/images/audio/play_icon.svg',
                                onTap: () async {
                                  if (controller.isPlaying.value) {
                                    await controller.pauseAudio();
                                  } else {
                                    await controller.playAudio();
                                  }
                                },
                              ),
                            ),
                            SvgIcon(
                              height: 16,
                              svgPath: 'assets/images/audio/next_10_icon.svg',
                              onTap: () async {
                                final newPosition = (controller.currentAudioPosition.inSeconds + 10)
                                    .clamp(0, controller.totalDuration.value.toInt());
                                await controller.seekAudio(Duration(seconds: newPosition));
                              },
                            ),
                            SvgIcon(
                              height: 16,
                              svgPath: 'assets/images/audio/next_icon.svg',
                              onTap: controller.playNext,
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
