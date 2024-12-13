import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String svgPath;
  final VoidCallback onTap;
  final double height;

  const SvgIcon({
    required this.svgPath,
    required this.onTap,
    required this.height,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        svgPath,
        height: height,
      ),
    );
  }
}