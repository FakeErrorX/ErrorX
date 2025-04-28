import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:io';
import 'package:errorx/common/common.dart';
import 'package:errorx/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Background service for handling WebSocket connections when app is in background
class BackgroundService {
  static const String _wsKeepAliveTask = 'ws_keep_alive_task';
  static const String _wsKeepAlivePeriodic = 'ws_keep_alive_periodic';
  static const String _isolateName = 'WebSocketIsolate';

  /// Initialize the background service
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for detailed logs during development
    );

    // Register periodic task to keep WebSocket alive
    await registerKeepAliveTask();
  }

  /// Register a periodic task to keep the WebSocket alive
  static Future<void> registerKeepAliveTask() async {
    // Cancel any existing tasks
    await Workmanager().cancelByUniqueName(_wsKeepAlivePeriodic);

    // Check if user is logged in before registering task
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final licenseKey = prefs.getString('license_key');

    if (isLoggedIn && licenseKey != null && licenseKey.isNotEmpty) {
      // Register a periodic task to run every 30 seconds
      // Note: Android has a minimum interval of 15 minutes for periodic tasks,
      // so we'll use a one-off task with a frequency constraint instead
      await Workmanager().registerOneOffTask(
        _wsKeepAlivePeriodic,
        _wsKeepAliveTask,
        initialDelay: const Duration(seconds: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      
      commonPrint.log('WebSocket keep-alive task registered');
    } else {
      commonPrint.log('User not logged in, WebSocket keep-alive task not registered');
    }
  }

  /// Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelByUniqueName(_wsKeepAlivePeriodic);
    commonPrint.log('All WebSocket background tasks cancelled');
  }
}

/// The callback function that will be called by WorkManager in the background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      commonPrint.log('Executing background task: $taskName');
      
      if (taskName == BackgroundService._wsKeepAliveTask) {
        await _performWebSocketKeepAlive();
        
        // Re-register the task for the next execution
        await BackgroundService.registerKeepAliveTask();
      }
      
      return true;
    } catch (e) {
      commonPrint.log('Error in background task: $e');
      return false;
    }
  });
}

/// Perform the WebSocket keep-alive operation
Future<void> _performWebSocketKeepAlive() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final licenseKey = prefs.getString('license_key');

  if (!isLoggedIn || licenseKey == null || licenseKey.isEmpty) {
    commonPrint.log('Not logged in, skipping WebSocket keep-alive');
    return;
  }

  // Create a new API service instance just for the background task
  final apiService = ApiService();
  
  // Send a ping to keep the WebSocket alive
  apiService.backgroundPing();
  
  // Give it time to complete the operation
  await Future.delayed(const Duration(seconds: 3));
  
  commonPrint.log('WebSocket keep-alive completed');
} 