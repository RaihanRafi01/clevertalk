import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../common/appColors.dart';
import '../../../data/database_helper.dart';

Future<void> connectUsbDevice(BuildContext context) async {
  const platform = MethodChannel('usb_path_reader/usb');
  final AudioPlayer audioPlayer = AudioPlayer();
  final dbHelper = DatabaseHelper();
  String selectedPath = '/RECORD';
  String? usbPath;
  String? usbDeviceUUID;
  String? usbProductId;
  String? usbVendorId;
  String? usbDeviceName;
  bool isUsbConnected = false;
  List<String> audioFiles = [];

  int retryCount = 0;
  const maxRetries = 3;

  // Show loading dialog
  _showLoadingDialog(context, "Connecting USB device...");

  while (retryCount < maxRetries) {
    try {
      // Step 1: Request permissions
      if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      // Step 2: Check USB connection
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
    Navigator.pop(context); // Dismiss loading dialog
    _showSnackbar(context, 'Failed to connect USB device after $maxRetries attempts');
    return;
  }

  try {
    // Step 3: List and process audio files
    String combinedPath = '$usbPath$selectedPath';
    final directory = Directory(combinedPath);

    if (!directory.existsSync()) {
      Navigator.pop(context); // Dismiss loading dialog
      _showSnackbar(context, 'Directory does not exist!');
      return;
    }

    final files = directory.listSync(recursive: true, followLinks: false);
    final audioFilesList = files.where((file) {
      final extension = file.path.split('.').last.toLowerCase();
      return ['mp3', 'wav', 'aac'].contains(extension);
    }).toList();

    // Delete existing audio files from the database
    await dbHelper.deleteAllAudioFiles(context);

    Navigator.pop(context); // Dismiss initial loading dialog

    // Show progress indicator during database insertion
    _showProgressDialog(context, "Processing audio files...");

    for (var i = 0; i < audioFilesList.length; i++) {
      final file = audioFilesList[i];
      final originalFilePath = file.path;
      final localFilePath = await _copyFileToLocal(originalFilePath);
      final duration = await _getAudioDuration(localFilePath, audioPlayer);

      await dbHelper.insertAudioFile(
        context,
        localFilePath.split('/').last, // File name
        localFilePath, // Local file path
        duration,
        false,
        '',
      );

      // Update progress
      final progress = (i + 1) / audioFilesList.length;
      _updateProgressDialog(context, "Processing file ${i + 1} of ${audioFilesList.length}...", progress);
    }

    Navigator.pop(context); // Dismiss progress dialog

    // Show loading dialog while fetching saved files
    _showProgressDialog(context, "Fetching saved files...", progress: 0.0);

    // Step 4: Fetch saved files from the database
    final savedFiles = await dbHelper.fetchAudioFiles(context);

    Navigator.pop(context); // Dismiss fetching dialog

    if (savedFiles.isNotEmpty) {
      audioFiles = savedFiles.map((file) {
        final fileName = file['file_name'] as String;
        final duration = file['duration'] as String;
        final savedDate = file['saved_date'] as String;
        return '$fileName | $duration | $savedDate';
      }).toList();

      _showSnackbar(
          context, 'Fetched ${audioFiles.length} saved audio files.');
    } else {
      _showSnackbar(context, 'No saved audio files found in the database!');
    }
  } catch (e) {
    _showSnackbar(context, 'An error occurred: $e');
  } finally {
    // Dispose the audio player when done
    audioPlayer.dispose();
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

Future<String> _getAudioDuration(String filePath, AudioPlayer audioPlayer) async {
  Duration? duration;

  try {
    await audioPlayer.play(DeviceFileSource(filePath));
    await Future.delayed(Duration(milliseconds: 1000));
    duration = await audioPlayer.getDuration();
    await audioPlayer.stop();
  } catch (e) {
    return '0:00';
  }

  if (duration != null) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
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
