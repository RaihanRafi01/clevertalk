import 'package:clevertalk/app/modules/text/views/convert_to_text_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../common/widgets/audio_text/customListTile.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../audio/views/summary_key_point_view.dart';

class TextView extends StatelessWidget {
  const TextView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isSearch: true,
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          // Action for the first button
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          // Action for the second button
          print("Second icon pressed");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Text', style: h1.copyWith(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: 15, // Static count for now
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.grey,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  // Example usage with conditional `showPlayIcon`
                  return GestureDetector(
                    onTap: () => Get.to(() => ConvertToTextView()),
                    child: CustomListTile(
                      title: 'Customer Feedback',
                      subtitle: '11/20/24 8:00 PM',
                      duration: '00:09:00',
                      showPlayIcon: false,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 58,)
          ],
        ),
      ),
    );
  }
}
