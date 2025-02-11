import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../../data/database_helper.dart';

class UsbFilePicker extends StatefulWidget {
  @override
  _UsbFilePickerState createState() => _UsbFilePickerState();
}

class _UsbFilePickerState extends State<UsbFilePicker> {
  static const platform = MethodChannel('usb_path_reader/usb');
  String? _selectedPath = '/RECORD';
  String? _usbPath;
  String? _usbDeviceUUID;
  String? _usbProductId;
  String? _usbVendorId;
  String? _usbDeviceName;

  String _selectedFolderPath = '';  // Store the selected folder path

  List<String> _audioFiles = [];
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isUsbConnected = false;

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
    _requestPermissions();
    _fetchSavedFiles();
    _checkUsbDeviceConnection();

  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "onFolderSelected") {
        final uriStr = call.arguments as String;
        final resolvedPath = await _resolveContentUri(uriStr);
        _showSnackbar(context, 'Selected Folder::: $resolvedPath');
        setState(() {
          _selectedFolderPath = resolvedPath;
        });

      }
    });
  }

  // New method to pick a folder
  Future<void> _pickFolder() async {
    try {
      // Open the folder picker (updated method name in newer versions)
      final result = await FilePicker.platform.getDirectoryPath();

      if (result != null && result.isNotEmpty) {
        setState(() {
          _selectedFolderPath = result;
        });
        _showSnackbar(context, 'Selected Folder: $_selectedFolderPath');
      } else {
        _showSnackbar(context, 'No folder selected');
      }
    } catch (e) {
      _showSnackbar(context, 'Error picking folder: $e');
    }
  }

  Future<void> _pickFolder2() async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.OPEN_DOCUMENT_TREE',
      );
      await intent.launch();
    } catch (e) {
      _showSnackbar(context, 'Error picking folder: $e');
    }
  }

