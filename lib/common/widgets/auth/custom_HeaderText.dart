import 'package:flutter/material.dart';

import '../../appColors.dart';

class CustomHeadertext extends StatelessWidget {
  final String header1;
  final String header2;
  const CustomHeadertext({super.key, required this.header1, required this.header2});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header1,
          style: TextStyle(fontSize: 24,color: AppColors.textHeader,fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16,),
        Text(
          header2,
          style: TextStyle(fontSize: 14,color: AppColors.textHeader2),
        ),
      ],
    );
  }
}
