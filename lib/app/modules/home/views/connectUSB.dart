import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../common/appColors.dart';
import '../../../data/database_helper.dart';
import '../../audio/controllers/audio_controller.dart';
import '../../text/controllers/text_controller.dart';
import 'package:just_audio/just_audio.dart';

Future<void> connectUsbDevice(BuildContext context) async {
  const platform = MethodChannel('usb_path_reader/usb');
  //final AudioPlayer audioPlayer = AudioPlayer();
  final dbHelper = DatabaseHelper();
  String selectedPath = '/RECORD';
  String? usbPath;
  String? usbDeviceUUID;
  String? usbProductId;
  String? usbVendorId;
  String? usbDeviceName;
  bool isUsbConnected = false;
  //List<String> audioFiles = [];

  int retryCount = 0;
  const maxRetries = 3;

  // Show loading dialog
  _showLoadingDialog(context, "Connecting USB device...");

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

        _showSnackbar(
          context,
          'USB connected: Name=$usbDeviceName, UUID=$usbDeviceUUID, VendorID=$usbVendorId, ProductID=$usbProductId',
        );
        break;
      } else {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 10));
        }
      }
    } catch (e) {
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 10));
      }
    }
  }

  if (!isUsbConnected || usbPath == null) {
    Navigator.pop(context);
    _showSnackbar(context, 'Failed to connect USB device after $maxRetries attempts');
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
          await Future.delayed(Duration(seconds: 10));
        } else {
          Navigator.pop(context);
          _showSnackbar(context, 'Failed to access directory after $maxRetriesStep3 attempts.');
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

    Navigator.pop(context);
    _showProgressDialog(context, "Processing new audio files...");

    for (var i = 0; i < newFiles.length; i++) {
      final file = newFiles[i];
      final originalFilePath = file.path;
      final localFilePath = await _copyFileToLocal(originalFilePath);
      final duration = await _getAudioDuration(localFilePath);

      await dbHelper.insertAudioFile(
        context,
        localFilePath.split('/').last,
        localFilePath,
        duration,
        false,
        '',
      );

      final progress = (i + 1) / newFiles.length;
      _updateProgressDialog(context, "Processing file ${i + 1} of ${newFiles.length}...", progress);
    }

    Navigator.pop(context);

    _showSnackbar(context, 'Added ${newFiles.length} new audio files to the database.');
    final AudioPlayerController audioController = Get.put(AudioPlayerController());
    //final TextViewController textViewController = Get.put(TextViewController());
    audioController.fetchAudioFiles();
    //textViewController.fetchTextFiles();

  } catch (e) {
    _showSnackbar(context, 'An error occurred: $e');
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
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  } catch (e) {
    return '0:00';
  } finally {
    await audioPlayer.dispose();
  }

  return '0:00';
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _showProgressDialog(BuildContext context, String message, {double progress = 0}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.appColor),
                ),
              ),
              SizedBox(height: 8),
              Text('${(progress * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
        ),
      );
    },
  );
}

void _updateProgressDialog(BuildContext context, String message, double progress) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context); // Close the previous dialog
    _showProgressDialog(context, message, progress: progress);
  }
}

void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
