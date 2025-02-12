import 'package:clevertalk/common/customFont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/home/customPopUp.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../controllers/record_controller.dart';

class RecordView extends GetView<RecordController> {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    final RecordController controller = Get.put(RecordController());

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
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
                          margin: EdgeInsets.symmetric(horizontal: 5),
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
          )),

          Spacer(),

          // Control buttons
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
                    if (controller.isPaused.value) {
                      // Resume recording if it's paused
                      controller.resumeRecording();
                    } else {
                      // Pause recording if it's recording
                      controller.pauseRecording();
                    }
                  } else {
                    // Start recording if it's not recording yet
                    controller.startRecording();
                  }
                },
              ),
              SvgIcon(
                height: 35,
                svgPath: 'assets/images/audio/save_icon.svg',
                onTap: () async {
                  TextEditingController txtController = TextEditingController();
                  await controller.pauseRecording(); // Wait for the recording to pause before proceeding
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return CustomPopup(
                        controller: txtController,
                        title: 'Saved',
                        onButtonPressed: () async {
                          final filename = txtController.text.trim();
                          if (filename.isEmpty) {
                            // Show a message to the user if no name is provided.
                            print("Please provide a name for the recording.");
                            Navigator.of(context).pop();
                            return;
                          }

                          // Wait for the save to complete before closing the dialog
                          await controller.saveRecording(filename);
                          Navigator.of(context).pop(); // Close the dialog after saving
                        },
                      );
                    },
                  );
                },
              )
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}