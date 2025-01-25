import 'dart:async';

import 'package:clevertalk/common/customFont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/home/audioPlayerCard.dart';
import '../../../../common/widgets/home/customPopUp.dart';
import '../../../../common/widgets/svgIcon.dart';

class RecordController extends GetxController {
  var recordingTime = 0.obs; // Total seconds
  var recordingMilliseconds = 0.obs; // Milliseconds
  var isRecording = false.obs;
  var waveformOffset = 0.0.obs; // Controls the movement of gray lines
  Timer? _timer;

  void startRecording() {
    isRecording.value = true;
    recordingTime.value = 0;
    recordingMilliseconds.value = 0;
    waveformOffset.value = 0.0;

    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      // Increment milliseconds
      recordingMilliseconds.value += 50;
      if (recordingMilliseconds.value >= 1000) {
        // If milliseconds exceed 1000, increment seconds
        recordingMilliseconds.value = 0;
        recordingTime.value++;
      }

      waveformOffset.value -= 2; // Move the waveform to the left
      if (waveformOffset.value <= -Get.width) {
        waveformOffset.value = 0.0; // Reset to create continuous effect
      }
    });
  }

  void stopRecording() {
    isRecording.value = false;
    _timer?.cancel();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  String formatTime(int seconds, int milliseconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0'); // Calculate hours
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0'); // Calculate minutes
    final secs = (seconds % 60).toString().padLeft(2, '0'); // Calculate seconds
    final millis = (milliseconds ~/ 50).toString().padLeft(2, '0'); // Calculate milliseconds (every 50ms interval)

    return "$hours:$minutes:$secs.$millis"; // Return formatted time in hh:mm:ss:ms
  }
}

class RecordView extends GetView<RecordController> {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    final RecordController controller = Get.put(RecordController());

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 80),
          SvgPicture.asset('assets/images/auth/logo.svg'),
          SizedBox(height: 30),
          // Timer
          Obx(() => Container(
            width: 150,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Add some padding around the text
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2), // Border color and width
              borderRadius: BorderRadius.circular(8), // Rounded corners
            ),
            child: Center(
              child: Text(
                controller.formatTime(controller.recordingTime.value, controller.recordingMilliseconds.value),
                style: h3.copyWith(fontSize: 17),
              ),
            ),
          )),

          SizedBox(height: 20),

          // Waveform with animated gray lines
          Obx(() => SizedBox(
            height: 150,
            width: double.infinity,
            child: ClipRect(
              child: Stack(
                children: [
                  // Simulated waveform with moving gray lines
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
                          margin: EdgeInsets.symmetric(horizontal: 5), // Add spacing between lines
                        );
                      }),
                    ),
                  ),
                  // Fixed vertical moving bar
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
          )),

          Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgIcon(
                height: 35,
                svgPath: 'assets/images/audio/cancel_icon.svg',
                onTap: () {
                  if (controller.isRecording.value) {
                    controller.stopRecording();
                  }
                },
              ),
              SvgIcon(
                height: 100,
                svgPath: 'assets/images/audio/mic_icon.svg',
                onTap: () {
                  if (controller.isRecording.value) {
                    controller.stopRecording();
                  } else {
                    controller.startRecording();
                  }
                },
              ),
              SvgIcon(
                height: 35,
                svgPath: 'assets/images/audio/save_icon.svg',
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Prevents closing by tapping outside
                    builder: (BuildContext context) {
                      return CustomPopup(
                        controller: TextEditingController(),
                        title: 'Edit',
                        onButtonPressed: () {
                          // Handle button press, for example, retrieve input data:
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      );
                    },
                  );
                  if (!controller.isRecording.value) {
                    // Save action
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 30,)
        ],
      ),
    );
  }
}
