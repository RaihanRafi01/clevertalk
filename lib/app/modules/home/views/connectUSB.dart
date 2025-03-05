import 'dart:async';
import 'dart:io';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../common/appColors.dart';
import '../../../data/database_helper.dart';
import '../../audio/controllers/audio_controller.dart';

// Dialog State Controller using GetX
class DialogStateController extends GetxController {
  var title = ''.obs;
  var message = ''.obs;
  var icon = Rxn<IconData>();
  var iconColor = Rxn<Color>();
  var progress = Rxn<double>();
  var isLoading = false.obs;
  var showContinue = false.obs;
  var showTryAgain = false.obs;

  void updateDialog({
    String? title,
    String? message,
    IconData? icon,
    Color? iconColor,
    double? progress,
    bool? isLoading,
    bool? showContinue,
    bool? showTryAgain,
  }) {
    if (title != null) this.title.value = title;
    if (message != null) this.message.value = message;
    this.icon.value = icon;
    this.iconColor.value = iconColor;
    this.progress.value = progress;
    if (isLoading != null) this.isLoading.value = isLoading;
    if (showContinue != null) this.showContinue.value = showContinue;
    if (showTryAgain != null) this.showTryAgain.value = showTryAgain;
  }
}

Future<void> connectUsbDevice(BuildContext context) async {
  const platform = MethodChannel('usb_path_reader/usb');
  final dbHelper = DatabaseHelper();
  String selectedPath = '/RECORD';
  String? usbPath;
  String? usbDeviceUUID;
  String? usbProductId;
  String? usbVendorId;
  String? usbDeviceName;
  bool isUsbConnected = false;

  int retryCount = 0;
  const maxRetries = 3;

  // Initialize and show persistent dialog
  final dialogController = _showPersistentDialog(context);

  Future<void> tryConnect() async {
    retryCount = 0;
    isUsbConnected = false;

    dialogController.updateDialog(
      title: "Connecting",
      message: "Connecting to CleverTalk recorder...",
      isLoading: true,
      showTryAgain: false,
      showContinue: false,
    );

    while (retryCount < maxRetries) {
      try {
        if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }

        final Map<dynamic, dynamic>? usbDeviceDetails =
        await platform.invokeMethod('getUsbDeviceDetails');

        if (usbDeviceDetails != null) {
          usbPath = await platform.invokeMethod<String>('getUsbPath');
          usbDeviceName = usbDeviceDetails['deviceName'];
          usbVendorId = usbDeviceDetails['vendorId'];
          usbProductId = usbDeviceDetails['productId'];
          usbDeviceUUID = usbDeviceDetails['deviceUUID'];
          isUsbConnected = true;

          dialogController.updateDialog(
            title: "Success",
            message: "Successfully connected to the recorder\nPlease wait for file transfer from CleverTalk recorder",
            icon: Icons.check_circle,
            iconColor: AppColors.appColor,
            isLoading: true,
          );
          await Future.delayed(Duration(seconds: 2));
          break;
        } else {
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 15));
          }
        }
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 15));
        }
      }
    }

    if (!isUsbConnected || usbPath == null) {
      dialogController.updateDialog(
        title: "Error",
        message: "Failed to connect USB device after $maxRetries attempts",
        icon: Icons.error,
        iconColor: Colors.red.shade700,
        isLoading: false,
        showTryAgain: true,
      );
      return;
    }

    try {
      String combinedPath = '$usbPath$selectedPath';
      final directory = Directory(combinedPath);

      int retryCountStep3 = 0;
      const maxRetriesStep3 = 3;
      List<FileSystemEntity> files = [];

      while (retryCountStep3 < maxRetriesStep3) {
        try {
          if (!directory.existsSync()) {
            throw Exception('Directory does not exist!');
          }

          files = directory.listSync(recursive: true, followLinks: false);
          break;
        } catch (e) {
          retryCountStep3++;
          if (retryCountStep3 < maxRetriesStep3) {
            await Future.delayed(Duration(seconds: 15));
          } else {
            dialogController.updateDialog(
              title: "Error",
              message: "Failed to access directory after $maxRetriesStep3 attempts.",
              icon: Icons.error,
              iconColor: Colors.red.shade700,
              isLoading: false,
              showTryAgain: true,
            );
            return;
          }
        }
      }

    final audioFilesList = files.where((file) {
      final extension = file.path.split('.').last.toLowerCase();
      return ['mp3', 'wav', 'aac'].contains(extension);
    }).toList();

    final savedFiles = await dbHelper.fetchAudioFiles();
    final savedFileNames = savedFiles.map((file) => file['file_name'] as String).toSet();

    List<FileSystemEntity> newFiles = audioFilesList.where((file) {
      final fileName = file.path.split('/').last;
      return !savedFileNames.contains(fileName);
    }).toList();

      dialogController.updateDialog(
        title: "Transferring",
        message: "Please wait for file transfer from CleverTalk recorder\n\nFiles remaining: ${newFiles.length}",
        progress: 0.0,
        isLoading: true,
      );

    for (var i = 0; i < newFiles.length; i++) {
      final file = newFiles[i];
      final originalFilePath = file.path;
      final localFilePath = await _copyFileToLocal(originalFilePath);
      final duration = await _getAudioDuration(localFilePath);

      await dbHelper.insertAudioFile(
        false,
        context,
        localFilePath.split('/').last,
        localFilePath,
        duration,
        false,
        '',
      );

        final progress = (i + 1) / newFiles.length;
        dialogController.updateDialog(
          title: "Transferring",
          message: "Please wait for file transfer from CleverTalk recorder\n\nFiles remaining: ${newFiles.length - (i + 1)}",
          progress: progress,
          isLoading: true,
        );
      }

      dialogController.updateDialog(
        title: "Completed",
        message: "All files have been downloaded!\n${newFiles.length} files transferred successfully",
        icon: Icons.check_circle,
        iconColor: AppColors.appColor,
        isLoading: false,
        showContinue: true,
      );

      final AudioPlayerController audioController = Get.put(AudioPlayerController());
      audioController.fetchAudioFiles();

    } catch (e) {
      dialogController.updateDialog(
        title: "Error",
        message: "An error occurred: $e",
        icon: Icons.error,
        iconColor: Colors.red.shade700,
        isLoading: false,
        showTryAgain: true,
      );
    }
  }

  // Initial call to start the connection process
  await tryConnect();
}

