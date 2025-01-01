import 'package:clevertalk/app/modules/authentication/views/authentication_view.dart';
import 'package:clevertalk/app/modules/dashboard/views/dashboard_view.dart';
import 'package:clevertalk/common/widgets/auth/custom_HeaderText.dart';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:clevertalk/common/widgets/auth/custom_textField.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/auth/terms_and_conditions_checkbox.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/views/home_view.dart';
import '../controllers/authentication_controller.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final AuthenticationController _controller = Get.put(AuthenticationController());
  final HomeController homeController = Get.put(HomeController());
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isChecked = false;
    // Handle checkbox change
  void _onCheckboxChanged(bool isChecked) {
    setState(() {
      _isChecked = isChecked;
    });
  }

  void _handleSignUp() {
    if (_usernameController.text
        .trim()
        .isEmpty ||
        _emailController.text
            .trim()
            .isEmpty ||
        _passwordController.text
            .trim()
            .isEmpty ||
        _confirmPasswordController.text
            .trim()
            .isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Get.snackbar('Error', 'Passwords do not match');
      return;
    }

    homeController.usernameOBS.value = _usernameController.text.trim();

   print(':::::::::::::usernameOBS:::::::::::::::::${homeController.usernameOBS.value}');

    // Proceed with sign-up logic if validations pass
    _controller.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _usernameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30,),
              CustomHeadertext(
                header1: "Create an account",
                header2: "Sign up now to get started on your journey.",
              ),
              SizedBox(height: 30,),
              CustomTextField(
                label: 'User Name',
                hint: 'Enter Name',
                prefixIcon: Icons.person_outline_rounded,
                controller: _usernameController,
              ),
              CustomTextField(
                label: 'Your email',
                hint: 'Enter Email',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
              ),
              CustomTextField(
                label: 'Password',
                hint: 'Enter Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                controller: _passwordController,
              ),
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                controller: _confirmPasswordController,
              ),
          
              // Replaced Row with the new TermsAndConditionsCheckbox widget
              TermsAndConditionsCheckbox(
                onCheckboxChanged: _onCheckboxChanged,
              ),
          
              SizedBox(height: 20,),
          
              // Sign Up button is only enabled if the checkbox is checked
              CustomButton(
                text: "Sign Up",
                onPressed: _isChecked
                    ? () {
                  _handleSignUp();
                }
                    : () {
                  Get.snackbar(
                    'Error',
                    'Please accept Terms & Conditions & Privacy Policy',
                  );
                },
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
        // Loading Indicator
        Obx(() {
          return _controller.isLoading.value
              ? Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.appColor,),
            ),
          )
              : const SizedBox.shrink();
        }),
        ],
      ),
    );
  }
}
