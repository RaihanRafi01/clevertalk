import 'dart:convert';
import 'dart:ffi';
import 'package:clevertalk/app/modules/audio/controllers/audio_controller.dart';
import 'package:clevertalk/app/modules/authentication/views/authentication_view.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../../data/services/notification_services.dart';
import '../../authentication/views/verify_o_t_p_view.dart';
import '../../dashboard/views/dashboard_view.dart';

class HomeController extends GetxController {
  final ApiService _service = ApiService();
  var email = ''.obs;
  var password = ''.obs;
  var username = ''.obs;
  var isLoading = false.obs;
  var profilePicUrl = ''.obs; // Store the profile picture URL
  final RxString usernameOBS = ''.obs;
  var name = ''.obs;
  var gender = ''.obs;
  var phone = ''.obs;
  var address = ''.obs;
  var user_type = ''.obs;
  var device_id_number = ''.obs;
  var subscriptionExpireDate = ''.obs;
  var subscriptionStatus = ''.obs;
  RxBool isExpired = false.obs;
  RxBool isFree = false.obs;
  RxBool isVerified = false.obs;
  RxInt paid_plan_minutes_left = 0.obs;
  RxInt recorder_plan_minutes_left = 0.obs;
  RxInt free_plan_minutes_left = 0.obs;
  RxInt total_minutes_left = 0.obs;
  RxBool hasSentLowMinutesNotification = false.obs;

  // Save the notification flag to SharedPreferences
  Future<void> _saveNotificationFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSentLowMinutesNotification', value);
    hasSentLowMinutesNotification.value = value;
  }


  Future<void> fetchProfileData() async {
    // Check if the account is verified
    final http.Response verificationResponse = await _service.getProfileInformation();

    print('fetchProfileData CODE : ${verificationResponse.statusCode}');
    print('fetchProfileData body : ${verificationResponse.body}');

    if (verificationResponse.statusCode == 200) {
      final responseData = jsonDecode(verificationResponse.body);
      //String? _subscriptionStatus = responseData['subscription_status'];
      //String? _subscriptionExpireDate = responseData['subscription_expires_on'];
      //bool? _isExpired = responseData['is_expired'];

      print('::::::::::::::::::::::::::::::::RESPONSE: ${responseData.toString()}');

      String? _username = responseData['username'];
      String? _email = responseData['email'];
      String? _profilePicture = responseData['profile_picture'];
      String? _phone = responseData['phone_number'];
      String? _address = responseData['address'];
      String? _name = responseData['full_name'];
      String? _gender = responseData['gender'];
      String? _user_type = responseData['user_type'];
      bool? _is_verified = responseData['is_verified']; // Corrected type
      String? _device_id_number = responseData['device_id_number'];
      int? _paid_plan_minutes_left = responseData['paid_plan_minutes_left'];
      int? _recorder_plan_minutes_left = responseData['recorder_plan_minutes_left'];
      int? _free_plan_minutes_left = responseData['free_plan_minutes_left'];


      username.value = _username ?? '';
      email.value = _email ?? '';
      profilePicUrl.value = _profilePicture ?? '';
      phone.value = _phone ?? '';
      address.value = _address ?? '';
      name.value = _name ?? '';
      gender.value = _gender ?? '';
      user_type.value = _user_type ?? '';
      isVerified.value = _is_verified ?? false; // Corrected assignment
      device_id_number.value = _device_id_number ?? '';
      paid_plan_minutes_left.value = _paid_plan_minutes_left ?? 0;
      recorder_plan_minutes_left.value = _recorder_plan_minutes_left ?? 0;
      free_plan_minutes_left.value = _free_plan_minutes_left ?? 0;

      //subscriptionStatus.value = _subscriptionStatus ?? '';
      //subscriptionExpireDate.value = _subscriptionExpireDate ?? '';
      //isExpired.value = _isExpired ?? false;


      total_minutes_left.value = paid_plan_minutes_left.value +
          recorder_plan_minutes_left.value +
          free_plan_minutes_left.value - 590;

      if (total_minutes_left.value < 20 && !hasSentLowMinutesNotification.value) {
        await NotificationService.showNotification(
          title: 'Low Minutes Warning',
          body: 'You have less than 20 minutes remaining. Explore plans to add more!',
          payload: 'subscription_page',
        );
        await _saveNotificationFlag(true); // Save flag to prevent duplicates
      } else if (total_minutes_left.value >= 20 && hasSentLowMinutesNotification.value) {
        await _saveNotificationFlag(false); // Reset flag when minutes are sufficient
      }

      print('::::::::::::::::::::paid_plan_minutes_left:::::::::::::::::::::::::::$paid_plan_minutes_left');
      print('::::::::::::::::::::recorder_plan_minutes_left:::::::::::::::::::::::::::$recorder_plan_minutes_left');
      print('::::::::::::::::::::free_plan_minutes_left:::::::::::::::::::::::::::$free_plan_minutes_left');

      //isFree.value = subscriptionStatus.value != 'not_subscribed';

    }
    else if (verificationResponse.statusCode == 401){

      await NotificationService.showNotification(
        title: 'Session Expired',
        body: 'Your session has expired. Please log in again.',
        payload: 'login_page', // Payload to navigate to AuthenticationView
      );
      final FlutterSecureStorage storage = FlutterSecureStorage();
      await FlutterSecureStorage().deleteAll();
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      // SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false); // User is logged out
      Get.offAll(() => AuthenticationView()); // Navigate to the login screen

    }
    else {
      //Get.snackbar('Error', 'Verification status check failed');
    }
  }

  Future<void> checkVerified(String username) async {
    // Check if the account is verified
    final http.Response verificationResponse = await _service.getProfileInformation();

    if (verificationResponse.statusCode == 200) {
      final responseData = jsonDecode(verificationResponse.body);

      bool isVerified = responseData['is_verified'];


      if (isVerified) {
        // Navigate to the Dashboard if verified
        //Get.snackbar('Success', 'Account verified!');
        Get.offAll(() => DashboardView()); // Navigate to DashboardView
      } else {
        // Show a page to request further action if not verified
        Get.snackbar('Verification', 'Account not verified. Please check your email.');
        Get.off(() => VerifyOTPView(username: username));
      }

    } else {
      //Get.snackbar('Error', 'Verification status check failed');
    }
  }


}
