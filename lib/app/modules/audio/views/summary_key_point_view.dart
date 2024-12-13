import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../common/customFont.dart';

class SummaryKeyPointView extends GetView {
  final bool isKey;
  const SummaryKeyPointView({super.key,this.isKey = false});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SummaryKeyPointView'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                isKey?
                Text(
                  'Key Point of Customer Feedback',
                  style: h1.copyWith(fontSize: 20),
                ) : Text(
                  'Summary of Customer Feedback',
                  style: h1.copyWith(fontSize: 20),
                ) ,
                SizedBox(height: 20),
                isKey?
                Text(
                  '1/  The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. \n\n2/  The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. ',
                  style: h4.copyWith(fontSize: 20),
                ) : Text(
                  'The goal of this project is to develop an innovative platform that combines audio recording and transcription with multilingual support. Designed to cater to individual users and professionals, the platform integrates seamlessly with a dedicated audio recorder device and offers tools for efficient file management, transcription, and content summarization. This user-friendly application supports English, French, Spanish, German, and Italian, ensuring accessibility for a global audience.',
                  style: h4.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
