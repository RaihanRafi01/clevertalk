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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 15),
        child: isTerms? Text(style: h3.copyWith(height: 2,fontSize: 14),
          'Welcome. By using our services, you agree to abide by the terms and conditions outlined below. These terms govern your access to and use of  tools and services, so please review them carefully before proceeding. provides innovative tools designed to enhance how you capture and manage voice recordings. Our services include voice-to-text transcription and AI-driven summarization, which are intended for lawful, ethical purposes only. You must ensure compliance with applicable laws, including obtaining consent from all participants when recording conversations. CleverTalk disclaims liability for any misuse of its tools.',
        ) : 
        Text(style: h3.copyWith(height: 2,fontSize: 14) ,
            'Welcome. By using our services, you agree to abide by the terms and conditions outlined below. These terms govern your access to and use of  tools and services, so please review them carefully before proceeding. provides innovative tools designed to enhance how you capture and manage voice recordings. Our services include voice-to-text transcription and AI-driven summarization, which are intended for lawful, ethical purposes only. You must ensure compliance with applicable laws, including obtaining consent from all participants when recording conversations. CleverTalk disclaims liability for any misuse of its tools.'),
      ),
    );
  }
}
