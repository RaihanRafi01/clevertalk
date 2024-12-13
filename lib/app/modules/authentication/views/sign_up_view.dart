import 'package:clevertalk/app/modules/authentication/views/authentication_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_HeaderText.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:clevertalk/common/widgets/auth/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/auth/terms_and_conditions_checkbox.dart';
import '../../home/views/home_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool _isChecked = false;

  // Handle checkbox change
  void _onCheckboxChanged(bool isChecked) {
    setState(() {
      _isChecked = isChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignUpView'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeadertext(
                header1: "Create an account",
                header2: "Sign up now to get started on your journey.",
              ),
              SizedBox(height: 30,),
              CustomTextField(
                label: 'User Name',
                hint: 'Enter Name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              CustomTextField(
                label: 'Your email',
                hint: 'Enter Email',
                prefixIcon: Icons.email_outlined,
              ),
              CustomTextField(
                label: 'Password',
                hint: 'Enter Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
          
              // Replaced Row with the new TermsAndConditionsCheckbox widget
              TermsAndConditionsCheckbox(
                onCheckboxChanged: _onCheckboxChanged,
              ),
          
              SizedBox(height: 20,),
          
              // Sign Up button is only enabled if the checkbox is checked
              CustomButton(
                text: "Sign Up ",
                onPressed: _isChecked ? () => Get.off(() => HomeView()) : () {},
              ),
          
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already Have an Account?"),
                  TextButton(
                    onPressed: () => Get.to(() => AuthenticationView()),
                    child: const Text("Log In"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
