import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/auth/pinCode_InputField.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/authentication_controller.dart';

class VerifyOTPView extends StatefulWidget {
  final String? forgotUserName;
  final String username;
  final bool isForgot;
  const VerifyOTPView({super.key,this.forgotUserName,this.isForgot = false,required this.username});

  @override
  State<VerifyOTPView> createState() => _VerifyOTPViewState();
}

class _VerifyOTPViewState extends State<VerifyOTPView> {
  late Timer _timer;
  //late final String username;
  int _remainingSeconds = 30;
  bool _isResendEnabled = false;
  String? _verificationMessage; // To show "Code is Correct" or "Incorrect Code"
  final AuthenticationController _controller = Get.put(AuthenticationController());
  final TextEditingController _otpController = TextEditingController(); // For manual OTP input

  @override
  void initState() {
    //final HomeController homeController = Get.put(HomeController());
    //username = homeController.usernameOBS.value;
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isResendEnabled = false;
      _remainingSeconds = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isResendEnabled = true;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> _resendOTP() async {
    print("OTP resent");
    //final homeController = Get.put(HomeController());
    //await homeController.fetchProfileData();
    _controller.resendOTP(widget.username);
    _startTimer();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'OTP has been sent to your Email',
                  style: h4.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                PinCodeInputField(
                  onCompleted: (code) {
                    // Save the OTP entered by the user
                    _otpController.text = code;
                  },
                ),
                if (_verificationMessage != null) // Only show message after `onCompleted`
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _verificationMessage!,
                      style: h4.copyWith(
                        color: _verificationMessage == "Code is Correct"
                            ? Colors.green
                            : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                CustomButton(
                  borderRadius: 5,
                  width: 150,
                  text: "Verify OTP",
                  onPressed: () {
                    print(':::::::::::::::::::::::::USERNAME TO BE SENT:::${widget.username}');
                    final otp = _otpController.text.trim();
                    if (otp.isEmpty) {
                      Get.snackbar('Error', 'Please enter the OTP');
                    } else {
                      widget.isForgot
                          ? _controller.verifyForgotOTP(widget.forgotUserName!, otp)
                          : _controller.verifyOTP(widget.username, otp);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const Text(' | ', style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: _isResendEnabled ? _resendOTP : null,
                      child: Text(
                        'Resend OTP',
                        style: h4.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isResendEnabled
                              ? AppColors.appColor
                              : Colors.grey, // Grey if disabled
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Loading Indicator
          Obx(() {
            return _controller.isLoading.value
                ? Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