// Platform-specific method to resolve content URIs on Android
  Future<String> _resolveContentUri(String uriStr) async {
    const platform = MethodChannel('usb_path_reader/usb');
    try {
      final resolvedPath = await platform.invokeMethod('resolveContentUri', {'uri': uriStr});
      return resolvedPath ?? uriStr; // Fallback to original URI if resolution fails
    } catch (e) {
      return uriStr; // Return original URI if error occurs
    }
  }

  // part 1

  void _checkUsbDeviceConnection() async {
    try {
      final Map<dynamic, dynamic>? usbDeviceDetails =
      await platform.invokeMethod('getUsbDeviceDetails');

      if (usbDeviceDetails != null) {
        setState(() async {
          _usbPath = await platform.invokeMethod<String>('getUsbPath');
          _usbDeviceName = usbDeviceDetails['deviceName'];
          _usbVendorId = usbDeviceDetails['vendorId'];
          _usbProductId = usbDeviceDetails['productId'];
          _usbDeviceUUID = usbDeviceDetails['deviceUUID'];
          _isUsbConnected = true;
        });

        _showSnackbar(
          context,
          'USB connected: Name=${_usbDeviceName}, UUID=${_usbDeviceUUID}, _usbVendorId=${_usbVendorId}, _usbProductId=${_usbProductId}',
        );
      } else {
        setState(() {
          _isUsbConnected = false;
        });
        _showSnackbar(context, 'No USB devices connected');
      }
    } on PlatformException catch (e) {
      _showSnackbar(context, 'Failed to get USB device details: ${e.message}');
    }
  }



  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isDenied) {
      _showSnackbar(context, 'Storage permission denied!');
    }
    if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  //part 2

  void _listAudioFiles(String path) async {
    try {
      final directory = Directory(path);
      if (directory.existsSync()) {
        final files = directory.listSync(recursive: true, followLinks: false);
        final audioFiles = files.where((file) {
          final extension = file.path.split('.').last.toLowerCase();
          return ['mp3', 'wav', 'aac'].contains(extension);
        }).toList();

        // Save to database
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteAllAudioFiles(context);

        for (var file in audioFiles) {
          final originalFilePath = file.path;
          final localFilePath = await _copyFileToLocal(originalFilePath);
          final duration = await _getAudioDuration(localFilePath);

          await dbHelper.insertAudioFile(
            context,
            localFilePath.split('/').last, // File name
            localFilePath,                // Local file path
            duration,
            false,
            ''
          );
        }

        setState(() {
          _audioFiles =
              audioFiles.map((file) => file.path.split('/').last).toList();
        });

        _showSnackbar(context, 'Audio files saved locally: ${audioFiles.length}');
      } else {
        _showSnackbar(context, 'Directory does not exist!');
      }
    } catch (e) {
      _showSnackbar(context, 'Error listing files: $e');
    }
  }

  // part 3

  Future<String> _copyFileToLocal(String filePath) async {
    try {
      // Get the app's local directory
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/${filePath.split('/').last}';

      // Copy the file to the local directory
      final sourceFile = File(filePath);
      final destinationFile = File(localPath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(localPath);
        return localPath; // Return the local path for database storage
      } else {
        throw Exception('Source file does not exist!');
      }
    } catch (e) {
      throw Exception('Error copying file: $e');
    }
  }

  Future<String> _getAudioDuration(String filePath) async {
    final audioPlayer = AudioPlayer();
    Duration? duration;

    try {
      await audioPlayer.play(DeviceFileSource(filePath));
      await Future.delayed(Duration(milliseconds: 1000)); // Short delay to get duration
      duration = await audioPlayer.getDuration();
      await audioPlayer.stop();
    } catch (e) {
      print('Error fetching duration for $filePath: $e');
      return '0:00'; // Default duration on error
    }

    if (duration != null) {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '0:00';
  }

  // part 4

  void _fetchSavedFiles() async {
    final dbHelper = DatabaseHelper();
    final savedFiles = await dbHelper.fetchAudioFiles();

    setState(() {
      _audioFiles = savedFiles.map((file) {
        final fileName = file['file_name'] as String;
        final duration = file['duration'] as String;
        final savedDate = file['saved_date'] as String;
        return '$fileName | $duration | $savedDate';
      }).toList();
    });

    _showSnackbar(context, 'Fetched ${_audioFiles.length} saved audio files.');
  }

  Future<void> _playAudioFromDatabase(String fileName) async {
    final dbHelper = DatabaseHelper();
    final savedFiles = await dbHelper.fetchAudioFiles();
    final filePath = savedFiles.firstWhere(
            (file) => file['file_name'] == fileName)['file_path'];

    try {
      // Play the audio from the local path
      await _audioPlayer.play(DeviceFileSource(filePath));
      _showSnackbar(context, 'Playing $fileName');
    } catch (e) {
      _showSnackbar(context, 'Error playing audio: $e');
    }
  }


  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String combinedPath = '$_usbPath$_selectedPath';

    return Scaffold(
      appBar: AppBar(title: Text('USB Drive Audio Files')),
      body: Column(
        children: [
          // Add new button to pick folder
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: Text('Selected Folder Path: $_selectedFolderPath')),
                IconButton(
                  icon: Icon(Icons.folder_open),
                  onPressed: _pickFolder2,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            color: _isUsbConnected ? Colors.green : Colors.red,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: _isUsbConnected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  _isUsbConnected
                      ? 'USB Device Connected'
                      : 'USB Device Not Connected',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: Text('Selected Path: $combinedPath')),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => _listAudioFiles(combinedPath),
                ),
              ],
            ),
          ),
          if (_isUsbConnected) // Show details only if USB is connected
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USB Device Details:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  SelectableText('Path: $_usbPath', style: TextStyle(fontSize: 16)),
                  SelectableText('Device Name: $_usbDeviceName', style: TextStyle(fontSize: 16)),
                  SelectableText('Vendor ID: $_usbVendorId', style: TextStyle(fontSize: 16)),
                  SelectableText('Product ID: $_usbProductId', style: TextStyle(fontSize: 16)),
                  SelectableText('Device UUID: $_usbDeviceUUID', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          Expanded(
            child: _audioFiles.isEmpty
                ? Center(child: Text('No audio files found.'))
                : ListView.builder(
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                final fileDetails = _audioFiles[index];
                return ListTile(
                  title: Text(fileDetails),
                  trailing: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {
                      final fileName = fileDetails.split('|')[0].trim();
                      _playAudioFromDatabase(fileName);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
