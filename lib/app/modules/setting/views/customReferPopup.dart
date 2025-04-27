import 'package:flutter/material.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';

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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Call your send referral logic here
              print('Referral email: ${_emailController.text}');
              widget.onSendPressed();
              Navigator.pop(context);
            }
          },
          child: Text('Send', style: h2.copyWith(color: AppColors.appColor)),
        ),
      ],
    );
  }
}