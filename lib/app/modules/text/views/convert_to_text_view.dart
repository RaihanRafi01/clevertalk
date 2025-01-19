import 'dart:async';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/audio_text/customUserText.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/home/customPopUp.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../audio/views/summary_key_point_view.dart';

class ConvertToTextView extends GetView {
  // Reactive variables for GetX state management
  var highlightedTimestamp = ''.obs;
  var currentHighlightedIndex = (-1).obs;

  // ScrollController and message list as class fields
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> messages = [
    {'name': 'Pial', 'time': '00:30', 'description': 'Message 1'},
    {'name': 'Rufsan', 'time': '01:00', 'description': 'Message 2'},
    {'name': 'Pial', 'time': '01:30', 'description': 'Message 3'},
    {'name': 'Rufsan', 'time': '02:00', 'description': 'Message 4'},
    {'name': 'Pial', 'time': '02:30', 'description': 'Message 5'},
    {'name': 'Rufsan', 'time': '03:00', 'description': 'Message 6'},
    {'name': 'Pial', 'time': '03:30', 'description': 'Message 7'},
    {'name': 'Rufsan', 'time': '04:00', 'description': 'Message 8'},
  ];

  ConvertToTextView({super.key}); // Remove 'const' constructor here

  // Function to highlight the words one by one with a delay
  // Function to highlight the messages one by one with a delay
  // Function to highlight the messages one by one with a delay
  void highlightWords() {
    int index = 0; // Start from the first message
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (index >= messages.length) {
        timer.cancel(); // Stop the timer when all messages are highlighted
      } else {
        // Update the index for highlighting and trigger scrolling
        currentHighlightedIndex.value = index;
        index++;
      }
    });
  }




  // Function to scroll to a specific timestamp and highlight the message
  void scrollToTimestamp(String targetTimestamp) {
    final targetIndex = messages.indexWhere((msg) => msg['time'] == targetTimestamp);
    if (targetIndex != -1) {
      // Update the highlighted timestamp
      highlightedTimestamp.value = targetTimestamp;

      // Calculate the position of the target message (height of each message is assumed to be 80)
      final position = targetIndex * 80.0;  // Adjust this calculation if your layout changes
      _scrollController.animateTo(
        position,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );

      // Trigger word-by-word highlighting for the selected message
      //highlightWords(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
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
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            top: 260, // This adjusts the content to not overlap with the header area
            child: SingleChildScrollView(
              controller: _scrollController, // Attach the controller here
              padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: List.generate(messages.length, (index) {
                    final msg = messages[index];
                    return Obx(() {
                      bool isHighlighted = index == currentHighlightedIndex.value; // Compute inside Obx
                      if (isHighlighted) {
                        // Trigger scroll when the highlighted message changes
                        final position = index * 80.0; // Adjust height as per your layout
                        _scrollController.animateTo(
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
                        isHighlighted: isHighlighted, // Reactively highlight the message
                      );
                    });
                  }),
                ),
            ),
          ),

          // Fixed header (top content)
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
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Customer Feedback',
                            style: h1.copyWith(fontSize: 20, color: AppColors.textHeader),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Slider(
                        value: 0.3,
                        onChanged: (value) {},
                        activeColor: AppColors.appColor,
                        inactiveColor: Colors.grey,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgIcon(
                            height: 22,
                            svgPath: 'assets/images/audio/previous_icon.svg',
                            onTap: () {},
                          ),
                          SvgIcon(
                            height: 22,
                            svgPath: 'assets/images/audio/previous_10_icon.svg',
                            onTap: () {},
                          ),
                          SvgIcon(
                            height: 54,
                            svgPath: 'assets/images/audio/pause_icon.svg',
                            onTap: () {
                              // Scroll to a specific timestamp and highlight it
                              highlightWords(); // For example, scroll to 02:00
                            },
                          ),
                          SvgIcon(
                            height: 22,
                            svgPath: 'assets/images/audio/next_10_icon.svg',
                            onTap: () {},
                          ),
                          SvgIcon(
                            height: 22,
                            svgPath: 'assets/images/audio/next_icon.svg',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Title and edit icon row
                Row(
                  children: [
                    Spacer(),
                    Text(
                      'Customer Feedback',
                      style: h1.copyWith(fontSize: 20),
                    ),
                    Spacer(),
                    SvgIcon(svgPath: 'assets/images/audio/edit_icon.svg', onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false, // Prevents closing by tapping outside
                        builder: (BuildContext context) {
                          return CustomPopup(
                            title: 'Edit',
                            isSecondInput: true,
                            hint1: 'Speaker 01',
                            hint2: 'Speaker 02',
                            onButtonPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          );
                        },
                      );
                    }, height: 24),
                  ],
                ),
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
                CustomButton(
                  backgroundColor: AppColors.appColor2,
                  text: 'Summary',
                  onPressed: () => Get.to(() => SummaryKeyPointView(summary: '', keyPoints: '',)),
                ),
                SizedBox(height: 10),
                CustomButton(
                  backgroundColor: AppColors.appColor3,
                  text: 'Key Point',
                  onPressed: () => Get.to(() => SummaryKeyPointView(isKey: true, summary: '', keyPoints: '',)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
