import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/svgIcon.dart';
import '../../../app/data/database_helper.dart';
import '../../../app/modules/audio/views/audio_player_view.dart';
import '../../../app/modules/text/views/convert_to_text_view.dart';
import '../home/customDeletePopUp.dart';
import '../home/customPopUp.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String filepath;
  final String subtitle;
  final String duration;
  final bool showPlayIcon;
  final int id;
  final VoidCallback onUpdate; // Callback to refresh the list

  const CustomListTile({
    Key? key,
    required this.title,
    required this.filepath,
    required this.subtitle,
    required this.duration,
    this.showPlayIcon = true, // Default to true
    required this.id,
    required this.onUpdate, // Accept the callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      minLeadingWidth: 0,
      leading: SvgIcon(
        height: 30,
        svgPath: showPlayIcon ? 'assets/images/audio/music_icon.svg' : 'assets/images/text/text_icon.svg',
        onTap: () {
          // Handle leading icon tap
        },
      ),
      title: Text(
        title,
        style: h4.copyWith(fontSize: 17),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              subtitle,
              style: h4.copyWith(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if(showPlayIcon)
          const SizedBox(width: 5),
          if(showPlayIcon) Icon(
            Icons.access_time,
            size: 10,
            color: AppColors.green,
          ),
          if(showPlayIcon) const SizedBox(width: 2),
          if(showPlayIcon) Text(
            duration,
            style: h4.copyWith(fontSize: 10, color: AppColors.green),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*if (showPlayIcon) // Conditional rendering for play_icon
              SvgIcon(
                height: 24,
                svgPath: 'assets/images/audio/play_icon.svg',
                onTap: () => navigateBasedOnTranscription(context, title, filepath), // Pass the file name
              ),
            if (showPlayIcon) const SizedBox(width: 10),*/ // Spacing only if play_icon exists
            SvgIcon(
              height: 24,
              svgPath: 'assets/images/audio/edit_icon.svg',
              onTap: () {
                TextEditingController controller = TextEditingController(text: title); // Pre-fill the controller with the file name

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return CustomPopup(
                      title: 'Edit',
                      controller: controller, // Pass the controller
                      onButtonPressed: () async {
                        String newFileName = controller.text.trim(); // Get the updated file name
                        if (newFileName.isNotEmpty) {
                          final dbHelper = DatabaseHelper();
                          await dbHelper.renameAudioFile(context, id, newFileName); // Update the file name in the database
                          Navigator.of(context).pop(); // Close the dialog
                          onUpdate(); // Refresh the list
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('File name cannot be empty!')),
                          );
                        }
                      },
                      hint1: 'Enter new file name', // Provide hint text
                      fieldName: 'Rename File', // Provide label text
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 10),
            SvgIcon(
              height: 24,
              svgPath: 'assets/images/audio/delete_icon.svg',
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false, // Prevents closing by tapping outside
                  builder: (BuildContext context) {
                    return CustomDeletePopup(
                      onButtonPressed1: () async {
                        // Delete
                        final dbHelper = DatabaseHelper();
                        await dbHelper.deleteAudioFile(context, id);
                        Navigator.of(context).pop();
                        onUpdate();
                      },
                      onButtonPressed2: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void navigateBasedOnTranscription(BuildContext context, String fileName, String filePath) async {
  final dbHelper = DatabaseHelper();
  final hasText = await dbHelper.hasTranscription(fileName);

  if (hasText) {
    Get.to(() => ConvertToTextView(fileName: fileName, filePath: filePath));
  } else {
    Get.to(() => AudioPlayerView(fileName: fileName, filepath: filePath));
  }
}

