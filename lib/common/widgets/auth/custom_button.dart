import 'package:flutter/material.dart';

import '../../appColors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isEditPage;
  final double width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.appColor,
    this.borderColor = AppColors.appColor,
    this.textColor = Colors.white,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
    this.isEditPage = false,
    this.width = double.maxFinite,
    this.height = 45
  });

  @override
  Widget build(BuildContext context) {
    return  SizedBox(
      height: height,
      width: width, // Full-width button
      child: !isEditPage ? ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ) : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor), // Border color
          backgroundColor: backgroundColor, // Background color
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            textAlign: TextAlign.center,
            text.toUpperCase(),
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ),
      )
      ,
    );
  }
}
