import 'package:clevertalk/app/modules/authentication/views/forgot_password_view.dart';
import 'package:clevertalk/app/modules/authentication/views/sign_up_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'social_button.dart';
class SignupWithOther extends StatelessWidget {
  const SignupWithOther({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't Have An Account?"),
          TextButton(
            onPressed: () => Get.to(()=> SignUpView()),
            child: const Text("Sign Up"),
          ),

        ],
      ),

      const SizedBox(height: 10),
      SvgPicture.asset('assets/images/auth/orLoginWith.svg'),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SocialButton(
            iconPath: 'assets/images/auth/apple_icon.svg',
            onPressed: () {
              // Call Google sign-in function
            },
          ),
          SizedBox(width: 30),
          SocialButton(
            iconPath: 'assets/images/auth/google_icon.svg',
            onPressed: () {
              // Call Google sign-in function
            },
          ),
          SizedBox(width: 30),
          SocialButton(
            iconPath: 'assets/images/auth/facebook_icon.svg',
            onPressed: () {
              // Call Google sign-in function
            },
          ),
        ],
      ),


    ],);
  }
}
