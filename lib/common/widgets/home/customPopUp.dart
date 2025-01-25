import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../appColors.dart';
import '../../customFont.dart';

class CustomPopup extends StatefulWidget {
  final String title;
  final VoidCallback onButtonPressed;
  final bool isSecondInput;
  final String hint1;
  final String hint2;
  final String btnText;
  final String fieldName;
  final TextEditingController controller; // Accept controller here

  const CustomPopup({
    super.key,
    required this.title,
    required this.onButtonPressed,
    this.isSecondInput = false,
    this.hint1 = 'Untitled',
    this.hint2 = 'Untitled',
    this.btnText = 'Save',
    this.fieldName = 'Set a name',
    required this.controller, // Initialize controller
  });

  @override
  _CustomPopupState createState() => _CustomPopupState();
}

class _CustomPopupState extends State<CustomPopup> {
  // Controllers for the text fields
  //final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Popup text
                Text(widget.title, style: h1.copyWith(
                    fontSize: 24,
                color: AppColors.textHeader),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.fieldName , style: h1.copyWith(
                      fontSize: 20,
                      color: AppColors.textHeader),
                  ),
                ),
                SizedBox(height: 20),
                // First TextField (Optional)
                TextField(
                  controller: widget.controller, // Use the passed controller
                  decoration: InputDecoration(
                    hintText: widget.hint1,
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                      borderSide: BorderSide(color: AppColors.appColor, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.appColor, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                if(widget.isSecondInput)
                // Second TextField (Optional)
                TextField(
                  controller: _controller2,
                  decoration: InputDecoration(
                    hintText: widget.hint2,
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                      borderSide: BorderSide(color: AppColors.appColor, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.appColor, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Button to trigger action
                CustomButton(
                  text: widget.btnText,
                  onPressed: widget.onButtonPressed,
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: (){
                Navigator.of(context).pop();
              },
                child: SvgPicture.asset('assets/images/home/popup_cancel_icon.svg'))
          ),
        ],
      ),
    );
  }
}
