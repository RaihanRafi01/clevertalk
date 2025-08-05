import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../app/data/services/notification_services.dart';
import '../../../app/modules/authentication/controllers/authentication_controller.dart';
import '../../../app/modules/authentication/views/sign_up_view.dart';
import 'social_button.dart';

class SignupWithOther extends StatelessWidget {
  SignupWithOther({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Use singleton
  final AuthenticationController _controller = Get.put(AuthenticationController());
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't Have An Account?"),
            TextButton(
              onPressed: () => Get.to(() => SignUpView()),
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
                //_signInWithApple();
              },
            ),
            SizedBox(width: 30),
            SocialButton(
              iconPath: 'assets/images/auth/google_icon.svg',
              onPressed: _signInWithGoogle,
            ),
            /*SocialButton(
          iconPath: 'assets/images/auth/facebook_icon.svg',
          onPressed: () {
            // Call Google sign-in function
          },
        ),*/
          ],
        ),
      ],
    );
  }


  Future<void> _signInWithGoogle() async {
    try {
      String fcmToken = await _notificationService.getDeviceToken();
      print('FCM Token: $fcmToken');
      _controller.isLoading.value = true;
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {

        print(':::::::::::::::::::::::::::::::::::::::${user.email}');
        print(':::::::::::::::::::::::::::::::::::::::${user.displayName}');
        print(':::::::::::::::::::::::::::::::::::::::${user.uid}');

        await _controller.signUpWithOther(user.email!, fcmToken);

      }
    } catch (e) {
      print("Error signing in: $e");
    }finally {
      _controller.isLoading.value = false; // Hide the loading screen
    }

  }

  /*Future<void> _signInWithApple() async {
    try {
      _controller.isLoading.value = true;

      final AuthorizationCredentialAppleID result = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: result.identityToken,
        accessToken: result.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print(':::::::::::::::::::::::::::::::::::::::${user.email}');
        print(':::::::::::::::::::::::::::::::::::::::${user.displayName}');
        print(':::::::::::::::::::::::::::::::::::::::${user.uid}');

        await _controller.signUpWithOther(
          user.displayName!, // Fallback in case displayName is null
          user.email ?? result.email!, // Fallback in case email is null
        );
      }
    } catch (e) {
      print("Error signing in with Apple: $e");
    } finally {
      _controller.isLoading.value = false; // Hide the loading screen
    }
  }*/
}
