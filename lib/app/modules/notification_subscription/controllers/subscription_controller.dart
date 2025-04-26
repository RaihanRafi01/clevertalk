import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../data/services/api_services.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../home/controllers/home_controller.dart';
import '../views/subscription_view.dart';
import '../views/webViewScreen.dart';

class SubscriptionController extends GetxController {
  var isYearly = true.obs;
  var packages = <Package>[].obs;
  var isLoading = true.obs;

  final ApiService apiService = Get.put(ApiService());
  final HomeController homeController = Get.find<HomeController>();

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
  }

  void setYearly(bool value) {
    isYearly.value = value;
  }

  List<Package> getFilteredPackages() {
    return packages.where((p) => p.packageType == (isYearly.value ? 'Yearly' : 'Monthly')).toList();
  }

  Future<void> fetchPackages() async {
    try {
      isLoading.value = true;
      final response = await apiService.getAllPackageInformation();

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        packages.assignAll(data.map((json) => Package.fromJson(json)).toList());
      } else {
        Get.snackbar('Error', 'Failed to fetch packages: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buySubscription({
    required String priceId,
    required String packageName,
    required String packageType,
  }) async {
    try {
      final response = await apiService.buySubscription(
        priceId: priceId,
        packageName: packageName,
        packageType: packageType,
      );

      print('buySubscription CODE : ${response.statusCode}');
      print('buySubscription body : ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final checkoutUrl = responseBody['checkout_url'];
        final message = responseBody['Message'];
        if (message != null && message.isNotEmpty) {
          Get.snackbar('Message', message);
        } else if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          print(':::::::::checkout_url:::::::::::::::::::::::::::::$checkoutUrl');
          Get.off(() => WebViewScreen(
            url: checkoutUrl,
            onUrlMatched: () {
              homeController.package_name.value = packageName;
              homeController.package_type.value = packageType;
              Get.snackbar('Success', 'Subscription purchased successfully');
              Get.offAll(() => DashboardView());
            },
          ));
        } else {
          Get.snackbar('Error', 'Unexpected response. Please try again.');
        }
      } else {
        Get.snackbar('Error', 'Failed to purchase subscription: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final response = await apiService.cancelSubscription();

      if (response.statusCode == 200) {
        homeController.package_name.value = '';
        homeController.package_type.value = '';
        Get.snackbar('Success', 'Subscription canceled successfully');
        Get.off(() => SubscriptionView());
      } else {
        Get.snackbar('Error', 'Failed to cancel subscription: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }

  // New method to check if the user is trying to select the same plan
  bool isSamePlan(String packageName, String packageType) {
    return homeController.package_name.value.toLowerCase() == packageName.toLowerCase() &&
        homeController.package_type.value.toLowerCase() == packageType.toLowerCase();
  }

  // New method to determine allowed actions based on current plan
  Map<String, bool> getAllowedActions() {
    final currentPlan = homeController.package_name.value.toLowerCase();
    final currentType = homeController.package_type.value.toLowerCase();

    if (currentPlan == 'basic' && currentType == 'monthly') {
      return {'upgrade': true, 'downgrade': false};
    } else if (currentPlan == 'premium' && currentType == 'yearly') {
      return {'upgrade': false, 'downgrade': true};
    } else {
      return {'upgrade': true, 'downgrade': true};
    }
  }

  // New method to upgrade subscription
  Future<void> upgradeSubscription({
    required String priceId,
    required String packageName,
    required String packageType,
  }) async {
    if (isSamePlan(packageName, packageType)) {
      Get.snackbar('Info', 'You are already on this plan.');
      return;
    }

    try {
      final response = await apiService.upgradeSubscription(
        priceId: priceId,
        packageName: packageName,
        packageType: packageType,
      );
      print(':::::::::upgradeSubscription priceId  : $priceId');
      print(':::::::::upgradeSubscription CODE : ${response.statusCode}');
      print(':::::::::upgradeSubscription body : ${response.body}');

      if (response.statusCode == 200) {
        homeController.package_name.value = packageName;
        homeController.package_type.value = packageType;
        Get.snackbar('Success', 'Subscription upgraded successfully');
      } else {
        Get.snackbar('Error', 'Failed to upgrade subscription: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }

  // New method to downgrade subscription
  Future<void> downgradeSubscription({
    required String priceId,
    required String packageName,
    required String packageType,
  }) async {
    if (isSamePlan(packageName, packageType)) {
      Get.snackbar('Info', 'You are already on this plan.');
      return;
    }

    try {
      final response = await apiService.downgradeSubscription(
        priceId: priceId,
        packageName: packageName,
        packageType: packageType,
      );

      print(':::::::::downgradeSubscription priceId  : $priceId');
      print(':::::::::downgradeSubscription CODE : ${response.statusCode}');
      print(':::::::::downgradeSubscription body : ${response.body}');

      if (response.statusCode == 200) {
        homeController.package_name.value = packageName;
        homeController.package_type.value = packageType;
        Get.snackbar('Success', 'Subscription downgraded successfully');
      } else {
        Get.snackbar('Error', 'Failed to downgrade subscription: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }
}

class PackageDescription {
  final String description;

  PackageDescription({required this.description});

  factory PackageDescription.fromJson(Map<String, dynamic> json) {
    return PackageDescription(description: json['description']);
  }
}

class Package {
  final int id;
  final String packageName;
  final String packageType;
  final String? packagePriceUsd;
  final String? priceIdUsd;
  final String packagePriceEuro;
  final String priceIdEuro;
  final List<PackageDescription> descriptions;

  Package({
    required this.id,
    required this.packageName,
    required this.packageType,
    this.packagePriceUsd,
    this.priceIdUsd,
    required this.packagePriceEuro,
    required this.priceIdEuro,
    required this.descriptions,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    var descriptionsList = json['descriptions'] as List;
    List<PackageDescription> descriptions =
    descriptionsList.map((desc) => PackageDescription.fromJson(desc)).toList();

    String rawPrice = json['package_price_euro'] ?? '';
    String cleanedPrice = rawPrice
        .replaceAll('â¬', '\u20AC')
        .replaceAll('\$', '\u20AC')
        .replaceAll('/month', '')
        .replaceAll(' / month', '')
        .trim();

    return Package(
      id: json['id'],
      packageName: json['package_name'],
      packageType: json['package_type'],
      packagePriceUsd: json['package_price_usd'],
      priceIdUsd: json['price_id_usd'],
      packagePriceEuro: cleanedPrice,
      priceIdEuro: json['price_id_euro'],
      descriptions: descriptions,
    );
  }
}