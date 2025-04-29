import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/services/api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  
  factory WebSocketService() {
    return _instance;
  }
  
  WebSocketService._internal();
  
  // Method channel to communicate with native code
  final MethodChannel _channel = const MethodChannel('net.errorx.vpn/websocket');
  
  // Flag to track if keep-alive service is running
  bool _isKeepAliveServiceRunning = false;
  
  // Start the background keep-alive service for WebSocket connection
  Future<bool> startKeepAliveService() async {
    if (!Platform.isAndroid) {
      // Only needed on Android
      return false;
    }
    
    try {
      if (!_isKeepAliveServiceRunning) {
        commonPrint.log('Starting WebSocket keep-alive service');
        final result = await _channel.invokeMethod<bool>('startKeepAliveService') ?? false;
        _isKeepAliveServiceRunning = result;
        return result;
      }
      return true;
    } catch (e) {
      commonPrint.log('Error starting WebSocket keep-alive service: $e');
      return false;
    }
  }
  
  // Stop the background keep-alive service
  Future<bool> stopKeepAliveService() async {
    if (!Platform.isAndroid) {
      // Only needed on Android
      return false;
    }
    
    try {
      if (_isKeepAliveServiceRunning) {
        commonPrint.log('Stopping WebSocket keep-alive service');
        final result = await _channel.invokeMethod<bool>('stopKeepAliveService') ?? false;
        _isKeepAliveServiceRunning = !result;
        return result;
      }
      return true;
    } catch (e) {
      commonPrint.log('Error stopping WebSocket keep-alive service: $e');
      return false;
    }
  }
  
  // Initialize the WebSocket keep-alive mechanism
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      // Only needed on Android
      return;
    }
    
    // Set up method channel handler for keepWebSocketAlive calls from native
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'keepWebSocketAlive') {
        // Send a ping via the API service to keep the WebSocket alive
        _sendPingToKeepAlive();
        return true;
      }
      return null;
    });
    
    // Start the keep-alive service if needed
    await startKeepAliveService();
  }
  
  // Send a ping to keep the WebSocket connection alive
  void _sendPingToKeepAlive() {
    try {
      final apiService = ApiService();
      
      // Check if WebSocket is connected before sending ping
      if (apiService.isWebSocketConnected()) {
        commonPrint.log('Sending ping from background worker to keep WebSocket alive');
        
        // Use the API service to check connection (this will send a ping internally)
        apiService.checkConnection();
        
        // Schedule the next ping (as a backup in case the worker fails)
        _scheduleNextPing();
      } else {
        commonPrint.log('WebSocket not connected, attempting to reconnect');
        
        // Check connection and attempt to reconnect if needed
        apiService.checkConnection();
      }
    } catch (e) {
      commonPrint.log('Error sending ping to keep WebSocket alive: $e');
    }
  }
  
  // Schedule the next ping (as a backup mechanism)
  Future<void> _scheduleNextPing() async {
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      await _channel.invokeMethod('scheduleNextPing');
    } catch (e) {
      commonPrint.log('Error scheduling next ping: $e');
    }
  }
  
  // Clean up resources
  Future<void> dispose() async {
    if (Platform.isAndroid) {
      await stopKeepAliveService();
    }
  }
} 