import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../common/customFont.dart';

class TermsPrivacyView extends GetView {
  final bool isTerms;
  const TermsPrivacyView({required this.isTerms,super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: isTerms? const Text('Terms & Condition') : const Text('Privacy policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          child: isTerms
              ? Text(
            '''
Terms of Service
Effective Date: May 1, 2025
Welcome to CleverTalk, operated by Duckdik S.L.L. ("we", "us", or "our"). By accessing or using the CleverTalk mobile application, website, or any services provided (collectively, the "Platform"), you agree to comply with and be bound by these Terms of Service ("Terms"). Please read them carefully before using our Platform. If you do not agree with these Terms, you may not use the Platform.
________________________________________
1. Subscription Plans and Pricing
1.1 Plan Options and Prices
●	Free Trial: Available to all new users.
●	Recorder Plan: Offers free monthly minutes for users who connect a registered CleverTalk Recorder regularly.
●	Paid Plans: Include Basic and Premium options with varying monthly minute allowances and pricing, available on both monthly and annual billing cycles.

1.2 Upgrades and Downgrades
●	Users may upgrade their subscription at any time. Additional minutes will be made available immediately, and the cost will be prorated based on a 30-day cycle.
●	Downgrades take effect at the next billing cycle.

1.3 Minute Policies
●	Minutes reset monthly and do not roll over.
●	Users on both a paid plan and the recorder plan may combine minutes from both sources.

1.4 Plan Management
●	Admins may adjust subscriptions, extend trials, add bonus minutes, or process exceptions as needed.
________________________________________
2. Account and Eligibility
2.1 You must provide accurate and complete information during account creation.
2.2 You are responsible for maintaining the security of your account.
2.3 If you are under 16 in the EU or under 13 in the US, you must have parental consent.
________________________________________
3. Subscription Cancellation and Refunds
3.1 Subscriptions may be canceled at any time and will remain active through the end of the billing cycle.
3.2 Unused minutes do not carry over and are forfeited at cancellation.
3.3 Refunds for yearly plans are not automatic but may be granted in exceptional cases at our discretion.
3.4 We reserve the right to refuse refund requests that are inconsistent with our stated policy or reflect misuse of the Platform.
________________________________________
4. Acceptable Use
You agree not to:
●	Use the service for illegal purposes.
●	Share your account credentials.
●	Attempt to reverse-engineer or tamper with the app.
●	Use CleverTalk to generate content that violates applicable laws or the rights of others.

We reserve the right to suspend or terminate access for conduct that we deem, in our sole discretion, harmful, abusive, fraudulent, or in violation of these Terms.
________________________________________

5. Intellectual Property
All content, branding, and technology on the Platform are the property of Duckdik S.L.L. or its licensors. You may not use, copy, modify, distribute, or reproduce any part of the Platform without prior written permission. Any unauthorized use constitutes a violation of these Terms and may result in legal action.
________________________________________
6. Communications
By registering, you agree to receive service emails and updates. You may unsubscribe from promotional emails at any time via the link provided. We are not responsible if our emails are filtered out by your email provider or software.
________________________________________
7. Third-Party Services
We are not responsible for content or services provided by third parties linked from our Platform. You acknowledge that third-party services may have their own terms and privacy policies, which you are responsible for reviewing.
________________________________________
8. Termination
We reserve the right to terminate or suspend your access to the Platform for violating these Terms. You may delete your account at any time. Upon termination, you must immediately cease using the Platform and delete all copies of any materials obtained through the Platform.
________________________________________
9. Limitation of Liability
To the fullest extent permitted by law, Duckdik S.L.L. shall not be liable for indirect, incidental, or consequential damages arising from your use of the Platform. Our total liability for any claim shall not exceed the amount paid by you, if any, for access to the Platform during the twelve-month period preceding the event giving rise to the claim.
________________________________________
10. Indemnification
You agree to indemnify and hold harmless Duckdik S.L.L., its officers, directors, employees, agents, and affiliates from any claims, damages, obligations, losses, or expenses (including attorney fees) arising out of: (i) your use of the Platform; (ii) your violation of any provision of these Terms; or (iii) your violation of any third-party rights, including intellectual property or privacy rights.
________________________________________
11. Governing Law
These Terms are governed by the laws of Spain. You agree to resolve any dispute with us exclusively in the courts located in Madrid.
________________________________________
12. Changes to These Terms
We may update these Terms at any time. Material changes will be communicated via email or in-app notification. Continued use of the Platform after updates constitutes acceptance. You are responsible for reviewing the Terms periodically.
________________________________________
13. Disclaimers
The Platform is provided "as is" and "as available" without warranties of any kind, whether express or implied. We do not guarantee that the service will be uninterrupted, error-free, secure, or meet your expectations. You use the Platform at your own risk.
________________________________________
Contact Us
If you have questions about these Terms, please contact us:
Email: info@clevertalk.ai
Address: Calle Azaleas, 5, 28440 Guadarrama, Madrid, Spain
            ''',
            style: TextStyle(
              fontSize: 14,
              height: 2,
              fontWeight: FontWeight.bold, // Assuming h3 implies bold
            ),
          )
              : Text(
            'Welcome. By using our services, you agree to abide by the terms and conditions outlined below. These terms govern your access to and use of tools and services, so please review them carefully before proceeding. CleverTalk provides innovative tools designed to enhance how you capture and manage voice recordings. Our services include voice-to-text transcription and AI-driven summarization, which are intended for lawful, ethical purposes only. You must ensure compliance with applicable laws, including obtaining consent from all participants when recording conversations. CleverTalk disclaims liability for any misuse of its tools.',
            style: TextStyle(
              fontSize: 14,
              height: 2,
              fontWeight: FontWeight.bold, // Assuming h3 implies bold
            ),
          ),
        ),
      )
    );
  }
}