Future<String> _copyFileToLocal(String filePath) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/${filePath.split('/').last}';
    final sourceFile = File(filePath);

    if (await sourceFile.exists()) {
      await sourceFile.copy(localPath);
      return localPath;
    } else {
      throw Exception('Source file does not exist!');
    }
  } catch (e) {
    throw Exception('Error copying file: $e');
  }
}

Future<String> _getAudioDuration(String filePath) async {
  final audioPlayer = AudioPlayer();

  try {
    await audioPlayer.setFilePath(filePath);
    final duration = await audioPlayer.duration;

    if (duration != null) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;

      if (hours > 0) {
        return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes}:${seconds.toString().padLeft(2, '0')}';
      }
    }
  } catch (e) {
    return '0:00';
  } finally {
    await audioPlayer.dispose();
  }

  return '0:00';
}

DialogStateController _showPersistentDialog(BuildContext context) {
  final controller = Get.put(DialogStateController());

  Get.dialog(
    WillPopScope(
      onWillPop: () async => false, // Prevents dialog dismissal on back button press
      child: Obx(() => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                controller.iconColor.value == Colors.red.shade700 ? Colors.red.shade100 :
                controller.iconColor.value == AppColors.appColor ? AppColors.appColor2 :
                Colors.blue.shade100,
                Colors.white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.icon.value != null) ...[
                Icon(
                  controller.icon.value,
                  color: controller.iconColor.value,
                  size: 48,
                ),
                SizedBox(height: 16),
              ],
              Text(
                controller.title.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: controller.iconColor.value ?? Colors.blue.shade900,
                ),
              ),
              SizedBox(height: 12),
              Text(
                controller.message.value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              if (controller.isLoading.value) ...[
                SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.appColor),
                ),
              ],
              if (controller.progress.value != null && !controller.showContinue.value && !controller.showTryAgain.value) ...[
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: controller.progress.value,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "${(controller.progress.value! * 100).toStringAsFixed(1)}% complete",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
              if (controller.showContinue.value) ...[
                SizedBox(height: 20),
                CustomButton(
                  borderRadius: 30,
                  width: 160,
                  text: 'Continue',
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
              if (controller.showTryAgain.value) ...[
                SizedBox(height: 20),
                CustomButton(
                  borderRadius: 30,
                  width: 160,
                  text: 'Try Again',
                  onPressed: () async {
                    controller.updateDialog(showTryAgain: false); // Reset try again state
                    Get.back();
                    await connectUsbDevice(context); // Restart the process within the same dialog
                  },
                ),
              ],
            ],
          ),
        ),
      )),
    ),
    barrierDismissible: false, // Prevents closing by tapping outside
  );

  return controller;
}