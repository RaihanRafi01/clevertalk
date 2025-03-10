import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Define the TaskHandler for the foreground service
class RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("Foreground task started at $timestamp with starter: $starter");
  }

  @override
  Future<void> onEvent(DateTime timestamp, TaskStarter? starter) async {
    print("Foreground task is running at $timestamp with starter: $starter");
    await FlutterForegroundTask.updateService(
      notificationTitle: "Recording Audio",
      notificationText: "Your app is recording audio in the background",
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print("Foreground task destroyed at $timestamp");
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }
}