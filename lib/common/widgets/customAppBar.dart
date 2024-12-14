import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../customFont.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String firstIcon;
  final String secondIcon;
  final VoidCallback onFirstIconPressed;
  final VoidCallback onSecondIconPressed;
  final bool isSearch;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.isSearch = false,
    this.firstIcon = 'assets/images/home/search_icon.svg',
    this.secondIcon = 'assets/images/settings/notification_icon.svg',
    required this.onFirstIconPressed,
    required this.onSecondIconPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent, // You can customize the background color
      elevation: 0, // Optional: Removes the shadow under the AppBar
      title: Text(
        title,
        style: h1.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if(isSearch)
        // First SVG Icon Button
        IconButton(
          onPressed: onFirstIconPressed,
          icon: SvgPicture.asset(
            firstIcon,
            height: 24,
            width: 24,
          ),
        ),
        // Second SVG Icon Button
        IconButton(
          onPressed: onSecondIconPressed,
          icon: SvgPicture.asset(
            secondIcon,
            height: 24,
            width: 24,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
