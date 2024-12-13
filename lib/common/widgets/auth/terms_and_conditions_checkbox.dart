import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:clevertalk/common/appColors.dart';

// New widget class for Checkbox and Terms/Privacy Policy logic
class TermsAndConditionsCheckbox extends StatefulWidget {
  final Function(bool) onCheckboxChanged;

  const TermsAndConditionsCheckbox({super.key, required this.onCheckboxChanged});

  @override
  _TermsAndConditionsCheckboxState createState() => _TermsAndConditionsCheckboxState();
}

class _TermsAndConditionsCheckboxState extends State<TermsAndConditionsCheckbox> {
  bool _isChecked = false;

  // Method to show BottomSheet with Terms & Conditions or Privacy Policy text
  void _showBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(content),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the BottomSheet
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: AppColors.appColor,
          checkColor: Colors.white,
          value: _isChecked,
          onChanged: (bool? value) {
            setState(() {
              _isChecked = value ?? false;
            });
            widget.onCheckboxChanged(_isChecked);  // Notify parent widget about the checkbox state
          },
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'By creating an account, I accept the ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _showBottomSheet(
                        "Terms & Conditions",
                        "Here are the detailed terms and conditions for the app...",
                      );
                    },
                ),
                TextSpan(
                  text: ' & ',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _showBottomSheet(
                        "Privacy Policy",
                        "Here are the privacy policies of the app...",
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
