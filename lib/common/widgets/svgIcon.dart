import 'package:clevertalk/common/appColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String svgPath;
  final VoidCallback onTap;
  final double height;
  final Color? color;

  const SvgIcon({
    required this.svgPath,
    required this.onTap,
    required this.height,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        svgPath,
        height: height,
        color: color,
      ),
    );
  }
}