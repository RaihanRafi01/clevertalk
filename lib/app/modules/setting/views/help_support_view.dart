import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/auth/custom_textField.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../controllers/setting_controller.dart';

class HelpSupportView extends GetView<SettingController> {
  HelpSupportView({super.key});

  final emailController = TextEditingController(); // Text controllers
  final problemController = TextEditingController();
  final SettingController settingController = Get.put(SettingController());

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () => print("First icon pressed"),
        onSecondIconPressed: () => print("Second icon pressed"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              controller: emailController,
              hint: 'Enter Email',
            ),
            const SizedBox(height: 20),
            CustomTextField(
              maxLine: 4,
              label: 'Description',
              controller: problemController,
              hint: 'Write Your Problem',
            ),
            const Spacer(),
            Obx(() {
              return settingController.isLoading.value
                  ? const CircularProgressIndicator()
                  : CustomButton(
                text: 'Send',
                onPressed: _validateAndSend,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _validateAndSend() {
    final email = emailController.text.trim();
    final problem = problemController.text.trim();

    if (email.isEmpty || problem.isEmpty) {
      _showSnackbar('Error', 'Please fill out all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackbar('Error', 'Please enter a valid email address');
      return;
    }

    settingController.helpAndSupport(email, problem);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
