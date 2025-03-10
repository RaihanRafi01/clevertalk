import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/database_helper.dart';
import '../../audio/controllers/audio_controller.dart';
import '../../text/controllers/text_controller.dart';

class RecordController extends GetxController {
  var recordingTime = 0.obs;
  var recordingMilliseconds = 0.obs;
  var isRecording = false.obs;
  var isPaused = false.obs; // Track if the recording is paused
  var waveformOffset = 0.0.obs; // Track the position of the waveform
  Timer? _timer;
  FlutterSoundRecorder? _recorder;
  String? _filePath;

  int _pauseTime = 0; // Track time when recording is paused
  int _pauseMilliseconds = 0; // Track milliseconds when recording is paused
  final AudioPlayerController audioPlayerController = Get.put(AudioPlayerController());
  final TextViewController textViewController = Get.put(TextViewController());

  @override
  void onInit() {
    super.onInit();
    requestPermissions();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    initBackground();
  }

  bool _backgroundInitialized = false;

  Future<void> initBackground() async {
    try {
      if (!_backgroundInitialized) {
        final androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "Recording Audio",
          notificationText: "Audio is being recorded in the background",
          notificationImportance: AndroidNotificationImportance.high,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );

        // Initialize and enable in sequence
        await FlutterBackground.initialize(androidConfig: androidConfig);
        _backgroundInitialized = true;
      }

      if (!await FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.enableBackgroundExecution();
      }
    } catch (e) {
      print("Background initialization error: $e");
      rethrow;
    }
  }

  Future<void> requestPermissions() async {
    var status = await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.notification.request();
    if (status.isGranted) {
      print("Microphone permission granted");
    } else {
      print("Microphone permission denied");
    }

    status = await Permission.storage.request();
    if (status.isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder?.openRecorder();
      print("Recorder initialized successfully.");
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> startRecording() async {
    try {
      // Initialize background first
      await initBackground();

      // Configure audio session for background
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
        AVAudioSessionCategoryOptions.defaultToSpeaker |
        AVAudioSessionCategoryOptions.mixWithOthers,
      ));
      await session.setActive(true);

      // Start recording with proper format
      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder?.startRecorder(
        toFile: _filePath,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
        bitRate: 128000,
      );

      // Keep existing timer logic
      isRecording.value = true;
      recordingTime.value = 0;
      recordingMilliseconds.value = 0;
      waveformOffset.value = 0.0;

      _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
        if (isRecording.value && !isPaused.value) {
          recordingMilliseconds.value += 50;
          if (recordingMilliseconds.value >= 1000) {
            recordingMilliseconds.value = 0;
            recordingTime.value++;
          }
          waveformOffset.value -= 2;
          if (waveformOffset.value <= -Get.width) waveformOffset.value = 0;
        }
      });

    } catch (e) {
      print("Error starting recording: $e");
      Get.snackbar("Error", "Failed to start recording: ${e.toString()}");
    }
  }

  Future<void> stopRecording() async {
    try {
      await _recorder?.stopRecorder();
      await FlutterBackground.disableBackgroundExecution();
      final session = await AudioSession.instance;
      await session.setActive(false);

      // Your existing cleanup logic
      isRecording.value = false;
      _timer?.cancel();
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }


  Future<void> pauseRecording() async {
    try {
      await _recorder?.pauseRecorder();
      isPaused.value = true;

      // Save the current state of time and milliseconds when paused
      _pauseTime = recordingTime.value;
      _pauseMilliseconds = recordingMilliseconds.value;

      // Pause the timer
      _timer?.cancel();
      print("Recording paused.");
    } catch (e) {
      print("Error pausing recording: $e");
    }
  }

  void resumeRecording() async {
    try {
      await _recorder?.resumeRecorder();
      isPaused.value = false;

      // Restart the timer from the paused state
      _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
        if (isRecording.value && !isPaused.value) {
          recordingMilliseconds.value += 50;
          if (recordingMilliseconds.value >= 1000) {
            recordingMilliseconds.value = 0;
            recordingTime.value++;
          }

          waveformOffset.value -= 2;
          if (waveformOffset.value <= -Get.width) {
            waveformOffset.value = 0.0;
          }
        }
      });

      // Resume from the paused time
      recordingTime.value = _pauseTime;
      recordingMilliseconds.value = _pauseMilliseconds;

      print("Recording resumed.");
    } catch (e) {
      print("Error resuming recording: $e");
    }
  }

  Future<void> saveRecording(String filename) async {
    print(':::::::::::::::::::::::::TIME:::::::::::::::::${recordingTime.value} :: ${recordingMilliseconds.value}');
    final duration = formatTime(recordingTime.value, recordingMilliseconds.value);

    // Insert audio details into the database
    if (_filePath != null) {
      String formattedDate =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await DatabaseHelper().insertAudioFile(true,Get.context!, '$filename.WAV',
          _filePath!, duration, true, formattedDate);
      await stopRecording();
      audioPlayerController.fetchAudioFiles();
      textViewController.fetchTextFiles();
    }

    /*final directory = await getApplicationDocumentsDirectory();
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final localPath = '${directory.path}/${_filePath?.split('/').last}';

      File(_filePath!).copySync(localPath);*/
    /*//print("Recording stopped and saved to the database.");

      // Copy the file to the local path
      //
      print("Recording saved at: $localPath");
    } else {
      print("No recording to save.");
    }*/
  }

  @override
  void onClose() {
    _timer?.cancel();
    _recorder?.closeRecorder();
    FlutterBackground.disableBackgroundExecution();
    super.onClose();
  }

  String formatTime(int seconds, int milliseconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }
}