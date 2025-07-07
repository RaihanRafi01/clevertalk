import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/auth/custom_HeaderText.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/auth/custom_textField.dart';
import '../controllers/authentication_controller.dart';

class ResetPasswordView extends GetView {
  final String userName;
  const ResetPasswordView({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final AuthenticationController _controller = Get.put(AuthenticationController());
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    void validateAndResetPassword() async {
      String password = passwordController.text.trim();
      String confirmPassword = confirmPasswordController.text.trim();

      if (password.isEmpty || confirmPassword.isEmpty) {
        Get.snackbar(
          "Error",
          "Both fields are required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else if (password == confirmPassword) {
        // Call the resetPassword API
        await _controller.resetPassword(userName, password);
      } else {
        Get.snackbar(
          "Error",
          "Passwords do not match",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: SvgPicture.asset('assets/images/auth/app_logo.svg'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomHeadertext(
                    header1: "Reset Password",
                    header2: "Enter a new password",
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: passwordController,
                    label: "Password",
                    hint: "Enter Password",
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  CustomTextField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    hint: "Confirm Password",
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: "Reset Password",
                    onPressed: validateAndResetPassword,
                  ),
                ],
              ),
            ),
          ),
          // Loading Indicator
          Obx(() {
            return _controller.isLoading.value
                ? Container(
              color: Colors.black54,
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
