import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';

class SummaryKeyPointView extends GetView {
  final bool isKey;
  final String summary;
  final String keyPoints;
  const SummaryKeyPointView({super.key,this.isKey = false,required this.summary,required this.keyPoints});
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
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 30),
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
                  keyPoints,
                  style: h4.copyWith(fontSize: 20),
                ) : Text(
                  summary,
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
