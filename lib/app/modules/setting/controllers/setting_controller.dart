import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../data/services/api_services.dart';

class SettingController extends GetxController {
  var isWritingReminderOn = false.obs;
  var selectedLanguage = 'English'.obs;
  var isLoading = false.obs; // Reactive loading state
  final ApiService _service = ApiService();

  // Toggle method for the Writing Reminder
  void toggleWritingReminder(bool value) {
    isWritingReminderOn.value = value;
  }

  // Change the language
  void changeLanguage(String newLanguage) {
    selectedLanguage.value = newLanguage;
  }

  // Help and Support Function
  Future<void> helpAndSupport(String email, String query) async {
    isLoading.value = true; // Show the loading state
    try {
      final http.Response response =
          await _service.helpAndSupport(email, query);

      print('support Response Body: ${response.body}');
      print('Status Code: ${response.statusCode}');
      print('Request: ${response.request}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final responseBody = jsonDecode(response.body);
        print(':::::::::::::::::::::::::::::::::::::::::::::HIT HELP');
        Get.dialog(
          AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Column(
              children: [
                Text(
                  'Help!',
                  textAlign: TextAlign.center,
                  style: h1.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Our team will contact you within 24 hours',
                  textAlign: TextAlign.center,
                  style: h4.copyWith(fontSize: 16),
                ),
              ],
            ),
            actions: [
              CustomButton(
                text: 'OK',
                onPressed: () => Get.back(),
                // Close the dialog
                isEditPage: true,
                textColor: AppColors.textColor,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        );
      } else {
        // Failure
        final responseBody = jsonDecode(response.body);
        Get.snackbar(
            'Error',
            responseBody['message'] ??
                'Something went wrong. Please try again.');
      }
    } catch (e) {
      // Exception handling
      Get.snackbar('Error', 'An unexpected error occurred. Please try again.');
      print('Error: $e');
    } finally {
      isLoading.value = false; // Hide the loading state
    }
  }

  Future<void> sendInvite(String email, String username) async {
    isLoading.value = true; // Show the loading state
    try {
      final http.Response response = await _service.sendInvite(email, username);

      print('----------> sendInvite Response Body: ${response.body}');
      print('----------> sendInvite Status Code: ${response.statusCode}');
      print('----------> sendInvite Request: ${response.request}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        Get.dialog(
          AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Column(
              children: [
                Text(
                  'Success!',
                  textAlign: TextAlign.center,
                  style: h1.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Invitation sent successfully.',
                  textAlign: TextAlign.center,
                  style: h4.copyWith(fontSize: 16),
                ),
              ],
            ),
            actions: [
              CustomButton(
                text: 'OK',
                onPressed: () => Get.back(),
                // Close the dialog
                isEditPage: true,
                textColor: AppColors.textColor,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        );
      } else if (response.statusCode == 400) {
        Get.dialog(
          AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Column(
              children: [
                Text(
                  'Warning!',
                  textAlign: TextAlign.center,
                  style: h1.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'The User Was Already Invited.',
                  textAlign: TextAlign.center,
                  style: h4.copyWith(fontSize: 16),
                ),
              ],
            ),
            actions: [
              CustomButton(
                text: 'OK',
                onPressed: () => Get.back(),
                // Close the dialog
                isEditPage: true,
                textColor: AppColors.textColor,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        );
      } else {
        // Failure
        final responseBody = jsonDecode(response.body);
        Get.snackbar(
            'Error',
            responseBody['message'] ??
                'Something went wrong. Please try again.');
      }
    } catch (e) {
      // Exception handling
      Get.snackbar('Error', 'An unexpected error occurred. Please try again.');
      print('Error: $e');
    } finally {
      isLoading.value = false; // Hide the loading state
    }
  }
}
