import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../appColors.dart';
import '../../customFont.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final bool isGem;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isEditPage;
  final double width;
  final double height;
  final double fontSize;
  final String svgAsset;

  const CustomButton({
    super.key,
    required this.text,
    this.isGem = false,
    required this.onPressed,
    this.backgroundColor = AppColors.appColor,
    this.borderColor = AppColors.appColor,
    this.textColor = Colors.white,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
    this.isEditPage = false,
    this.width = double.maxFinite,
    this.height = 40,
    this.fontSize = 16,
    this.svgAsset = 'assets/images/profile/gem.svg',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: !isEditPage
          ? ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Center( // Wrap the child in a Center widget
          child: isGem ? textWithIcon() : Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
        ),
      )
          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          backgroundColor: backgroundColor,
          padding: padding, // Ensure padding is consistent
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Center( // Wrap the child in a Center widget
          child: isGem ? textWithIcon() : Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget textWithIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min, // Ensure Row takes only the space it needs
      mainAxisAlignment: MainAxisAlignment.center, // Center the Row contents
      children: [
        if (isGem && svgAsset.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // Consistent spacing
            child: SvgPicture.asset(
              svgAsset,
              width: 20.0,
              height: 20.0,
            ),
          ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: h4.copyWith(
            fontSize: fontSize,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}