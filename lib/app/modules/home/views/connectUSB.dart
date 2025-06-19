import 'dart:async';
import 'dart:io';
import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/appColors.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/api_services.dart';
import '../../audio/controllers/audio_controller.dart';

class DialogStateController extends GetxController {
  var title = ''.obs;
  var message = ''.obs;
  var icon = Rxn<IconData>();
  var iconColor = Rxn<Color>();
  var progress = Rxn<double>();
  var isLoading = false.obs;
  var showContinue = false.obs;
  var showTryAgain = false.obs;
  var showRestart = false.obs;
  var isUsbAttached = false.obs;

  static const platform = MethodChannel('usb_path_reader/usb');

  @override
  void onInit() {
    super.onInit();
    _setupUsbListener();
  }

  void _setupUsbListener() {
    platform.invokeMethod('startUsbListener').then((_) {
      print('USB listener started successfully');
    }).catchError((e) {
      print('Error starting USB listener: $e');
    });
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUsbAttached':
          print('USB Attached received in Flutter: ${call.arguments}');
          isUsbAttached.value = true;
          updateDialog(
            title: 'usb_detected'.tr,
            message: 'usb_device_detected'.tr,
            icon: Icons.usb,
            iconColor: Colors.blue.shade700,
            isLoading: false,
            showTryAgain: false,
            showContinue: false,
          );
          await connectUsbDevice(Get.context!);
          break;
        case 'onUsbDetached':
          print('USB Detached received in Flutter');
          isUsbAttached.value = false;
          updateDialog(
            title: 'usb_disconnected'.tr,
            message: 'please_reconnect_usb_device'.tr,
            icon: Icons.usb_off,
            iconColor: Colors.red.shade700,
            isLoading: false,
            showContinue: false,
            showTryAgain: true,
          );
          break;
        case 'onUsbPermissionGranted':
          print('USB Permission granted for: ${call.arguments['deviceName']}');
          if (isUsbAttached.value) {
            await connectUsbDevice(Get.context!);
          }
          break;
      }
    });
  }

  void updateDialog({
    String? title,
    String? message,
    IconData? icon,
    Color? iconColor,
    double? progress,
    bool? isLoading,
    bool? showContinue,
    bool? showTryAgain,
    bool? showRestart,
  }) {
    if (title != null) this.title.value = title;
    if (message != null) this.message.value = message;
    this.icon.value = icon;
    this.iconColor.value = iconColor;
    this.progress.value = progress;
    if (isLoading != null) this.isLoading.value = isLoading;
    if (showContinue != null) this.showContinue.value = showContinue;
    if (showTryAgain != null) this.showTryAgain.value = showTryAgain;
    if (showRestart != null) this.showRestart.value = showRestart;
  }
}

Future<PermissionStatus> _requestStoragePermission() async {
  PermissionStatus status;

  if (Platform.isAndroid && Platform.version.startsWith('29')) {
    status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        status = await Permission.storage.status;
      }
    }
  } else {
    status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        status = await Permission.manageExternalStorage.status;
      }
    }
  }

  return status;
}

Future<bool> _waitForMount(String usbPath, {int maxRetries = 5, int delaySeconds = 5}) async {
  for (int i = 0; i < maxRetries; i++) {
    if (Directory(usbPath).existsSync()) {
      return true;
    }
    await Future.delayed(Duration(seconds: delaySeconds));
  }
  return false;
}

