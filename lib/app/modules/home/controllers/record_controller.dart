import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/database_helper.dart';
import '../../../data/services/recordingTask_service.dart';
import '../../audio/controllers/audio_controller.dart';
import '../../text/controllers/text_controller.dart';

class RecordController extends GetxController with WidgetsBindingObserver {
  var recordingTime = 0.obs;
  var recordingMilliseconds = 0.obs;
  var isRecording = false.obs;
  var isPaused = false.obs;
  var waveformOffset = 0.0.obs;
  Timer? _timer;
  FlutterSoundRecorder? _recorder;
  String? _filePath;

  int _pauseTime = 0;
  int _pauseMilliseconds = 0;
  final AudioPlayerController audioPlayerController = Get.put(AudioPlayerController());
  final TextViewController textViewController = Get.put(TextViewController());

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    requestPermissions();
    //requestForegroundMicrophonePermission();
    //disableBatteryOptimizations();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    /*Future.delayed(Duration(milliseconds: 100), ()  {
      _initForegroundTask();
    });*/
  }

  @override
  void onClose() {
    _timer?.cancel();
    _recorder?.closeRecorder();
    FlutterForegroundTask.stopService();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRecording.value && !isPaused.value) {
      print("App minimized, foreground service keeps recording");
    } else if (state == AppLifecycleState.resumed) {
      print("App resumed, attempting to resume recording if paused");
      if (isRecording.value && isPaused.value) {
        resumeRecording();
      }
    }
  }

  Future<void> requestForegroundMicrophonePermission() async {
    if (Platform.isAndroid && int.parse(Platform.operatingSystemVersion.split(' ')[0]) >= 14) {
      const MethodChannel _channel = MethodChannel('request_foreground_microphone');

      try {
        final bool granted = await _channel.invokeMethod('requestPermission');
        if (!granted) {
          print("Foreground microphone permission denied");
        }
      } on PlatformException catch (e) {
        print("Error requesting foreground microphone permission: $e");
      }
    }
  }



  Future<void> _initForegroundTask() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'recording_channel',
          channelName: 'Recording Service',
          channelDescription: 'This app is recording audio in the background',
          channelImportance: NotificationChannelImportance.DEFAULT,
          priority: NotificationPriority.DEFAULT,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
      print("Foreground task initialized successfully");
    } catch (e) {
      print("Error initializing foreground task: $e");
      if (Get.overlayContext != null) {
        Get.snackbar("Error", "Failed to initialize foreground task: $e");
      } else {
        print("Overlay context unavailable, cannot show snackbar");
      }
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
      print("Recorder initialized successfully");
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> startRecording() async {
    try {
      // Ensure the service starts properly
      ServiceRequestResult serviceStarted = await FlutterForegroundTask.startService(
        notificationTitle: "Recording Audio",
        notificationText: "Your app is recording audio in the background",
      );
      print(":::::::::::::::::::::::::Service start result: $serviceStarted");

      // Acquire proper audio focus
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,  // <- Change to `voiceChat`
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
        AVAudioSessionCategoryOptions.defaultToSpeaker |
        AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientExclusive,
        androidWillPauseWhenDucked: false,
      ));

      await session.setActive(true);

      session.interruptionEventStream.listen((event) async {
        if (event.begin && isRecording.value && !isPaused.value) {
          print("Microphone interrupted by another app!");
          await pauseRecording();
          Get.snackbar("Recording Paused", "Another app is using the microphone.");
        } else if (!event.begin && isRecording.value && isPaused.value) {
          print("Microphone access restored, resuming recording...");
          await resumeRecording();
          Get.snackbar("Recording Resumed", "Microphone access restored.");
        }
      });

      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder?.startRecorder(
        toFile: _filePath,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
        bitRate: 128000,
      );

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

      print("Recording started successfully");
    } catch (e) {
      print("Error starting recording: $e");
      Get.snackbar("Error", "Failed to start recording: ${e.toString()}");
    }
  }


  Future<void> stopRecording() async {
    try {
      isRecording.value = false;
      _timer?.cancel();
      await _recorder?.stopRecorder();
      await FlutterForegroundTask.stopService();
      final session = await AudioSession.instance;
      await session.setActive(false);
      // Your existing cleanup logic
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _recorder?.pauseRecorder();
      isPaused.value = true;

      _pauseTime = recordingTime.value;
      _pauseMilliseconds = recordingMilliseconds.value;

      _timer?.cancel();
      print("Recording paused at ${DateTime.now()}");
    } catch (e) {
      print("Error pausing recording: $e");
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recorder?.resumeRecorder();
      isPaused.value = false;

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

      recordingTime.value = _pauseTime;
      recordingMilliseconds.value = _pauseMilliseconds;

      print("Recording resumed at ${DateTime.now()}");
    } catch (e) {
      print("Error resuming recording: $e");
      Get.snackbar("Error", "Failed to resume recording: ${e.toString()}");
    }
  }
  Future<void> saveRecording(String filename) async {
    print(':::::::::::::::::::::::::TIME:::::::::::::::::${recordingTime.value} :: ${recordingMilliseconds.value}');
    final duration = formatTime(recordingTime.value, recordingMilliseconds.value);

    // Insert audio details into the database
    if (_filePath != null) {
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await DatabaseHelper().insertAudioFile(
        true,
        Get.context!,
        '$filename.WAV',
        _filePath!,
        duration,
        true,
        formattedDate,
      );

      await stopRecording();

      // Reset recording variables
      recordingTime.value = 0;
      recordingMilliseconds.value = 0;
      waveformOffset.value = 0.0;
      isPaused.value = false;
      _pauseTime = 0;
      _pauseMilliseconds = 0;

      audioPlayerController.fetchAudioFiles();
      textViewController.fetchTextFiles();
    }
  }


  String formatTime(int seconds, int milliseconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }
}