import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../data/services/api_services.dart';

class SubscriptionController extends GetxController {
  var isYearly = true.obs;
  var packages = <Package>[].obs;
  var isLoading = true.obs;

  // Inject ApiService
  final ApiService apiService = Get.put(ApiService());

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

    // Clean and normalize package_price_euro
    String rawPrice = json['package_price_euro'] ?? '';
    // Replace malformed Euro symbols and normalize currency to €
    String cleanedPrice = rawPrice
        .replaceAll('â¬', '\u20AC') // Fix malformed Euro
        .replaceAll('\$', '\u20AC')   // Replace $ with € (if all prices should be in Euro)
        .replaceAll('/month', '')     // Normalize format
        .replaceAll(' / month', '')   // Handle both formats
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