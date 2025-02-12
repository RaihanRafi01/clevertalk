import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/audio/bindings/audio_binding.dart';
import '../modules/audio/views/audio_view.dart';
import '../modules/authentication/bindings/authentication_binding.dart';
import '../modules/authentication/views/authentication_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/notification_subscription/bindings/notification_subscription_binding.dart';
import '../modules/notification_subscription/views/notification_subscription_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/setting/bindings/setting_binding.dart';
import '../modules/setting/views/setting_view.dart';
import '../modules/text/bindings/text_binding.dart';
import '../modules/text/views/text_view.dart';
part 'app_routes.dart';

class AppPages {
  AppPages._();

  static Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn ? _Paths.HOME : _Paths.AUTHENTICATION;
  }

  static final routes = [
    // If the user is logged in, navigate to HOME; else, to the AUTHENTICATION screen
    GetPage(
      name: _Paths.HOME,
      page: () => DashboardView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTHENTICATION,
      page: () => AuthenticationView(),
      binding: AuthenticationBinding(),
    ),
    GetPage(
      name: _Paths.AUDIO,
      page: () => const AudioView(),
      binding: AudioBinding(),
    ),
    GetPage(
      name: _Paths.TEXT,
      page: () => const TextView(),
      binding: TextBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.SETTING,
      page: () => const SettingView(),
      binding: SettingBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATION_SUBSCRIPTION,
      page: () => const NotificationSubscriptionView(),
      binding: NotificationSubscriptionBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
  ];
}
