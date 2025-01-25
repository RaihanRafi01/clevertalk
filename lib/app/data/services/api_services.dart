import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {

  final FlutterSecureStorage _storage = FlutterSecureStorage(); // For secure storage
  // Base URL for the API
  final String baseUrl = 'http://192.168.20.201:8000/'; // https://apparently-intense-toad.ngrok-free.app/     //     https://agcourt.pythonanywhere.com/   // https://charming-willingly-starfish.ngrok-free.app/

  // Sign-up method
  Future<http.Response> signUp(String email, String password, String username) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}authentication_app/normal_signup_signin/');

    // Headers for the HTTP request
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Request body
    final Map<String, String> body = {
      "email": email,
      "password": password,
      "username": username,
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // login method
  Future<http.Response> login(String username, String password) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}authentication_app/normal_signup_signin/');

    // Headers for the HTTP request
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Request body
    final Map<String, String> body = {
      "username": username,
      "password": password,
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> helpAndSupport(String email, String query) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}email_support/email_support/');


    String? accessToken = await _storage.read(key: 'access_token');

    // Headers for the HTTP request with Bearer token
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken", // Add the Bearer token
    };

    // Request body
    final Map<String, String> body = {
      "email": email,
      "query": query,
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // Add this method in ApiService
  Future<http.Response> verifyOTP(String username, String otp) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}authentication_app/verify_email/');

    // Headers for the HTTP request
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Request body
    final Map<String, String> body = {
      "username": username,
      "otp": otp,
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> verifyForgotOTP(String username, String otp) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}authentication_app/verify_email/');

    // Headers for the HTTP request
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Request body
    final Map<String, String> body = {
      "username": username,
      "otp": otp,
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /*Future<http.Response> resendOTP(String username) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}authentication_app/resend_otp/');

    // Retrieve the stored access token
    String? accessToken = await _storage.read(key: 'access_token');

    // Headers for the HTTP request with Bearer token
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken", // Add the Bearer token
    };


    // Make the POST request
    return await http.post(
      url,
      headers: headers
    );
  }*/


  Future<http.Response> sendOTP(String username) async {
    // Construct the endpoint URL
    final Uri url = Uri.parse('${baseUrl}authentication_app/resend_otp/');

    // Headers for the HTTP request
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Request body
    final Map<String, String> body = {
      "username": username
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }



  // Method to check verification status with Bearer token
  Future<http.Response> getProfileInformation() async {
    final Uri url = Uri.parse('${baseUrl}authentication_app/user_profile/');

    print('::::::::::::::::::::::::::::::::::::::::::::::::::HIT');
    // Retrieve the stored access token
    String? accessToken = await _storage.read(key: 'access_token');

    // Headers for the HTTP request with Bearer token
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken", // Add the Bearer token
    };

    // Make the GET request
    return await http.get(url, headers: headers);
  }


  Future<http.Response> updateProfile(String? name, String? phone, String? address, String? gender, File? profilePic) async {
    print(':::::::::::::::::::::NAME:::::::::::$name');

    String? accessToken = await _storage.read(key: 'access_token');
    final Uri url = Uri.parse('${baseUrl}authentication_app/user_profile/');

    try {
      // Prepare the multipart request
      var request = http.MultipartRequest('PATCH', url);

      // Add text fields to the request only if they are not null or empty
      if (name != null && name.isNotEmpty) {
        request.fields['full_name'] = name;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone_number'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (gender != null && gender.isNotEmpty) {
        request.fields['gender'] = gender;
      }

      // Add the profile picture file if it exists and is provided
      if (profilePic != null && profilePic.existsSync()) {
        var picStream = http.ByteStream(profilePic.openRead());
        var picLength = await profilePic.length();

        // Determine the file extension and set the content type accordingly
        String extension = profilePic.uri.pathSegments.last.split('.').last.toLowerCase();
        String contentType;

        switch (extension) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          default:
            contentType = 'application/octet-stream'; // Default if type is unknown
            break;
        }

        var picMultipart = http.MultipartFile(
          'profile_picture',
          picStream,
          picLength,
          filename: profilePic.uri.pathSegments.last,
          contentType: MediaType.parse(contentType),
        );
        request.files.add(picMultipart);
      }

      // Set the headers with the Bearer token
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Send the request and await the response
      final response = await request.send();

      // Check the status code and handle the response
      if (response.statusCode == 200) {
        // Convert the stream response to a normal response
        final responseString = await response.stream.bytesToString();
        print('Profile updated successfully: $responseString');
        return http.Response(responseString, 200);
      } else {
        final responseString = await response.stream.bytesToString();
        print('Failed to update profile: $responseString');
        return http.Response(responseString, response.statusCode);
      }
    } catch (e) {
      print('Error updating profile: $e');
      return http.Response('Error: $e', 500); // Return error with 500 status
    }
  }




  Future<http.Response> paymentRequest() async {
    final Uri url = Uri.parse('${baseUrl}subscription_app/buy_subscription_on_app/');

    // Retrieve the stored access token
    String? accessToken = await _storage.read(key: 'access_token');

    // Headers for the HTTP request with Bearer token
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken", // Add the Bearer token
    };

    // Make the GET request
    return await http.post(url, headers: headers);
  }


  Future<http.Response> resetPassword(String userName,String password) async {
    final Uri url = Uri.parse('${baseUrl}authentication_app/reset_password/');

    // Headers for the HTTP request with Bearer token
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Request body
    final Map<String, String> body = {
      "username": userName,
      "password": password
    };

    // Make the POST request
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

///////////////////////////////////////////////////////////// AUDIO ///////////////////////////


  Future<http.Response> convertToText(String filePath) async {
    final Uri url = Uri.parse('${baseUrl}handle_recording_stuff/speech_to_text/');

    // Retrieve the stored access token
    String? accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    // Read the audio file bytes
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist on the disk');
    }
    final fileData = await file.readAsBytes();

    // Prepare the multipart request
    final request = http.MultipartRequest('GET', url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'recording_file',
        fileData,
        filename: 'file.WAV',
      ));

    // Send the request and return the response
    final response = await request.send();
    return http.Response.fromStream(response);
  }



  // Method for fetching summary
  Future<http.Response> fetchSummary(String filePath, String fileName) async {
    final Uri url = Uri.parse('${baseUrl}handle_recording_stuff/generate_summary/');
    String? accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }
    final fileData = await file.readAsBytes();

    final request = http.MultipartRequest('GET', url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'recording_file',
        fileData,
        filename: 'file.WAV',
      ));

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // Method for fetching key points
  Future<http.Response> fetchKeyPoints(String filePath, String fileName) async {
    final Uri url = Uri.parse('${baseUrl}handle_recording_stuff/get_key_points/');
    String? accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }
    final fileData = await file.readAsBytes();

    final request = http.MultipartRequest('GET', url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'recording_file',
        fileData,
        filename: 'file.WAV',
      ));

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  Future<http.Response> fetchTranscription(String filePath, String fileName) async {
    final Uri url = Uri.parse('${baseUrl}handle_recording_stuff/generate_transcription/');

    String? accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }
    final fileData = await file.readAsBytes();

    final request = http.MultipartRequest('GET', url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'recording_file',
        fileData,
        filename: 'file.WAV',
      ));

    final response = await request.send();
    return http.Response.fromStream(response);
  }

}
