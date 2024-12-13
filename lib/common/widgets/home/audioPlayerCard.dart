import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../appColors.dart';
import '../../customFont.dart';
import '../svgIcon.dart';

class AudioPlayerCard extends StatelessWidget {
  const AudioPlayerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
          child: Row(
            children: [
              // Icon or Album Art Section
              SvgPicture.asset('assets/images/home/audio_card.svg'),
              // Info and Player Controls Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                      'Recent Record',
                      style: h4.copyWith(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'CLEVERTALK',
                      style: h1.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Slider and Controls Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: 0.5,
                          onChanged: (value) {},
                          activeColor: AppColors.appColor,
                          inactiveColor: Colors.grey,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center the buttons
                          children: [
                            SvgIcon(height: 16, svgPath: 'assets/images/audio/previous_icon.svg', onTap: () {  },),
                            SvgIcon(height: 16, svgPath: 'assets/images/audio/previous_10_icon.svg', onTap: () {  },),
                            SvgIcon(height: 30, svgPath: 'assets/images/audio/pause_icon.svg', onTap: () {  },),
                            SvgIcon(height: 16, svgPath: 'assets/images/audio/next_10_icon.svg', onTap: () {  },),
                            SvgIcon(height: 16, svgPath: 'assets/images/audio/next_icon.svg', onTap: () {  },),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


