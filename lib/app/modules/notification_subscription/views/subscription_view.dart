import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';

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
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildExactPricingCard(
            title: "BASIC",
            price: controller.isYearly.value ? "\$7.99" : "\$14.99",
            billedAnnually: controller.isYearly.value,
            savingsPercentage: controller.isYearly.value ? 46 : null,
            minutes: 1500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildExactPricingCard(
            title: "PREMIUM",
            price: controller.isYearly.value ? "\$12.99" : "\$24.99",
            billedAnnually: controller.isYearly.value,
            savingsPercentage: controller.isYearly.value ? 48 : null,
            minutes: 3000,
          ),
        ),
      ],
    ));
  }

  Widget _buildExactPricingCard({
    required String title,
    required String price,
    required bool billedAnnually,
    int? savingsPercentage,
    required int minutes,
  }) {
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
                      style: h1.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    Text(
                      " per month",
                      style: h1.copyWith(fontSize: 12),
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
                Text(
                  "$minutes transcription\nminutes/month",
                  textAlign: TextAlign.center,
                  style: h1.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                  text: 'Buy Now',
                  onPressed: () {
                    print("Buy ${title.toLowerCase()} Plan");
                  }),
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

class SubscriptionController extends GetxController {
  var isYearly = true.obs;

  void setYearly(bool value) {
    isYearly.value = value;
  }
}