import 'package:clevertalk/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../controllers/setting_controller.dart';

class CustomReferPopup extends StatefulWidget {
  final VoidCallback onSendPressed;

  const CustomReferPopup({super.key, required this.onSendPressed});

  @override
  _CustomReferPopupState createState() => _CustomReferPopupState();
}

class _CustomReferPopupState extends State<CustomReferPopup> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final HomeController homeController = Get.find<HomeController>();
    return AlertDialog(
      title: Text('Refer a Friend', style: h2),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your friend\'s email address', style: h3),
            SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
                hintText: 'friend@example.com',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: h2.copyWith(color: AppColors.appColor)),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              await settingController.sendInvite(_emailController.text, homeController.username.value);
              print('Referral email: ${_emailController.text}');
            }
          },
          child: Text('Send', style: h2.copyWith(color: AppColors.appColor)),
        ),
      ],
    );
  }
}