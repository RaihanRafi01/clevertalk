import 'package:clevertalk/app/modules/authentication/views/forgot_password_view.dart';
import 'package:clevertalk/app/modules/home/views/home_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:clevertalk/common/widgets/auth/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/auth/custom_HeaderText.dart';
import '../../../../common/widgets/auth/signupWithOther.dart';
import '../controllers/authentication_controller.dart';

class AuthenticationView extends GetView<AuthenticationController> {
  const AuthenticationView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(

            children: [
              SizedBox(height: 100,),
              Align(alignment: Alignment.center, child: SvgPicture.asset('assets/images/auth/logo.svg')),
              SizedBox(height: 50,),
              CustomHeadertext(header1: "Login to your account",header2: "welcome back! we’ve missed you.",),
              SizedBox(height: 30),
              CustomTextField(label: "Your Email",hint: "Enter Email",prefixIcon: Icons.email_outlined,),
              CustomTextField(label: "Password",hint: "Enter Password",prefixIcon: Icons.lock_outline_rounded,isPassword: true,),
              GestureDetector(
                onTap: ()=> Get.to(()=> ForgotPasswordView()),
                  child: Align(alignment: Alignment.centerRight,child: Text('Forgot Password?',style: TextStyle(color: Colors.red),))),
              SizedBox(height: 30,),
              CustomButton(text: "Login",onPressed: (){
                Get.off(()=> HomeView());
              }),
              SignupWithOther()
            ],
          ),
        ),
      ),
    );
  }
}
