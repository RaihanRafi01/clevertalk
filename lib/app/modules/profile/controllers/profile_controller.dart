import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../data/services/api_services.dart';
import '../../home/controllers/home_controller.dart';

class ProfileController extends GetxController {
  final HomeController homeController = Get.put(HomeController());
  final ApiService _service = ApiService();
  var isTextVisible = false.obs;

  /// Toggle visibility for a text field (e.g., password or sensitive info)
  void toggleTextVisibility() {
    isTextVisible.value = !isTextVisible.value;
  }

  /// Update the name
  void updateName(String newValue) {
    homeController.name.value = newValue;
    print('::::::::::::::::::::::::::::::::::::::::::::update hit');
  }

  void updatePhone(String newValue) {
    homeController.phone.value = newValue;
    print('::::::::::::::::::::::::::::::::::::::::::::update hit');
  }

  void updateAddress(String newValue) {
    homeController.address.value = newValue;
    print('::::::::::::::::::::::::::::::::::::::::::::update hit');
  }

  void updateGender(String newValue) {
    homeController.gender.value = newValue;
    print('::::::::::::::::::::::::::::::::::::::::::::update hit');
  }


  /// Update profile data (name, aboutYou, and profile picture)
  Future<void> updateData(String? newName, String? newPhone, String? newAddress, String? newGender, File? profilePic) async {
    try {
      // Pass profilePic as nullable to the updateProfile method
      final http.Response response = await _service.updateProfile(newName, newPhone, newAddress, newGender, profilePic);

      if (response.statusCode == 200) {
        // Update local values with the new data
        if (newName != null) homeController.name.value = newName;
        //if (newAboutYou != null) homeController.aboutYou.value = newAboutYou;

        // If the profile picture was updated, fetch the updated profile
        if (profilePic != null) {
          //await fetchData();
          await homeController.fetchProfileData();
        }

        Get.snackbar('Success', 'Profile updated successfully');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update profile';
        Get.snackbar('Error', error);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }
}
