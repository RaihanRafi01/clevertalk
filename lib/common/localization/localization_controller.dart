import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationController extends GetxController {
  // Observable for selected language
  var selectedLanguage = 'English'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  // Load saved language from SharedPreferences
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? 'English';
    selectedLanguage.value = savedLanguage;
    _updateLocale(savedLanguage);
  }

  // Change language and update locale
  Future<void> changeLanguage(String language) async {
    selectedLanguage.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    _updateLocale(language);
  }

  // Update GetX locale based on selected language
  void _updateLocale(String language) {
    Locale locale;
    switch (language) {
      case 'Spanish':
        locale = const Locale('es', 'ES');
        break;
      case 'French':
        locale = const Locale('fr', 'FR');
        break;
      default:
        locale = const Locale('en', 'US');
    }
    Get.updateLocale(locale);
  }

  // Get current locale
  Locale getCurrentLocale() {
    switch (selectedLanguage.value) {
      case 'Spanish':
        return const Locale('es', 'ES');
      case 'French':
        return const Locale('fr', 'FR');
      default:
        return const Locale('en', 'US');
    }
  }
}