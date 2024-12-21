import 'dart:async';
import 'package:clevertalk/app/modules/authentication/views/reset_password_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/auth/pinCode_InputField.dart';

class VerifyOTPView extends StatefulWidget {
  const VerifyOTPView({Key? key}) : super(key: key);

  @override
  State<VerifyOTPView> createState() => _VerifyOTPViewState();
}

class _VerifyOTPViewState extends State<VerifyOTPView> {
  late Timer _timer;
  int _remainingSeconds = 30;
  bool _isResendEnabled = false;
  String? _verificationMessage; // To show "Code is Correct" or "Incorrect Code"

  @override
  void initState() {
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

  void _resendOTP() {
    print("OTP resent");
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'OTP has been sent to your Email',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            PinCodeInputField(
              onCompleted: (code) {
                // Validate the OTP
                setState(() {
                  if (code == "1234") {
                    _verificationMessage = "Code is Correct";
                  } else {
                    _verificationMessage = "Incorrect Code";
                  }
                });
              },
            ),
            if (_verificationMessage != null) // Only show message after `onCompleted`
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _verificationMessage!,
                  style: TextStyle(
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
              onPressed: () => Get.off(() => const ResetPasswordView()),
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
                  onTap: _isResendEnabled
                      ? () {
                    _resendOTP();
                  }
                      : null,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
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
    );
  }
}
