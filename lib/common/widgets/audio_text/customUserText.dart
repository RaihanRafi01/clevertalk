import 'package:flutter/material.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';

class CustomUserText extends StatelessWidget {
  final String name;
  final String time;
  final String description;
  final Color UserColor;
  final bool isHighlighted;

  const CustomUserText({
    Key? key,
    required this.name,
    required this.time,
    required this.description,
    required this.UserColor,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.yellow.withOpacity(0.3) : Colors.transparent,  // Highlight background if true
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlighted ? AppColors.appColor : Colors.transparent, width: 2), // Optional border for highlighted state
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$name ',
                    style: h4.copyWith(
                      fontSize: 20,
                      color: UserColor,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, // Bold for highlighted
                    ),
                  ),
                  TextSpan(
                    text: time,
                    style: h4.copyWith(fontSize: 20, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            description,
            style: h4.copyWith(
              fontSize: 20,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,  // Bold for highlighted
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
