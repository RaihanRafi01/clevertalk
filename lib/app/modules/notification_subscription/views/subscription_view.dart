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
    final HomeController homeController = Get.find<HomeController>();

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
        return Center(child: Text("No packages available"));
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
        ElevatedButton(
          onPressed: () {
            controller.setYearly(false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: !controller.isYearly.value ? AppColors.appColor : Colors.white,
            foregroundColor: !controller.isYearly.value ? Colors.white : AppColors.appColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.appColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text("Monthly"),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            controller.setYearly(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.isYearly.value ? AppColors.appColor : Colors.white,
            foregroundColor: controller.isYearly.value ? Colors.white : AppColors.appColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.appColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text("Yearly"),
        ),
      ],
    ));
  }

  Widget _buildPricingCards() {
    return Obx(() {
      final packages = controller.getFilteredPackages();
      final basicPackage = packages.firstWhereOrNull((p) => p.packageName.toLowerCase() == 'basic');
      final premiumPackage = packages.firstWhereOrNull((p) => p.packageName.toLowerCase() == 'premium');

      return Row(
        children: [
          if (basicPackage != null)
            Expanded(
              child: _buildExactPricingCard(
                title: basicPackage.packageName.toUpperCase(),
                price: controller.currency.value == 'USD' && basicPackage.packagePriceUsd != null
                    ? basicPackage.packagePriceUsd!
                    : basicPackage.packagePriceEuro,
                priceId: controller.currency.value == 'USD' && basicPackage.priceIdUsd != null
                    ? basicPackage.priceIdUsd!
                    : basicPackage.priceIdEuro,
                packageName: basicPackage.packageName,
                packageType: basicPackage.packageType,
                billedAnnually: basicPackage.packageType == 'Yearly',
                savingsPercentage: basicPackage.packageType == 'Yearly' ? _getSavingsPercentage(basicPackage) : null,
                descriptions: basicPackage.descriptions.map((d) => d.description).toList(),
              ),
            ),
          if (basicPackage != null && premiumPackage != null) const SizedBox(width: 16),
          if (premiumPackage != null)
            Expanded(
              child: _buildExactPricingCard(
                title: premiumPackage.packageName.toUpperCase(),
                price: controller.currency.value == 'USD' && premiumPackage.packagePriceUsd != null
                    ? premiumPackage.packagePriceUsd!
                    : premiumPackage.packagePriceEuro,
                priceId: controller.currency.value == 'USD' && premiumPackage.priceIdUsd != null
                    ? premiumPackage.priceIdUsd!
                    : premiumPackage.priceIdEuro,
                packageName: premiumPackage.packageName,
                packageType: premiumPackage.packageType,
                billedAnnually: premiumPackage.packageType == 'Yearly',
                savingsPercentage: premiumPackage.packageType == 'Yearly' ? _getSavingsPercentage(premiumPackage) : null,
                descriptions: premiumPackage.descriptions.map((d) => d.description).toList(),
              ),
            ),
        ],
      );
    });
  }

  int? _getSavingsPercentage(Package package) {
    final description = package.descriptions.firstWhereOrNull((d) => d.description.contains('save'));
    if (description != null) {
      final match = RegExp(r'\d+').firstMatch(description.description);
      return match != null ? int.tryParse(match.group(0)!) : null;
    }
    return null;
  }

  String determineAction(String packageName, String packageType) {
    final currentPlan = controller.homeController.package_name.value.toLowerCase();
    final currentType = controller.homeController.package_type.value.toLowerCase();
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
      buttonText = 'Buy Now';
    } else if (isSamePlan) {
      buttonText = 'Current Plan';
    } else {
      buttonText = action == 'upgrade' ? 'Upgrade' : 'Downgrade';
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        " per month",
                        style: h1.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (billedAnnually)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Billed Annually",
                          style: h4.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (savingsPercentage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            "Save $savingsPercentage%",
                            style: h2.copyWith(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                ...descriptions
                    .where((desc) => !desc.contains('save') && !desc.contains('fas fa-tachometer-alt'))
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
                    : () {
                  print("Action: $action ${title.toLowerCase()} Plan");
                  if (action == 'buy') {
                    controller.buySubscription(
                      priceId: priceId,
                      packageName: packageName,
                      packageType: packageType,
                    );
                  } else if (action == 'upgrade') {
                    controller.upgradeSubscription(
                      priceId: priceId,
                      packageName: packageName,
                      packageType: packageType,
                    );
                  } else if (action == 'downgrade') {
                    controller.downgradeSubscription(
                      priceId: priceId,
                      packageName: packageName,
                      packageType: packageType,
                    );
                  }
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
      "Unlimited in-app recording",
      "Smart time-stamped transcripts with audio syncing",
      "Transcription supports more than 36 languages",
      "Translation to more than 60 languages",
      "Automatic speaker identification (diarization)",
      "Unlimited summaries and Clevertalk IA interaction",
      "Combine recordings with photo-based notes",
      "Download transcripts, summaries, and other reports",
      "Easily share results with colleagues or collaborators",
    ];

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Both plans include:",
            style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(feature, style: h2.copyWith(fontSize: 14)),
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