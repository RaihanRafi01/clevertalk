import 'package:clevertalk/app/modules/notification_subscription/views/subscription_view.dart';
import 'package:clevertalk/app/modules/notification_subscription/views/subscribed_view.dart';
import 'package:clevertalk/app/modules/setting/views/help_support_web_view.dart';
import 'package:clevertalk/app/modules/setting/views/terms_privacy_view.dart';
import 'package:clevertalk/common/localization/localization_controller.dart';
import 'package:clevertalk/common/widgets/settings/settingsList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../../common/widgets/home/customDeletePopUp.dart';
import '../../authentication/views/authentication_view.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/setting_controller.dart';
import 'customReferPopup.dart';
import 'help_support_view.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SettingController());
    final HomeController homeController = Get.find<HomeController>();
    final LocalizationController localizationController = Get.find<LocalizationController>();

    final FlutterSecureStorage _storage = FlutterSecureStorage();
    Future<void> logout() async {
      await FlutterSecureStorage().deleteAll();
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      Get.offAll(() => AuthenticationView());
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          print("Second icon pressed");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('settings'.tr, style: h1.copyWith(fontSize: 24)),
              SizedBox(height: 30),
              Text('account'.tr, style: h1.copyWith(fontSize: 16)),
              SizedBox(height: 10),
              SettingsList(
                svgPath: 'assets/images/settings/subscription_icon.svg',
                text: 'manage_subscription'.tr,
                onTap: () {
                  if (homeController.package_name.value != 'Free Trial') {
                    Get.to(() => SubscribedView());
                  } else {
                    Get.to(() => SubscriptionView());
                  }
                },
              ),
              SettingsList(
                  svgPath: 'assets/images/settings/delete_icon.svg',
                  text: 'delete_account'.tr,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return CustomDeletePopup(
                          title: 'delete_account_confirm'.tr,
                          onButtonPressed1: () {
                            // Delete
                          },
                          onButtonPressed2: () {
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  }),
              SettingsList(
                  svgPath: 'assets/images/settings/terms_icon.svg',
                  text: 'terms_and_condition'.tr,
                  onTap: () => Get.to(() => TermsPrivacyView(isTerms: true))),
              SettingsList(
                  svgPath: 'assets/images/settings/privacy_icon.svg',
                  text: 'privacy_policy'.tr,
                  onTap: () => Get.to(() => TermsPrivacyView(isTerms: false))),
              SettingsList(
                svgPath: 'assets/images/settings/refer_icon.svg',
                text: 'refer_a_friend'.tr,
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return CustomReferPopup(
                        onSendPressed: () {
                          print('Send referral button pressed');
                        },
                      );
                    },
                  );
                },
              ),
              Text('help'.tr, style: h1.copyWith(fontSize: 16)),
              SizedBox(height: 10),
              SettingsList(
                  svgPath: 'assets/images/settings/email_icon.svg',
                  text: 'email_support'.tr,
                  onTap: () => Get.to(() => HelpSupportWebViewScreen())),
              Text('notification'.tr, style: h1.copyWith(fontSize: 16)),
              SizedBox(height: 10),
              Obx(() {
                return SettingsList(
                  svgPath: 'assets/images/settings/notification_icon.svg',
                  text: 'writing_reminder'.tr,
                  isTogol: true,
                  isToggled: controller.isWritingReminderOn.value,
                  onToggleChanged: (value) {
                    controller.toggleWritingReminder(value);
                    if (value) {
                      print('yes');
                    } else {
                      print('no');
                    }
                  },
                  onTap: () {},
                );
              }),
              Text('language'.tr, style: h1.copyWith(fontSize: 16)),
              SizedBox(height: 10),
              Obx(() {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: localizationController.selectedLanguage.value,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        localizationController.changeLanguage(newValue);
                        print('Language changed to: $newValue');
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'English',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'English',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'German',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'German',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Russian',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Russian',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'French',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'French',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Spanish',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Spanish',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Italian',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Italian',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Portuguese',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Portuguese',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Chinese',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Chinese',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Hindi',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Hindi',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Arabic',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Arabic',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Japanese',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Japanese',
                            style: h4.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    underline: const SizedBox(),
                  ),
                );
              }),
              SizedBox(height: 20),
              GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            title: Text('log_out'.tr, style: h2),
                            content: Text('log_out_confirm'.tr, style: h3),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('cancel'.tr, style: h2.copyWith(
                                    color: AppColors.appColor)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  logout();
                                },
                                child: Text('log_out'.tr,
                                    style: h2.copyWith(color: Colors.red)),
                              ),
                            ],
                          ),
                    );
                  },
                  child: SvgPicture.asset(
                      'assets/images/auth/logout_logo.svg')),
              SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}