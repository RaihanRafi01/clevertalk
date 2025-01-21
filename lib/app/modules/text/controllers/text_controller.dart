import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/api_services.dart';

class ConvertToTextController extends GetxController {
  var messages = <Map<String, String>>[].obs;
  var highlightedTimestamp = ''.obs;
  var currentHighlightedIndex = (-1).obs;
  var isLoading = false.obs;
  final ScrollController scrollController = ScrollController();

  Future<void> fetchMessages(String filePath, String fileName) async {
    final ApiService _apiService = ApiService();
    try {
      isLoading.value = true;
      final response = await _apiService.fetchTranscription(filePath, fileName);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['Data'] as List;
        messages.value = data.map<Map<String, String>>((entry) {
          final speakerName = entry['Speaker_Name'] as String;
          final transcript = entry['Transcript'] as String;
          final startTime = formatTimestamp(entry['Start_time'] as double);
          final endTime = formatTimestamp(entry['End_time'] as double);
          return {
            'name': speakerName,
            'time': '$startTime - $endTime',
            'description': transcript,
          };
        }).toList();
      } else {
        Get.snackbar('Error', 'Failed to fetch data: ${response.reasonPhrase}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String formatTimestamp(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }
}