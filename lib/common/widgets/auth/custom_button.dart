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
  final bool isBold;

  const CustomButton({
    super.key,
    required this.text,
    this.isGem = false,
    this.isBold = false,
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
        child: Center(
          child: isGem
              ? textWithIcon()
              : (isBold ? boldFirstWordText() : regularText()),
        ),
      )
          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          backgroundColor: backgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Center(
          child: isGem
              ? textWithIcon()
              : (isBold ? boldFirstWordText() : regularText()),
        ),
      ),
    );
  }

  Widget regularText() {
    return Text(
      isEditPage ? text.toUpperCase() : text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, color: textColor),
    );
  }

  Widget boldFirstWordText() {
    final words = text.split(' ');
    if (words.isEmpty) {
      return Text(
        '',
        style: TextStyle(fontSize: fontSize, color: textColor),
      );
    }

    final firstWord = words[0];
    final remainingWords = words.length > 1 ? words.sublist(1).join(' ') : '';

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: isEditPage ? firstWord.toUpperCase() : firstWord,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: FontWeight.bold, // Bold for the first word
            ),
          ),
          if (remainingWords.isNotEmpty)
            TextSpan(
              text: isEditPage ? ' ${remainingWords.toUpperCase()}' : ' $remainingWords',
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: FontWeight.normal, // Normal for remaining words
              ),
            ),
        ],
      ),
    );
  }

  Widget textWithIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isGem && svgAsset.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SvgPicture.asset(
              svgAsset,
              width: 20.0,
              height: 20.0,
            ),
          ),
        isBold
            ? boldFirstWordText()
            : Text(
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