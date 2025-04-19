import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/audio_text/customListTile.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../controllers/text_controller.dart';
import 'convert_to_text_view.dart';

class TextView extends StatelessWidget {
  const TextView({super.key});


  @override
  Widget build(BuildContext context) {
    final TextViewController controller = Get.put(TextViewController());
    return Scaffold(
      appBar: CustomAppBar(
        isSearch: true,
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
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
                child: Text('Recordings', style: h1.copyWith(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                if (controller.textFiles.isEmpty) {
                  return Center(
                    child: Text(
                      'No text files available',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                } else {
                  return ListView.separated(
                    itemCount: controller.textFiles.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final textFile = controller.textFiles[index];
                      final fileName = textFile['file_name'] ?? 'Unknown Title';
                      final parsedDate = textFile['parsed_date'] ?? 'Unknown Date';
                      final filePath = textFile['file_path'];
                      final id = textFile['id']; // Add ID

                      return GestureDetector(
                        onTap: () {
                          print(':::::::::::::::::::::::::id: $id');
                          Get.to(() => ConvertToTextView(fileName: fileName, filePath: filePath,));
                        },
                        child: CustomListTile(
                          filepath: filePath,
                          title: fileName,
                          subtitle: parsedDate,
                          duration: textFile['duration'] ?? '00:00:00',
                          showPlayIcon: false,
                          id: id,
                          onUpdate: controller.fetchTextFiles, // Pass the refresh callback
                        ),
                      );
                    },
                  );
                }
              }),
            ),
            const SizedBox(height: 58),
          ],
        ),
      ),
    );
  }
}