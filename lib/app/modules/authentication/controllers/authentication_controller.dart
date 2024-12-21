import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/api_services.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../home/controllers/home_controller.dart';

class AuthenticationController extends GetxController {
  final HomeController homeController = Get.put(HomeController());
  final ApiService _service = ApiService();
  var isLoading = false.obs; // Reactive loading state


  // Observable variable to store username
  //final RxString usernameOBS = ''.obs;

  final FlutterSecureStorage _storage = FlutterSecureStorage(); // For secure storage


  // Store tokens securely
  Future<void> storeTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> signUp(String email, String password, String username) async {
    isLoading.value = true; // Show the loading screen
    try {
      final http.Response response = await _service.signUp(
          email, password, username);

      print(':::::::::::::::RESPONSE:::::::::::::::::::::${response.body.toString()}');
      print(':::::::::::::::CODE:::::::::::::::::::::${response.statusCode}');
      print(':::::::::::::::REQUEST:::::::::::::::::::::${response.request}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the server responds with success on code 200 or 201
        final responseBody = jsonDecode(response.body);
        final accessToken = responseBody['access_token'];
        final refreshToken = responseBody['refresh_token'];

        // Store the tokens securely
        await storeTokens(accessToken, refreshToken);

        print(':::::::::::::::responseBody:::::::::::::::::::::$responseBody');
        print(':::::::::::::::accessToken:::::::::::::::::::::$accessToken');
        print(':::::::::::::::refreshToken:::::::::::::::::::::$refreshToken');

        Get.snackbar('Success', 'Account created successfully!');
        //Get.off(() => VerifyOTPView());


        // SharedPreferences

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // User is logged in

        Get.offAll(() => DashboardView());

      } else {
        final responseBody = jsonDecode(response.body);
        Get.snackbar('Error', responseBody['message'] ?? 'Sign-up failed\nPlease Use Different Username');
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
      print('Error: $e');
    }finally {
      isLoading.value = false; // Hide the loading screen
    }
  }

  Future<void> login(String username, String password) async {
    isLoading.value = true; // Show the loading screen
    try {
      final http.Response response = await _service.login(username,password);

      print(':::::::::::::::RESPONSE:::::::::::::::::::::${response.body.toString()}');
      print(':::::::::::::::CODE:::::::::::::::::::::${response.statusCode}');
      print(':::::::::::::::REQUEST:::::::::::::::::::::${response.request}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the server responds with success on code 200 or 201
        final responseBody = jsonDecode(response.body);
        final accessToken = responseBody['access_token'];
        final refreshToken = responseBody['refresh_token'];

        // Store the tokens securely
        await storeTokens(accessToken, refreshToken);

        print(':::::::::::::::responseBody:::::::::::::::::::::$responseBody');
        print(':::::::::::::::accessToken:::::::::::::::::::::$accessToken');
        print(':::::::::::::::refreshToken:::::::::::::::::::::$refreshToken');

        Get.snackbar('Success', 'Logged in successfully!');
        //Get.off(() => VerifyOTPView());


        // SharedPreferences

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // User is logged in

        Get.offAll(() => DashboardView());

      } else {
        final responseBody = jsonDecode(response.body);
        Get.snackbar('Login failed', responseBody['message'] ?? 'Please use Correct UserName and Password');
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
      print('Error: $e');
    }finally {
      isLoading.value = false; // Hide the loading screen
    }
  }
}
