import 'package:get/get.dart';

class SettingController extends GetxController {
  var isWritingReminderOn = false.obs;
  var selectedLanguage = 'English'.obs;

  // Toggle method for the Writing Reminder
  void toggleWritingReminder(bool value) {
    isWritingReminderOn.value = value;
  }

  // Change the language
  void changeLanguage(String newLanguage) {
    selectedLanguage.value = newLanguage;
  }
}
