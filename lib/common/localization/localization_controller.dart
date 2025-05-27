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

  static const Map<String, String> languageMap = {
    'en': 'English',
    'de': 'German',
    'ru': 'Russian',
    'fr': 'French',
    'es': 'Spanish',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Chinese',
    'hi': 'Hindi',
    'ar': 'Arabic',
    'ja': 'Japanese',
  };

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
      case 'German':
        locale = const Locale('de', 'DE');
        break;
      case 'Russian':
        locale = const Locale('ru', 'RU');
        break;
      case 'French':
        locale = const Locale('fr', 'FR');
        break;
      case 'Spanish':
        locale = const Locale('es', 'ES');
        break;
      case 'Italian':
        locale = const Locale('it', 'IT');
        break;
      case 'Portuguese':
        locale = const Locale('pt', 'PT');
        break;
      case 'Chinese':
        locale = const Locale('zh', 'CN');
        break;
      case 'Hindi':
        locale = const Locale('hi', 'IN');
        break;
      case 'Arabic':
        locale = const Locale('ar', 'AR');
        break;
      case 'Japanese':
        locale = const Locale('ja', 'JP');
        break;
      default:
        locale = const Locale('en', 'US');
    }
    Get.updateLocale(locale);
  }

  // Get current locale
  Locale getCurrentLocale() {
    switch (selectedLanguage.value) {
      case 'German':
        return const Locale('de', 'DE');
      case 'Russian':
        return const Locale('ru', 'RU');
      case 'French':
        return const Locale('fr', 'FR');
      case 'Spanish':
        return const Locale('es', 'ES');
      case 'Italian':
        return const Locale('it', 'IT');
      case 'Portuguese':
        return const Locale('pt', 'PT');
      case 'Chinese':
        return const Locale('zh', 'CN');
      case 'Hindi':
        return const Locale('hi', 'IN');
      case 'Arabic':
        return const Locale('ar', 'AR');
      case 'Japanese':
        return const Locale('ja', 'JP');
      default:
        return const Locale('en', 'US');
    }
  }
}