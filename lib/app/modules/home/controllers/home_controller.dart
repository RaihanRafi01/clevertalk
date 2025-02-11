import 'dart:convert';
import 'dart:ffi';
import 'package:clevertalk/app/modules/audio/controllers/audio_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
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


  Future<void> fetchProfileData() async {
    // Check if the account is verified
    final http.Response verificationResponse = await _service.getProfileInformation();

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

      //subscriptionStatus.value = _subscriptionStatus ?? '';
      //subscriptionExpireDate.value = _subscriptionExpireDate ?? '';
      //isExpired.value = _isExpired ?? false;

      print('::::::::::::::::::::EMAIL:::::::::::::::::::::::::::$email');


      //isFree.value = subscriptionStatus.value != 'not_subscribed';

    } else {
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
