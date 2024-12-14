import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/auth/custom_textField.dart';
import '../../../../common/widgets/customAppBar.dart';

class HelpSupportView extends GetView {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for the text fields
    final emailController = TextEditingController();
    final problemController = TextEditingController();

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          // Action for the first button
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          // Action for the second button
          print("Second icon pressed");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              controller: emailController, hint: 'Enter Email', // Attach controller
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Description',
              controller: problemController, hint: 'Write Your Problem', // Attach controller
            ),
            const Spacer(),
            CustomButton(
              text: 'Send',
              onPressed: () {
                _validateAndSend(context, emailController, problemController);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndSend(BuildContext context, TextEditingController emailController, TextEditingController problemController) {
    final email = emailController.text.trim();
    final problem = problemController.text.trim();

    if (email.isEmpty || problem.isEmpty) {
      // Show a snackbar or dialog if fields are empty
      Get.snackbar(
        'Error',
        'Please fill out all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else if (!_isValidEmail(email)) {
      // Show an error if email is invalid
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else {
      // If validation passes, show the confirmation dialog
      _showConfirmationDialog(context);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Column(
            children: [
              Text(
                'Help!',
                textAlign: TextAlign.center,
                style: h1.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Our team will contact you within 24 hours',
                textAlign: TextAlign.center,
                style: h4.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'OK',
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                isEditPage: true,
                textColor: AppColors.textColor,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }
}
