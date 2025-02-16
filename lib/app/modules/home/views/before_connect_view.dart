import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:clevertalk/common/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/customFont.dart';
import 'connectUSB.dart';

class BeforeConnectView extends StatelessWidget {
  const BeforeConnectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'CLEVERTALK', onFirstIconPressed: (){}, onSecondIconPressed: (){}),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title text
                  Text(
                    'Connect Your Clevertalk Recorder',
                    style: h1.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info text
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'This section is exclusively for users who have purchased the Clevertalk Recorder. '
                              'If you plan to use the app by itself to record with your phone, please go back.',
                          style: h4.copyWith(fontSize: 16),
                        ),
                      ),
                      Image.asset(
                        'assets/images/home/recorder.png',
                        width: 180,
                      ),
                    ],
                  ),

                  // Instructions
                  Text(
                    'How to connect:',
                    style: h1.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1. Plug the USB cable into your Clevertalk Recorder.\n'
                        '2. Connect the other end to your phone.\n'
                        '3. Once connected, Press "Continue" then all audio files will be automatically downloaded into the app for transcription and summary.\n'
                        '4. Your 600 free minutes per month subscription will be activated.',
                    style: h4.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Fixed Button at the Bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80).copyWith(bottom: 60), // Increased bottom padding
            child: Center(
              child: CustomButton(
                borderRadius: 30,
                text: 'Continue',
                onPressed: () {
                  connectUsbDevice(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
