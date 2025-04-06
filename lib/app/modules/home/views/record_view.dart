import 'package:clevertalk/common/customFont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/customNavigationBar.dart';
import '../../../../common/widgets/home/customPopUp.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/record_controller.dart';
import 'package:clevertalk/app/modules/dashboard/views/dashboard_view.dart';

class RecordView extends GetView<RecordController> {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    final RecordController controller = Get.put(RecordController());

    return Scaffold(
      backgroundColor: AppColors.appColor,
      body: SafeArea(
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
              // Pause recording before navigating
              if (controller.isRecording.value && !controller.isPaused.value) {
                controller.pauseRecording();
              }
              // Update the DashboardController's currentIndex before navigating
              final dashboardController = Get.find<DashboardController>();
              dashboardController.updateIndex(index); // Set the desired index
              Get.offAll(() => const DashboardView(), arguments: index); // Pass index 1
            },
          ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                SvgPicture.asset('assets/images/auth/logo.svg'),
                const SizedBox(height: 30),

                // Timer
                Obx(() => Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      controller.formatTime(
                          controller.recordingTime.value,
                          controller.recordingMilliseconds.value),
                      style: h3.copyWith(fontSize: 17),
                    ),
                  ),
                )),

                const SizedBox(height: 20),

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
                                height:
                                (index % 2 == 0 ? 100 : 60).toDouble(),
                                color: AppColors.blurtext,
                                margin:
                                const EdgeInsets.symmetric(horizontal: 5),
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

                const SizedBox(height: 100),

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
                    Obx(() => SvgIcon(
                      height: 100,
                      svgPath: controller.isRecording.value &&
                          !controller.isPaused.value
                          ? 'assets/images/audio/pause_icon.svg'
                          : 'assets/images/audio/mic_icon.svg',
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
                    )),
                    SvgIcon(
                      height: 35,
                      svgPath: 'assets/images/audio/save_icon.svg',
                      onTap: () async {
                        TextEditingController txtController = TextEditingController();
                        await controller.pauseRecording(); // Wait for the recording to pause
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
                                  print("Please provide a name for the recording.");
                                  Navigator.of(context).pop();
                                  return;
                                }

                                // Save the recording
                                await controller.saveRecording(filename);
                                Navigator.of(context).pop(); // Close the dialog

                                // Update the DashboardController's currentIndex to "Recordings" (index 1)
                                final dashboardController = Get.find<DashboardController>();
                                dashboardController.updateIndex(1); // Set to "Recordings" tab

                                // Navigate to DashboardView
                                Get.off(() => const DashboardView());
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}