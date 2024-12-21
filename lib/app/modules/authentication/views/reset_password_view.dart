import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/auth/custom_HeaderText.dart';
import '../../../../common/widgets/auth/custom_textField.dart';
import '../../../../common/widgets/auth/popUpWidget.dart';

class ResetPasswordView extends GetView {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    void validateAndShowBottomSheet() {
      String password = passwordController.text;
      String confirmPassword = confirmPasswordController.text;

      if (password.isEmpty || confirmPassword.isEmpty) {
        Get.snackbar(
          "Error",
          "Both fields are required",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else if (password == confirmPassword) {
        Get.bottomSheet(
          PasswordChangedBottomSheet(
            onBackToLogin: () {
              Get.back(); // Close the bottom sheet
              // Navigate to the login screen or perform another action here
            },
          ),
          isScrollControlled: true,  // Makes sure the bottom sheet can be custom-sized
        );
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
      body: Padding(
        padding: const EdgeInsets.all(16),
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
              onPressed: validateAndShowBottomSheet,
            ),
          ],
        ),
      ),
    );
  }
}
