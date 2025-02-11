import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';

class SummaryKeyPointView extends GetView {
  final String keyPoints;
  const SummaryKeyPointView({super.key, required this.keyPoints});

  @override
  Widget build(BuildContext context) {
    // Parse the JSON string
    final Map<String, dynamic> data = json.decode(keyPoints);

    // Extract data
    final String title = data["Title"] ?? "No Title";
    final List<dynamic> mainPoints = data["Main Points"] ?? [];
    final List<dynamic> conclusions = data["Conclusions"] ?? [];

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: h1.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Key Points Section
              Text(
                'Key Points:',
                style: h2.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...mainPoints.map((point) {
                String key = point.keys.first; // Extract key (e.g., "Key Point 1")
                String value = point.values.first; // Extract text
                return _buildBulletPoint(key, value);
              }).toList(),

              SizedBox(height: 20),

              // Conclusions Section
              if (conclusions.isNotEmpty) ...[
                Text(
                  'Conclusions:',
                  style: h2.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ...conclusions.map((conclusion) {
                  String key = conclusion.keys.first; // Extract key (e.g., "Conclusion 1")
                  String value = conclusion.values.first; // Extract text
                  return _buildBulletPoint(key, value);
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Bullet point widget with title on top and justified text
  Widget _buildBulletPoint(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: h4.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

}