Future<void> _processFiles(BuildContext context, String usbPath, DialogStateController dialogController, DatabaseHelper dbHelper) async {
  String combinedPath = '$usbPath/RECORD';
  var directory = Directory(combinedPath);

  await Future.delayed(Duration(seconds: 15));

  final possiblePaths = [
    combinedPath,
    '/storage$combinedPath',
    '/mnt/media_rw$combinedPath',
  ];
  bool directoryFound = false;

  for (final path in possiblePaths) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      final stat = dir.statSync();
      if (stat.type == FileSystemEntityType.directory) {
        combinedPath = path;
        directory = dir;
        directoryFound = true;
        break;
      }
    }
  }

  if (!directoryFound) {
    throw Exception('No valid directory found in: $possiblePaths');
  }

  int retryCountStep3 = 0;
  const maxRetriesStep3 = 5;
  List<FileSystemEntity> files = [];

  while (retryCountStep3 < maxRetriesStep3) {
    try {
      files = directory.listSync(recursive: true, followLinks: false);
      break;
    } catch (e) {
      retryCountStep3++;
      if (retryCountStep3 < maxRetriesStep3) {
        await Future.delayed(Duration(seconds: 15));
      } else {
        dialogController.updateDialog(
          title: 'error'.tr,
          message: '${'failed_to_access_directory'.tr} ${maxRetriesStep3.toString()} ${'attempts'.tr}',
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
    title: 'transferring'.tr,
    message: '${'wait_for_transfer_remaining'.tr} ${newFiles.length}',
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
      title: 'transferring'.tr,
      message: '${'wait_for_transfer_remaining'.tr} ${(newFiles.length - (i + 1)).toString()}',
      progress: progress,
      isLoading: true,
    );
  }

  dialogController.updateDialog(
    title: 'completed'.tr,
    message: '${'all_files_have_been_downloaded'.tr}\n${newFiles.length} ${'files_transferred_successfully'.tr}',
    icon: Icons.check_circle,
    iconColor: AppColors.appColor,
    isLoading: false,
    showContinue: true,
  );

  final AudioPlayerController audioController = Get.put(AudioPlayerController());
  audioController.fetchAudioFiles();
}

Future<void> _processFilesFromSaf(BuildContext context, String uri, DialogStateController dialogController, DatabaseHelper dbHelper) async {
  dialogController.updateDialog(
    title: 'processing_saf'.tr,
    message: 'accessing_saf_directory'.tr,
    isLoading: true,
  );

  await Future.delayed(Duration(seconds: 2)); // Placeholder for SAF processing

  dialogController.updateDialog(
    title: 'completed'.tr,
    message: 'saf_files_processed'.tr,
    icon: Icons.check_circle,
    iconColor: AppColors.appColor,
    isLoading: false,
    showContinue: true,
  );
}

Future<void> connectUsbDevice(BuildContext context) async {
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

  final ApiService _apiService = ApiService();
  final dialogController = _showPersistentDialog(context);

  // Check for existing USB device on initialization
  try {
    final Map<dynamic, dynamic>? usbDeviceDetails =
    await DialogStateController.platform.invokeMethod('getUsbDeviceDetails');
    if (usbDeviceDetails != null) {
      print('USB device already connected on init');
      dialogController.isUsbAttached.value = true;
      dialogController.updateDialog(
        title: 'usb_detected'.tr,
        message: 'usb_device_detected'.tr,
        icon: Icons.usb,
        iconColor: Colors.blue.shade700,
        isLoading: false,
        showTryAgain: false,
        showContinue: false,
      );
    }
  } catch (e) {
    print('Error checking USB on init: $e');
  }

  Future<void> tryConnect() async {
    retryCount = 0;
    isUsbConnected = false;

    dialogController.updateDialog(
      title: 'connecting'.tr,
      message: 'connecting_to_recorder'.tr,
      isLoading: true,
      showTryAgain: false,
      showContinue: false,
    );

    while (retryCount < maxRetries) {
      try {
        final permissionStatus = await _requestStoragePermission();
        if (permissionStatus != PermissionStatus.granted) {
          dialogController.updateDialog(
            title: 'permission_required'.tr,
            message: 'storage_permission_message'.tr,
            icon: Icons.error,
            iconColor: Colors.red.shade700,
            isLoading: false,
            showTryAgain: true,
          );
          return;
        }

        final Map<dynamic, dynamic>? usbDeviceDetails =
        await DialogStateController.platform.invokeMethod('getUsbDeviceDetails');

        if (usbDeviceDetails != null) {
          usbPath = await DialogStateController.platform.invokeMethod<String>('getUsbPath');
          if (usbPath == null || usbPath!.isEmpty) {
            throw Exception('USB path not detected');
          }
          usbDeviceName = usbDeviceDetails['deviceName'];
          usbVendorId = usbDeviceDetails['vendorId'];
          usbProductId = usbDeviceDetails['productId'];
          usbDeviceUUID = usbDeviceDetails['deviceUUID'];
          isUsbConnected = true;

          final isMounted = await _waitForMount(usbPath!);
          if (!isMounted) {
            throw Exception('USB mount point not accessible');
          }

          if (usbVendorId == '32903') {
            final connectDevice = await _apiService.connectDevice(usbProductId.toString());
            dialogController.updateDialog(
              title: 'success'.tr,
              message: 'connected_to_recorder'.tr,
              icon: Icons.check_circle,
              iconColor: AppColors.appColor,
              isLoading: true,
            );
            await Future.delayed(Duration(seconds: 2));
            break;
          }
        } else {
          retryCount++;
          await Future.delayed(Duration(seconds: 15));
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
        title: 'error'.tr,
        message: '${'failed_to_connect_usb'.tr} ${maxRetries.toString()} ${'attempts'.tr}\n${'please_restart_app'.tr}',
        icon: Icons.error,
        iconColor: Colors.red.shade700,
        isLoading: false,
        showRestart: true,
      );
      return;
    }

    await _processFiles(context, usbPath!, dialogController, dbHelper);
  }

  if (dialogController.isUsbAttached.value) {
    await tryConnect();
  } else {
    dialogController.updateDialog(
      title: 'waiting_for_usb'.tr,
      message: 'please_connect_usb_device'.tr,
      icon: Icons.usb,
      iconColor: Colors.blue.shade700,
      isLoading: false,
      showTryAgain: false,
      showContinue: false,
    );
  }
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
  Get.put<DialogStateController>(DialogStateController(), tag: 'usbDialogController');
  final controller = Get.find<DialogStateController>(tag: 'usbDialogController');

  // Close any existing dialog to prevent stacking
  if (Get.isDialogOpen ?? false) {
    Get.back();
  }

  Get.dialog(
    WillPopScope(
      onWillPop: () async => false,
      child: Obx(() => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                controller.iconColor.value == Colors.red.shade700
                    ? Colors.red.shade100
                    : controller.iconColor.value == AppColors.appColor
                    ? AppColors.appColor2
                    : Colors.blue.shade100,
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
              if (controller.progress.value != null &&
                  !controller.showContinue.value &&
                  !controller.showTryAgain.value &&
                  !controller.showRestart.value) ...[
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
              if (controller.showRestart.value) ...[
                SizedBox(height: 20),
                CustomButton(
                  borderRadius: 30,
                  width: 160,
                  text: 'Restart App',
                  onPressed: () async {
                    await DialogStateController.platform.invokeMethod('restartApp');
                  },
                  backgroundColor: AppColors.appColor,
                  textColor: Colors.white,
                ),
              ] else if (controller.showContinue.value) ...[
                SizedBox(height: 20),
                CustomButton(
                  borderRadius: 30,
                  width: 160,
                  text: 'Continue',
                  onPressed: () {
                    // Ensure all dialogs are closed
                    while (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                  },
                  backgroundColor: AppColors.appColor,
                  textColor: Colors.white,
                ),
              ] else if (controller.showTryAgain.value) ...[
                SizedBox(height: 20),
                CustomButton(
                  borderRadius: 30,
                  width: 160,
                  text: 'Try Again',
                  onPressed: () async {
                    controller.updateDialog(showTryAgain: false);
                    // Close current dialog before retrying
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                    await connectUsbDevice(context);
                  },
                  backgroundColor: AppColors.appColor,
                  textColor: Colors.white,
                ),
              ] else if (!controller.isLoading.value) ...[
                SizedBox(height: 20),
                CustomButton(
                  borderRadius: 30,
                  width: 160,
                  text: 'Connect',
                  onPressed: controller.isUsbAttached.value
                      ? () async {
                    controller.updateDialog(
                      showTryAgain: false,
                      showContinue: false,
                    );
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                    await connectUsbDevice(context);
                  }
                      : null,
                  backgroundColor: controller.isUsbAttached.value
                      ? AppColors.appColor
                      : Colors.grey.shade400,
                  textColor: controller.isUsbAttached.value
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ],
            ],
          ),
        ),
      )),
    ),
    barrierDismissible: false,
  );

  return controller;
}