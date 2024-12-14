import 'package:clevertalk/app/modules/audio/views/summary_key_point_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';

class ConvertView extends GetView {
  const ConvertView({super.key});
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView( // Allow scrolling
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
              children: [
                Text(
                  'Customer Feedback',
                  style: h1.copyWith(fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  'The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. Designed to cater to individual users and professionals, the platform integrates seamlessly with a dedicated audio recorder device and offers tools for efficient file management, transcription, and content summarization. This user-friendly application supports English, French, Spanish, German, and Italian, ensuring accessibility for a global audience.',
                  style: h4.copyWith(fontSize: 20),
                ),
                SizedBox(height: 20), // Replace Spacer with fixed height
                CustomButton(
                  backgroundColor: AppColors.appColor2,
                  text: 'Summary',
                  onPressed: () => Get.to(() => SummaryKeyPointView()),
                ),
                SizedBox(height: 20),
                CustomButton(
                  backgroundColor: AppColors.appColor2.withOpacity(.7),
                  text: 'Key Point',
                  onPressed: () => Get.to(() => SummaryKeyPointView(isKey: true)),
                ),
                SizedBox(height: 20), // Ensure bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
