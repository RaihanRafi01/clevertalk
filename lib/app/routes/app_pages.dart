import 'package:get/get.dart';

import '../modules/audio/bindings/audio_binding.dart';
import '../modules/audio/views/audio_player_view.dart';
import '../modules/audio/views/audio_view.dart';
import '../modules/audio/views/convert_view.dart';
import '../modules/authentication/bindings/authentication_binding.dart';
import '../modules/authentication/views/authentication_view.dart';
import '../modules/authentication/views/forgot_password_view.dart';
import '../modules/authentication/views/reset_password_view.dart';
import '../modules/authentication/views/sign_up_view.dart';
import '../modules/authentication/views/splash_view.dart';
import '../modules/authentication/views/verify_o_t_p_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_splash_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/home/views/record_view.dart';
import '../modules/notification_subscription/bindings/notification_subscription_binding.dart';
import '../modules/notification_subscription/views/notification_subscription_view.dart';
import '../modules/notification_subscription/views/subscription_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/setting/bindings/setting_binding.dart';
import '../modules/setting/views/setting_view.dart';
import '../modules/text/bindings/text_binding.dart';
import '../modules/text/views/convert_to_text_view.dart';
import '../modules/text/views/text_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => DashboardView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTHENTICATION,
      page: () => const SplashView(),
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
