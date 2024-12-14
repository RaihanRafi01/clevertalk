import 'package:clevertalk/app/modules/audio/views/convert_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/svgIcon.dart';

class AudioPlayerView extends GetView {
  const  AudioPlayerView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          // Action for the first button
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          // Action for the second button
          print("Second icon pressed");
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SvgPicture.asset('assets/images/audio/audio_icon.svg'),
              Text('Customer Feedback',style: h1.copyWith(fontSize: 20,color: AppColors.textHeader),),
              SizedBox(height: 20,),
              Slider(
                value: 0.5,
                onChanged: (value) {},
                activeColor: AppColors.appColor,
                inactiveColor: Colors.grey,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgIcon(height: 30, svgPath: 'assets/images/audio/previous_icon.svg', onTap: () {  },),
                  SvgIcon(height: 30, svgPath: 'assets/images/audio/previous_10_icon.svg', onTap: () {  },),
                  SvgIcon(height: 76, svgPath: 'assets/images/audio/pause_icon.svg', onTap: () {  },),
                  SvgIcon(height: 30, svgPath: 'assets/images/audio/next_10_icon.svg', onTap: () {  },),
                  SvgIcon(height: 30,  svgPath: 'assets/images/audio/next_icon.svg', onTap: () {  },),
                ],
              ),
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomButton(text: 'Convert To Text', onPressed: () => Get.to(() => ConvertView()),),
              ),
              SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }
}
