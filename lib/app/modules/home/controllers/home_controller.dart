import 'dart:convert';
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
  var profilePicUrl = ''.obs;
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
  RxDouble paid_plan_minutes_left = 0.0.obs;
  RxDouble recorder_plan_minutes_left = 0.0.obs;
  RxDouble free_plan_minutes_left = 0.0.obs;
  RxDouble total_minutes_left = 0.0.obs;
  RxBool hasSentLowMinutesNotification = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationFlag(); // Load the notification flag on initialization
  }

  // Load the notification flag from SharedPreferences
  Future<void> _loadNotificationFlag() async {
    print('hitttt  _loadNotificationFlag: ');
    final prefs = await SharedPreferences.getInstance();
    hasSentLowMinutesNotification.value = prefs.getBool('hasSentLowMinutesNotification') ?? false;
  }

  // Save the notification flag to SharedPreferences
  Future<void> _saveNotificationFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSentLowMinutesNotification', value);
    hasSentLowMinutesNotification.value = value;
  }

  Future<void> fetchProfileData() async {
    final http.Response verificationResponse = await _service.getProfileInformation();

    print('fetchProfileData CODE : ${verificationResponse.statusCode}');
    print('fetchProfileData body : ${verificationResponse.body}');

    if (verificationResponse.statusCode == 200) {
      final responseData = jsonDecode(verificationResponse.body);

      print('::::::::::::::::::::::::::::::::RESPONSE: ${responseData.toString()}');

      String? _username = responseData['username'];
      String? _email = responseData['email'];
      String? _profilePicture = responseData['profile_picture'];
      String? _phone = responseData['phone_number'];
      String? _address = responseData['address'];
      String? _name = responseData['full_name'];
      String? _gender = responseData['gender'];
      String? _user_type = responseData['user_type'];
      bool? _is_verified = responseData['is_verified'];
      String? _device_id_number = responseData['device_id_number'];
      double? _paid_plan_minutes_left = responseData['paid_plan_minutes_left'];
      double? _recorder_plan_minutes_left = responseData['recorder_plan_minutes_left'];
      double? _free_plan_minutes_left = responseData['free_plan_minutes_left'];

      username.value = _username ?? '';
      email.value = _email ?? '';
      profilePicUrl.value = _profilePicture ?? '';
      phone.value = _phone ?? '';
      address.value = _address ?? '';
      name.value = _name ?? '';
      gender.value = _gender ?? '';
      user_type.value = _user_type ?? '';
      isVerified.value = _is_verified ?? false;
      device_id_number.value = _device_id_number ?? '';
      paid_plan_minutes_left.value = _paid_plan_minutes_left ?? 0;
      recorder_plan_minutes_left.value = _recorder_plan_minutes_left ?? 0;
      free_plan_minutes_left.value = _free_plan_minutes_left ?? 0;

      total_minutes_left.value = paid_plan_minutes_left.value +
          recorder_plan_minutes_left.value +
          free_plan_minutes_left.value - 574.6;

      if (total_minutes_left.value < 20.0 && !hasSentLowMinutesNotification.value) {
        await NotificationService.showNotification(
          title: 'Low Minutes Warning',
          body: 'You have less than 20 minutes remaining. Explore plans to add more!',
          payload: 'subscription_page',
        );
        await _saveNotificationFlag(true); // Save flag to prevent duplicates
      } else if (total_minutes_left.value >= 20.0 && hasSentLowMinutesNotification.value) {
        await _saveNotificationFlag(false); // Reset flag when minutes are sufficient
      }

      print('::::::::::::::::::::paid_plan_minutes_left:::::::::::::::::::::::::::$paid_plan_minutes_left');
      print('::::::::::::::::::::recorder_plan_minutes_left:::::::::::::::::::::::::::$recorder_plan_minutes_left');
      print('::::::::::::::::::::free_plan_minutes_left:::::::::::::::::::::::::::$free_plan_minutes_left');
      print('::::::::::::::::::::total_minutes_left:::::::::::::::::::::::::::$total_minutes_left');
    } else if (verificationResponse.statusCode == 401) {
      await NotificationService.showNotification(
        title: 'Session Expired',
        body: 'Your session has expired. Please log in again.',
        payload: 'login_page',
      );
      final FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.deleteAll();
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      Get.offAll(() => AuthenticationView());
    } else {
      //Get.snackbar('Error', 'Verification status check failed');
    }
  }

  Future<void> checkVerified(String username) async {
    final http.Response verificationResponse = await _service.getProfileInformation();

    if (verificationResponse.statusCode == 200) {
      final responseData = jsonDecode(verificationResponse.body);

      bool isVerified = responseData['is_verified'];

      if (isVerified) {
        Get.offAll(() => DashboardView());
      } else {
        Get.snackbar('Verification', 'Account not verified. Please check your email.');
        Get.off(() => VerifyOTPView(username: username));
      }
    } else {
      //Get.snackbar('Error', 'Verification status check failed');
    }
  }
}