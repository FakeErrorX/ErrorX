import 'dart:io';
import 'package:flutter/services.dart';
import 'package:errorx/common/common.dart';

class BatteryOptimizationService {
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  
  factory BatteryOptimizationService() {
    return _instance;
  }
  
  BatteryOptimizationService._internal();
  
  // Method channel to communicate with native code
  final MethodChannel _channel = const MethodChannel('net.errorx.vpn/battery_optimization');
  
  // Check if the app is ignoring battery optimizations
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) {
      return true; // Not applicable on non-Android platforms
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
      return result;
    } catch (e) {
      commonPrint.log('Error checking battery optimization status: $e');
      return false;
    }
  }
  
  // Request to ignore battery optimizations
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) {
      return; // Not applicable on non-Android platforms
    }
    
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      commonPrint.log('Requested battery optimization exemption');
    } catch (e) {
      commonPrint.log('Error requesting battery optimization exemption: $e');
    }
  }
  
  // Open battery optimization settings
  Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) {
      return; // Not applicable on non-Android platforms
    }
    
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
      commonPrint.log('Opened battery optimization settings');
    } catch (e) {
      commonPrint.log('Error opening battery optimization settings: $e');
    }
  }
  
  // Check and handle battery optimization on app start
  Future<void> checkAndHandleBatteryOptimization() async {
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      final isIgnoring = await isIgnoringBatteryOptimizations();
      
      if (!isIgnoring) {
        commonPrint.log('App is not ignoring battery optimizations, this may cause WebSocket disconnections');
        
        // You could show a dialog here to inform the user and request exemption
        // For now, we'll just log it
        // Uncomment the line below to automatically request exemption
        // await requestIgnoreBatteryOptimizations();
      } else {
        commonPrint.log('App is ignoring battery optimizations - good for background connectivity');
      }
    } catch (e) {
      commonPrint.log('Error checking battery optimization: $e');
    }
  }
}
