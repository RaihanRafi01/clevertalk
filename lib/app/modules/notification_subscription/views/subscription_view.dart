import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/subscription_controller.dart';
import 'subscribed_view.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SubscriptionController());

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
      body: _SubscriptionContent(),
    );
  }
}

class _SubscriptionContent extends GetView<SubscriptionController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      if (controller.packages.isEmpty) {
        return Center(child: Text("no_packages_available".tr));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildBillingButtons(),
              const SizedBox(height: 20),
              _buildPricingCards(),
              const SizedBox(height: 20),
              _buildFeaturesList(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBillingButtons() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120, // Set a smaller fixed width for the button
              child: ElevatedButton(
                onPressed: () {
                  controller.setYearly(false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !controller.isYearly.value
                      ? AppColors.appColor
                      : Colors.white,
                  foregroundColor: !controller.isYearly.value
                      ? Colors.white
                      : AppColors.appColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.appColor),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 48), // Consistent height
                ),
                child: Text(
                  "monthly".tr,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120, // Same fixed width for the second button
              child: ElevatedButton(
                onPressed: () {
                  controller.setYearly(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isYearly.value
                      ? AppColors.appColor
                      : Colors.white,
                  foregroundColor: controller.isYearly.value
                      ? Colors.white
                      : AppColors.appColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.appColor),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 48), // Consistent height
                ),
                child: Text(
                  "yearly".tr,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildPricingCards() {
    return Obx(() {
      final packages = controller.getFilteredPackages();
      final basicPackage = packages
          .firstWhereOrNull((p) => p.packageName.toLowerCase() == 'basic');
      final premiumPackage = packages
          .firstWhereOrNull((p) => p.packageName.toLowerCase() == 'premium');

      return Row(
        children: [
          if (basicPackage != null)
            Expanded(
              child: _buildExactPricingCard(
                title: basicPackage.packageName.toUpperCase(),
                price: controller.currency.value == 'USD' &&
                        basicPackage.packagePriceUsd != null
                    ? basicPackage.packagePriceUsd!
                    : basicPackage.packagePriceEuro,
                priceId: controller.currency.value == 'USD' &&
                        basicPackage.priceIdUsd != null
                    ? basicPackage.priceIdUsd!
                    : basicPackage.priceIdEuro,
                packageName: basicPackage.packageName,
                packageType: basicPackage.packageType,
                billedAnnually: basicPackage.packageType == 'Yearly',
                savingsPercentage: basicPackage.packageType == 'Yearly'
                    ? _getSavingsPercentage(basicPackage)
                    : null,
                descriptions: basicPackage.descriptions
                    .map((d) => d.description)
                    .toList(),
              ),
            ),
          if (basicPackage != null && premiumPackage != null)
            const SizedBox(width: 16),
          if (premiumPackage != null)
            Expanded(
              child: _buildExactPricingCard(
                title: premiumPackage.packageName.toUpperCase(),
                price: controller.currency.value == 'USD' &&
                        premiumPackage.packagePriceUsd != null
                    ? premiumPackage.packagePriceUsd!
                    : premiumPackage.packagePriceEuro,
                priceId: controller.currency.value == 'USD' &&
                        premiumPackage.priceIdUsd != null
                    ? premiumPackage.priceIdUsd!
                    : premiumPackage.priceIdEuro,
                packageName: premiumPackage.packageName,
                packageType: premiumPackage.packageType,
                billedAnnually: premiumPackage.packageType == 'Yearly',
                savingsPercentage: premiumPackage.packageType == 'Yearly'
                    ? _getSavingsPercentage(premiumPackage)
                    : null,
                descriptions: premiumPackage.descriptions
                    .map((d) => d.description)
                    .toList(),
              ),
            ),
        ],
      );
    });
  }

  int? _getSavingsPercentage(Package package) {
    final description = package.descriptions
        .firstWhereOrNull((d) => d.description.contains('save'));
    if (description != null) {
      final match = RegExp(r'\d+').firstMatch(description.description);
      return match != null ? int.tryParse(match.group(0)!) : null;
    }
    return null;
  }

  String determineAction(String packageName, String packageType) {
    final currentPlan =
        controller.homeController.package_name.value.toLowerCase();
    final currentType =
        controller.homeController.package_type.value.toLowerCase();
    final selectedPlan = packageName.toLowerCase();
    final selectedType = packageType.toLowerCase();

    if (currentPlan.isEmpty) {
      return 'buy';
    }

    final planValues = {
      'monthly_basic': 1,
      'monthly_premium': 3,
      'yearly_basic': 2,
      'yearly_premium': 4,
    };

    final currentKey = '${currentType}_${currentPlan}';
    final selectedKey = '${selectedType}_${selectedPlan}';

    final currentValue = planValues[currentKey] ?? 0;
    final selectedValue = planValues[selectedKey] ?? 0;

    if (selectedValue > currentValue) {
      return 'upgrade';
    } else if (selectedValue < currentValue) {
      return 'downgrade';
    } else {
      return 'same';
    }
  }

  Widget _buildExactPricingCard({
    required String title,
    required String price,
    required String priceId,
    required String packageName,
    required String packageType,
    required bool billedAnnually,
    int? savingsPercentage,
    required List<String> descriptions,
  }) {
    final action = determineAction(packageName, packageType);
    final isSamePlan = action == 'same';
    final isUnsubscribed = action == 'buy';
    final allowedActions = controller.getAllowedActions();
    final isActionAllowed = isUnsubscribed ||
        (action == 'upgrade' && allowedActions['upgrade']!) ||
        (action == 'downgrade' && allowedActions['downgrade']!);

    String buttonText;
    if (isUnsubscribed) {
      buttonText = 'buy_now'.tr;
    } else if (isSamePlan) {
      buttonText = 'current_plan'.tr;
    } else {
      buttonText = action == 'upgrade' ? 'upgrade'.tr : 'downgrade'.tr;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(
                  title,
                  style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    // Minimize row size to keep content tight
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          "per_month".tr,
                          style: h1.copyWith(fontSize: 10),
                          softWrap: false, // Prevent text from wrapping
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (billedAnnually)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "billed_annually".tr,
                            style: h4.copyWith(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (savingsPercentage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              '${"save_percentage:".tr} ${savingsPercentage.toString()}%', // Localized dynamic text
                              style: h2.copyWith(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ...descriptions
                    .where((desc) =>
                        !desc.contains('save') &&
                        !desc.contains('fas fa-tachometer-alt'))
                    .map((desc) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            desc,
                            textAlign: TextAlign.center,
                            style: h1.copyWith(fontSize: 11),
                          ),
                        )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: buttonText,
                onPressed: isSamePlan || !isActionAllowed
                    ? null
                    : () async {
                        print("Action: $action ${title.toLowerCase()} Plan");
                        String successMessage;
                        if (action == 'buy') {
                          controller.buySubscription(
                            priceId: priceId,
                            packageName: packageName,
                            packageType: packageType,
                          );
                          successMessage = "${'success_purchased'.tr} $title";
                        } else if (action == 'upgrade') {
                          controller.upgradeSubscription(
                            priceId: priceId,
                            packageName: packageName,
                            packageType: packageType,
                          );
                          successMessage = "${'success_upgraded'.tr} $title";
                        } else {
                          controller.downgradeSubscription(
                            priceId: priceId,
                            packageName: packageName,
                            packageType: packageType,
                          );
                          successMessage = "${'success_downgraded'.tr} $title";
                        }
                        Get.snackbar('success'.tr, successMessage);
                        controller.getAllowedActions();
                        final HomeController homeController =
                            Get.find<HomeController>();
                        await homeController.fetchProfileData();
                      },
                isDisabled: isSamePlan || !isActionAllowed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      "feature_unlimited_recording".tr, // Localized feature
      "feature_transcripts".tr, // Localized feature
      "feature_transcription_languages".tr, // Localized feature
      "feature_translation_languages".tr, // Localized feature
      "feature_speaker_identification".tr, // Localized feature
      "feature_summaries".tr, // Localized feature
      "feature_photo_notes".tr, // Localized feature
      "feature_download_reports".tr, // Localized feature
      "feature_share_results".tr, // Localized feature
    ];

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "both_plans_include".tr,
            style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(feature, style: h2.copyWith(fontSize: 12)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
