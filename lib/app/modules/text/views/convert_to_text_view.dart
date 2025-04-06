import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/audio_text/customUserText.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/customNavigationBar.dart'; // Add this import
import '../../../../common/widgets/svgIcon.dart';
import '../../audio/bindings/language_model.dart';
import '../../audio/controllers/audio_controller.dart';
import '../controllers/text_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart'; // Add this import
import '../../dashboard/views/dashboard_view.dart'; // Add this import

class ConvertToTextView extends StatelessWidget {
  final String fileName;
  final String filePath;

  const ConvertToTextView({super.key, required this.fileName, required this.filePath});

  Widget _buildEditableList(ConvertToTextController controller, int index) {
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
  }

  Widget _buildReadOnlyList(ConvertToTextController controller, int index) {
    final msg = controller.messages[index];
    final isHighlighted = controller.currentHighlightedIndex.value == index;
    return CustomUserText(
      name: msg['name']!,
      time: msg['time']!,
      UserColor: Colors.black,
      description: msg['description']!,
      isHighlighted: isHighlighted,
    );
  }

  String formatTimestamp(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return hours != "00" ? '$hours:$minutes:$secs' : '$minutes:$secs';
  }

  void _showSearchBottomSheet(BuildContext context, ConvertToTextController controller) {
    TextEditingController searchController = TextEditingController();
    List<Language> filteredLanguages = List.from(languages);
    bool isCleared = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Language',
                        style: h4.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeader,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search language...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.appColor),
                      suffixIcon: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            searchController.text.isEmpty ? null : Icons.clear,
                            key: ValueKey(searchController.text.isEmpty),
                            color: AppColors.appColor,
                          ),
                        ),
                        onPressed: () {
                          if (searchController.text.isEmpty) {
                            Navigator.pop(context);
                          } else if (!isCleared) {
                            searchController.clear();
                            setState(() {
                              filteredLanguages = List.from(languages);
                              isCleared = true;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.appColor, width: 2),
                      ),
                    ),
                    style: h4.copyWith(fontSize: 16, color: Colors.black87),
                    onChanged: (value) {
                      setState(() {
                        filteredLanguages = languages.where((lang) {
                          final query = value.toLowerCase();
                          return lang.name.toLowerCase().contains(query) ||
                              lang.region.toLowerCase().contains(query);
                        }).toList();
                        isCleared = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredLanguages.isEmpty
                        ? Center(
                      child: Text(
                        'No languages found',
                        style: h4.copyWith(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                        : ListView.separated(
                      itemCount: filteredLanguages.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final lang = filteredLanguages[index];
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.appColor3.withOpacity(0.1),
                              child: Text(
                                lang.name[0],
                                style: TextStyle(
                                  color: AppColors.appColor3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              lang.name,
                              style: h4.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              lang.region,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.check,
                              color: Colors.transparent,
                            ),
                            onTap: () {
                              controller.selectedLanguage.value = lang.name;
                              Navigator.pop(context);
                            },
                            tileColor: Colors.white,
                            hoverColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.put(AudioPlayerController(), permanent: true);
    final textController = Get.put(ConvertToTextController());
    textController.fetchMessages(filePath);

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
          await audioController.stopAudio();
          // Update DashboardController to "Recordings" tab (index 1)
          final dashboardController = Get.find<DashboardController>();
          dashboardController.updateIndex(1); // Set to "Recordings" tab
          Get.offAll(() => const DashboardView(), arguments: 1); // Navigate without back icon
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "CLEVERTALK",
          onFirstIconPressed: () => print("First icon pressed"),
          onSecondIconPressed: () => print("Second icon pressed"),
        ),
        bottomNavigationBar: CustomNavigationBar(
          onItemTapped: (index) async {
            // Pause audio before navigating if it's playing
            if (audioController.isPlaying.value) {
              await audioController.pauseAudio();
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
            Obx(() {
              if (textController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Positioned.fill(
                top: textController.isTranslate.value ? 310 : 260,
                bottom: 60,
                child: ScrollablePositionedList.builder(
                  itemScrollController: textController.itemScrollController,
                  itemCount: textController.messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    return Obx(() => textController.isEditing.value
                        ? _buildEditableList(textController, index)
                        : _buildReadOnlyList(textController, index));
                  },
                ),
              );
            }),
            Positioned(
              top: 0,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.gray1),
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
                                    ? audioController.audioFiles[audioController.currentIndex.value]
                                ['file_name']
                                    : 'No File Selected',
                                style: h1.copyWith(fontSize: 18, color: AppColors.gray2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Slider(
                            value: audioController.currentPosition.value,
                            min: 0,
                            max: audioController.totalDuration.value,
                            onChanged: (value) {
                              audioController.currentPosition.value = value;
                              textController.updateHighlightAndScroll(value);
                            },
                            onChangeEnd: (value) async {
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
                                  try {
                                    if (audioController.isPlaying.value) {
                                      await audioController.pauseAudio();
                                    } else {
                                      if (audioController.currentPosition.value > 0) {
                                        await audioController.resumeAudio(filePath: filePath);
                                      } else {
                                        await audioController.playAudio(filePath: filePath);
                                      }
                                    }
                                  } catch (e) {
                                    Get.snackbar('Error', 'Failed to toggle audio: $e');
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      Obx(
                            () => Text(
                          textController.messages.isNotEmpty
                              ? audioController.audioFiles[audioController.currentIndex.value]
                          ['file_name']
                              : 'Please wait for a while...',
                          style: h1.copyWith(fontSize: 16, color: AppColors.gray2),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!textController.isEditing.value) ...[
                        GestureDetector(
                          onTap: () async {
                            await textController.generateAndSharePdf();
                          },
                          child: SvgPicture.asset(
                            'assets/images/summary/share_icon.svg',
                            color: AppColors.gray1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => textController.editSpeakerName(context, filePath),
                          child: SvgPicture.asset(
                            'assets/images/summary/speaker_edit_icon.svg',
                            color: AppColors.gray1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            textController.isTranslate.toggle();
                          },
                          child: SvgPicture.asset(
                            'assets/images/summary/translate_icon.svg',
                            color: AppColors.gray1,
                          ),
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
                          color: AppColors.gray1,
                        ),
                      ),
                    ],
                  )),
                  Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
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
                            height: 30,
                            width: 80,
                            fontSize: 11,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child:
                            SvgPicture.asset('assets/images/summary/arrow_icon.svg'),
                          ),
                          Obx(() => Container(
                            height: 30,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.appColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              onTap: () => _showSearchBottomSheet(context, textController),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        textController.selectedLanguage.value.isEmpty
                                            ? 'Select Language'
                                            : textController.selectedLanguage.value,
                                        style: h4.copyWith(
                                            fontSize: 11, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          )),
                          const Spacer(),
                          CustomButton(
                            text: 'Translate',
                            onPressed: () =>
                                textController.translateText(filePath, fileName),
                            height: 30,
                            width: 80,
                            fontSize: 11,
                          ),
                        ],
                      ),
                    )
                        : const SizedBox(height: 20, key: ValueKey('empty')),
                  )),
                ],
              ),
            ),
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
                ],
              ),
            ),
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
}