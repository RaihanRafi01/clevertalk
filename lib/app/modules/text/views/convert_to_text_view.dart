import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/audio_text/customUserText.dart';
import '../../../../common/widgets/svgIcon.dart';

class ConvertToTextView extends GetView {
  const ConvertToTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConvertToTextView'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            top: 260, // This adjusts the content to not overlap with the header area
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  CustomUserText(
                    name: 'Pial:',
                    time: '00:30',
                    UserColor: AppColors.green,
                    description:
                    'The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. Designed to cater to individual users and professionals,',
                  ),
                  CustomUserText(
                    name: 'Rufsan:',
                    time: '00:30',
                    UserColor: AppColors.textUserColor,
                    description:
                    'The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. Designed to cater to individual users and professionals,',
                  ),
                  CustomUserText(
                    name: 'Pial:',
                    time: '00:30',
                    UserColor: AppColors.green,
                    description:
                    'The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. Designed to cater to individual users and professionals,',
                  ),
                  CustomUserText(
                    name: 'Rufsan:',
                    time: '00:30',
                    UserColor: AppColors.textUserColor,
                    description:
                    'The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. Designed to cater to individual users and professionals,',
                  ),
                ],
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
                            svgPath: 'assets/images/audio/.svg',
                            onTap: () {},
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
                    SvgIcon(svgPath: 'assets/images/audio/edit_icon.svg', onTap: () {}, height: 24),
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
                  onPressed: () {},
                ),
                SizedBox(height: 10),
                CustomButton(
                  backgroundColor: AppColors.appColor3,
                  text: 'Key Point',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
