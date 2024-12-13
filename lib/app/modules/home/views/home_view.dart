import 'package:clevertalk/app/modules/home/views/record_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/home/audioPlayerCard.dart';
import '../../../../common/widgets/home/videoCard.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  CustomButton(text: 'Connect Devices', onPressed: (){},width: 160,borderRadius: 5),
                  Spacer(),
                  CustomButton(text: 'Get A Plan', onPressed: (){},width: 160,borderRadius: 5,backgroundColor: AppColors.appColor2,),
                ],
              ),
              SizedBox(height: 20,),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.appColor, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Device ID Number : ',
                      style: h4.copyWith(fontSize: 16, color: AppColors.textHeader2),
                    ),
                    Text(
                      '32bg264',
                      style: h4.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeader2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10,),
              VideoCard(
                videoUrl: 'https://pixabay.com/videos/ocean-sea-beach-sunset-sand-204565/',
                onNextVideo: () {
                  print('Navigate to next video');
                },
                onPreviousVideo: () {
                  print('Navigate to previous video');
                },
              ),
              SizedBox(height: 10,),
              Stack(
                children: [
                  // Background image
                  Image.asset(
                    'assets/images/home/card2.png',
                    width: double.infinity,
                    fit: BoxFit.cover, // Adjust the image's fit if necessary
                  ),
                  // Positioned text
                  Positioned(
                    right: 20, // Distance from the right edge of the image
                    top: 10,   // Distance from the top edge of the image
                    child: Container(
                      padding: EdgeInsets.all(8), // Padding inside the container
                      child: Column(
                        children: [
                          Text(
                            'Pre order',
                            style: h1.copyWith(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20,),
                          Text(
                            'Mega Power in mini size',
                            style: h4.copyWith(
                              color: AppColors.cardBlurtext,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20,),
                          CustomButton(text: 'Shop Now', onPressed: (){},width: 160,backgroundColor: AppColors.appColor2,)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              AudioPlayerCard(),
              SizedBox(height: 20,),
              CustomButton(width: 190,borderRadius: 5,text: 'Start Record', onPressed: () => Get.to(() => RecordView()),),
              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
}
