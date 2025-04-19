import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:clevertalk/common/widgets/customAppBar.dart';
import 'package:clevertalk/common/widgets/customNavigationBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/customFont.dart';
import 'connectUSB.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/views/dashboard_view.dart';

class BeforeConnectView extends StatelessWidget {
  const BeforeConnectView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (canPop, result) async {
        if (canPop) {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.updateIndex(1); // Set to "Recordings" tab
          Get.offAll(() => const DashboardView(), arguments: 1);
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'CLEVERTALK',
          onFirstIconPressed: () {
            final dashboardController = Get.find<DashboardController>();
            dashboardController.updateIndex(1);
            Get.offAll(() => const DashboardView(), arguments: 1);
          },
          onSecondIconPressed: () {},
        ),
        bottomNavigationBar: CustomNavigationBar(
          onItemTapped: (index) {
            final dashboardController = Get.find<DashboardController>();
            dashboardController.updateIndex(index);
            Get.offAll(() => const DashboardView(), arguments: index);
          },
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Connect Your Clevertalk Recorder',
                      style: h1.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description and "How to connect" on the left, image on the right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Description and "How to connect" section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description text
                              Text(
                                'This section is exclusively for users who have purchased the Clevertalk Recorder. '
                                'If you plan to use the app by itself to record with your phone, please go back.',
                                style: h4.copyWith(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // "How to connect" title
                              Text(
                                'How to connect',
                                style: h1.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Steps in transparent containers with gray border
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Step 1
                                  Container(
                                    width: double.infinity,
                                    // Same width for all boxes
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Transparent background
                                      border: Border.all(
                                        color: Colors.grey, // Gray border
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '1. ',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors
                                                  .red, // Red color for numbering
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Plug ',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              // Bold "Plug"
                                              color: Colors.black,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                'the USB cable into your Clevertalk Recorder.',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Step 2
                                  Container(
                                    width: double.infinity,
                                    // Same width for all boxes
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Transparent background
                                      border: Border.all(
                                        color: Colors.grey, // Gray border
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '2. ',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors
                                                  .red, // Red color for numbering
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Connect ',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              // Bold "Connect"
                                              color: Colors.black,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                'the other end to your phone.',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Step 3
                                  Container(
                                    width: double.infinity,
                                    // Same width for all boxes
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Transparent background
                                      border: Border.all(
                                        color: Colors.grey, // Gray border
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '3. ',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors
                                                  .red, // Red color for numbering
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Once connected, ',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Press Continue.',
                                            style: h4.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              // Bold "Press"
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right side: Only the image
                        Expanded(
                          child: Image.asset(
                            'assets/images/home/recorder.png',
                          ),
                        ),
                      ],
                    ),

                    // Extra space to ensure content scrolls under the fixed button
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // Fixed Continue Button at the Bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                  // Background to prevent content from showing through
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Continue',
                      onPressed: () {
                        connectUsbDevice(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
