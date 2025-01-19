import 'dart:io';
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
  List<String> _audioFiles = [];
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isUsbConnected = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchSavedFiles();
    _checkUsbConnection();
  }

  void _checkUsbConnection() async {
    try {
      String? usbPath = await platform.invokeMethod('getUsbPath');
      setState(() {
        _usbPath = usbPath;
        _isUsbConnected = usbPath != null;
      });
      _showSnackbar(context,
          _isUsbConnected ? 'USB connected: $usbPath' : 'USB not connected');
    } on PlatformException catch (e) {
      _showSnackbar(context, 'Failed to get USB path: ${e.message}');
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

  void _fetchSavedFiles() async {
    final dbHelper = DatabaseHelper();
    final savedFiles = await dbHelper.fetchAudioFiles(context);

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
    final savedFiles = await dbHelper.fetchAudioFiles(context);
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
