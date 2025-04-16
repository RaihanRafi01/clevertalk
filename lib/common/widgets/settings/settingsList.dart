import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../appColors.dart';
import '../../customFont.dart';

class SettingsList extends StatelessWidget {
  final String svgPath;
  final String text;
  final VoidCallback onTap; // Callback for tap actions
  final bool isTogol;
  final bool isToggled;
  final Function(bool)? onToggleChanged; // Callback for toggle change

  const SettingsList({
    super.key,
    required this.svgPath,
    required this.text,
    this.isTogol = false,
    required this.onTap, // Required onTap callback
    this.isToggled= false, // Toggle state
    this.onToggleChanged, // Optional toggle callback
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Call the provided callback when tapped
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 20),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(svgPath,height: 16,),
                SizedBox(width: 10),
                Text(
                  text,
                  style: h4.copyWith(fontSize: 13),
                ),
                Spacer(),
                isTogol
                    ? Switch(
                  activeColor: AppColors.appColor,
                  inactiveThumbColor: AppColors.appColor,
                  inactiveTrackColor: AppColors.appColor3,
                  activeTrackColor: AppColors.appColor3,
                  value: isToggled, // Use the value from the controller
                  onChanged: onToggleChanged, // Update state when toggled
                )
                    : Icon(Icons.navigate_next),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
