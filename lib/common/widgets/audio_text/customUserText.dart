import 'package:flutter/material.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';

class CustomUserText extends StatelessWidget {
  final String name;
  final String time;
  final String description;
  final Color UserColor;

  const CustomUserText({
    Key? key,
    required this.name,
    required this.time,
    required this.description,
    required this.UserColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$name ',
                  style: h4.copyWith(fontSize: 20, color: UserColor),
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
          style: h4.copyWith(fontSize: 20),
        ),
        SizedBox(height: 20,),
      ],
    );
  }
}
