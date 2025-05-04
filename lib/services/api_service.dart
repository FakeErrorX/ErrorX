import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/services/secrets.dart';
import 'package:errorx/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:errorx/state.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URLs from secrets.dart
  static final String baseUrl = apiBaseUrl;
  static final String wsUrl = apiWebSocketUrl;
  
  // API Keys from secrets.dart
  static final String apiKey = apiKeyValue;
  static final String apiSecret = apiSecretValue;
  
  // Internal state
  String? _licenseKey;
  String? _sessionToken;
  String? _deviceId;
  WebSocketChannel? _webSocketChannel;
  Timer? _pingTimer;
  bool _isReconnecting = false;
  Map<String, dynamic>? _lastLicenseStatus;
  Timer? _pingChecker;
  DateTime? _lastPingTime;
  
  // Callbacks for logout
  final List<void Function(String)> _logoutListeners = [];
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Add a logout listener
  void addLogoutListener(void Function(String) listener) {
    if (!_logoutListeners.contains(listener)) {
      _logoutListeners.add(listener);
    }
  }
  
  // Remove a logout listener
  void removeLogoutListener(void Function(String) listener) {
    _logoutListeners.remove(listener);
  }
  
  // Set the logout callback (for backwards compatibility)
  void setLogoutCallback(void Function(String) callback) {
    // Clear existing listeners to maintain old behavior
    _logoutListeners.clear();
    _logoutListeners.add(callback);
  }
  
  // Get device ID
  Future<String> _getDeviceId() async {
    if (_deviceId != null) {
      return _deviceId!;
    }
    
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      _deviceId = windowsInfo.deviceId;
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      _deviceId = linuxInfo.machineId ?? linuxInfo.id;
    } else if (Platform.isMacOS) {
      final macOsInfo = await deviceInfo.macOsInfo;
      _deviceId = macOsInfo.systemGUID ?? macOsInfo.computerName;
    } else {
      // Fallback
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    return _deviceId!;
  }
  
  // Get platform type
  String _getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else {
      return 'windows'; // Default fallback
    }
  }
  
  // Generate HMAC signature for API requests
  String _generateSignature(String timestamp, String method, String path, String body) {
    final message = '$timestamp$method$path$body';
    final hmacSha256 = Hmac(sha256, utf8.encode(apiSecret));
    final digest = hmacSha256.convert(utf8.encode(message));
    return digest.toString();
  }
  
  // Login with license key
  Future<Map<String, dynamic>> login(String licenseKey) async {
    try {
      _licenseKey = licenseKey;
      final deviceId = await _getDeviceId();
      final platform = _getPlatform();
      
      // Prepare request
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final body = jsonEncode({
        'device_id': deviceId,
        'platform': platform,
      });
      
      final path = '/device/register';
      final signature = _generateSignature(timestamp, 'POST', path, body);
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl$path?license_key=$licenseKey'),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
            'X-API-Signature': signature,
            'X-Timestamp': timestamp,
          },
          body: body,
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode != 200) {
          commonPrint.log('Login failed with status: ${response.statusCode}');
          commonPrint.log('Response: ${response.body}');
          
          return {
            'status': 'error',
            'message': _parseErrorMessage(response.body) ?? 'Login failed. Please check your license key.',
          };
        }
        
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success') {
          // Save session token but not to file
          _sessionToken = responseData['session_token'];
          _licenseKey = licenseKey;
          
          // Save login state AND license key
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('license_key', licenseKey);
          
          // Connect to WebSocket for real-time updates
          _connectWebSocket();
          
          return responseData;
        } else {
          return {
            'status': 'error',
            'message': responseData['message'] ?? 'Unknown error',
          };
        }
      } on http.ClientException catch (e) {
        commonPrint.log('API connection error: $e');
        return {
          'status': 'error',
          'message': 'Server is down. Please try again later.',
        };
      } on TimeoutException catch (_) {
        commonPrint.log('API connection timeout');
        return {
          'status': 'error',
          'message': 'Server is down or not responding. Please try again later.',
        };
      } on SocketException catch (_) {
        commonPrint.log('API socket error - server unreachable');
        return {
          'status': 'error',
          'message': 'Server is down or unreachable. Please check your internet connection.',
        };
      }
    } catch (e) {
      commonPrint.log('Login error: $e');
      return {
        'status': 'error',
        'message': 'Connection error. Please check your internet connection.',
      };
    }
  }
  
  // Parse error message from response
  String? _parseErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['message'] ?? data['detail'];
    } catch (e) {
      return null;
    }
  }
  
  // Connect to WebSocket for real-time updates
  void _connectWebSocket() {
    if (_licenseKey == null || _deviceId == null) {
      commonPrint.log('Cannot connect to WebSocket: Missing license key or device ID');
      return;
    }
    
    try {
      final wsUri = Uri.parse('$wsUrl/ws/$_licenseKey/$_deviceId');
      commonPrint.log('Connecting to WebSocket: $wsUri');
      
      _webSocketChannel = WebSocketChannel.connect(wsUri);
      
      // Listen for messages
      _webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          commonPrint.log('WebSocket error: $error');
          _handleWebSocketReconnect();
        },
        onDone: () {
          commonPrint.log('WebSocket connection closed');
          _handleWebSocketReconnect();
        },
      );
      
      // Set up ping response timer
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _sendPong(),
      );
      
      // Set initial ping time so we can detect if pings stop
      _lastPingTime = DateTime.now();
      
      // Add ping checker to detect silent disconnections
      _pingChecker?.cancel();
      _pingChecker = Timer.periodic(const Duration(seconds: 30), (_) {
        final now = DateTime.now();
        final timeSinceLastPing = _lastPingTime != null ? 
          now.difference(_lastPingTime!) : const Duration(seconds: 0);
          
        if (_lastPingTime != null && timeSinceLastPing.inSeconds > 60) {
          commonPrint.log('No ping received in ${timeSinceLastPing.inSeconds} seconds, connection likely lost');
          _handleWebSocketReconnect();
        }
      });
      
      // Start WebSocket keep-alive service for Android
      if (Platform.isAndroid) {
        final webSocketService = WebSocketService();
        webSocketService.startKeepAliveService();
      }
      
      // Send an initial pong to verify connection
      _sendPong();
    } catch (e) {
      commonPrint.log('WebSocket connection error: $e');
      _handleWebSocketReconnect();
    }
  }
  
  // Handle WebSocket reconnection
  void _handleWebSocketReconnect() {
    if (_isReconnecting) {
      commonPrint.log('Already handling a WebSocket disconnection');
      return;
    }
    
    commonPrint.log('WebSocket connection lost, handling reconnection');
    _isReconnecting = true;

    // Clean up existing connection
    if (_webSocketChannel != null) {
      try {
        _webSocketChannel?.sink.close();
      } catch (e) {
        commonPrint.log('Error closing WebSocket: $e');
      }
      _webSocketChannel = null;
    }
    
    // Cancel timers
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingChecker?.cancel();
    _pingChecker = null;
    
    // Trigger logout for UI update
    _triggerLogout('Connection to server lost');
    
    // Reset reconnecting flag
    Future.delayed(const Duration(seconds: 2), () {
      _isReconnecting = false;
    });
  }
  
  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final messageType = data['type'];
      
      commonPrint.log('Received WebSocket message of type: $messageType');
      
      switch (messageType) {
        case 'connected':
          commonPrint.log('WebSocket connected successfully');
          _lastPingTime = DateTime.now();
          break;
          
        case 'ping':
          _lastPingTime = DateTime.now();
          
          if (data.containsKey('license_status')) {
            _lastLicenseStatus = data['license_status'];
          }
          _sendPong();
          break;
          
        case 'license_status':
          _lastLicenseStatus = data;
          break;
          
        case 'license_expired':
          commonPrint.log('License expired: ${data['message']}');
          _triggerLogout(data['message'] ?? 'Your license has expired');
          break;
          
        default:
          commonPrint.log('Unknown message type: $messageType');
      }
    } catch (e) {
      commonPrint.log('Error handling WebSocket message: $e');
    }
  }
  
  // Send pong response to server ping
  void _sendPong() {
    if (_webSocketChannel != null) {
      try {
        _webSocketChannel!.sink.add(jsonEncode({'type': 'pong'}));
      } catch (e) {
        commonPrint.log('Error sending pong: $e');
        _handleWebSocketReconnect();
      }
    }
  }
  
  // Get the latest license status
  Map<String, dynamic>? getLicenseStatus() {
    return _lastLicenseStatus;
  }
  
  // Get license key
  String? getLicenseKey() {
    return _licenseKey;
  }
  
  // Explicitly request license status through WebSocket
  void requestLicenseStatus() {
    if (_webSocketChannel != null) {
      try {
        _webSocketChannel!.sink.add(jsonEncode({'type': 'check_license'}));
      } catch (e) {
        commonPrint.log('Error requesting license status: $e');
      }
    }
  }
  
  // Trigger logout and UI update
  void _triggerLogout(String reason) {
    commonPrint.log('Triggering logout: $reason');
    
    // Stop any running processes directly
    if (globalState.isStart) {
      commonPrint.log('ApiService: Stopping active processes during logout');
      
      // Force stop all operations, clear timers and state
      globalState.startTime = null;
      globalState.handleStop();
      
      // Make sure app controller state is updated too
      globalState.appController.updateStatus(false);
    }
    
    // Clean up connection and state
    _cleanupConnection();
    
    // Update SharedPreferences
    _updateLoginState(false);
    
    // Notify all listeners
    for (final listener in _logoutListeners) {
      try {
        listener(reason);
      } catch (e) {
        commonPrint.log('Error in logout listener: $e');
      }
    }
  }
  
  // Clean up WebSocket connection and state
  void _cleanupConnection() {
    // Cancel timers
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingChecker?.cancel();
    _pingChecker = null;
    
    // Close WebSocket
    if (_webSocketChannel != null) {
      try {
        _webSocketChannel?.sink.close();
      } catch (e) {
        commonPrint.log('Error closing WebSocket: $e');
      }
      _webSocketChannel = null;
    }
    
    // Stop WebSocket keep-alive service for Android
    if (Platform.isAndroid) {
      final webSocketService = WebSocketService();
      webSocketService.stopKeepAliveService();
    }
    
    // Clear session data
    _sessionToken = null;
  }
  
  // Update login state in SharedPreferences
  Future<void> _updateLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
      
      // If logging out, clear license key
      if (!isLoggedIn) {
        _licenseKey = null;
      }
    } catch (e) {
      commonPrint.log('Error updating login state: $e');
    }
  }
  
  // Manual logout
  Future<void> logout() async {
    commonPrint.log('Manual logout initiated');
    
    // Force stop all operations first
    if (globalState.isStart) {
      commonPrint.log('ApiService: Stopping active processes for manual logout');
      globalState.startTime = null;
      globalState.handleStop();
      globalState.appController.updateStatus(false);
    }
    
    // Clean up connection and session
    _cleanupConnection();
    
    // Update login state
    await _updateLoginState(false);
    
    // Clear license key
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('license_key');
    
    // Notify all listeners
    for (final listener in _logoutListeners) {
      try {
        listener('');
      } catch (e) {
        commonPrint.log('Error in logout listener: $e');
      }
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      commonPrint.log('Error checking login status: $e');
      return false;
    }
  }
  
  // Get stored license key
  Future<String?> getStoredLicenseKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('license_key');
    } catch (e) {
      commonPrint.log('Error retrieving stored license key: $e');
      return null;
    }
  }
  
  // Auto-login on app start
  Future<bool> autoLogin() async {
    try {
      // Check if already logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (!isLoggedIn) {
        commonPrint.log('Not logged in, skipping auto-login');
        return false;
      }
      
      // Try to get stored license key
      final licenseKey = prefs.getString('license_key');
      if (licenseKey == null || licenseKey.isEmpty) {
        commonPrint.log('No license key stored, cannot auto-login');
        await _updateLoginState(false); // Clear invalid login state
        return false;
      }
      
      commonPrint.log('Attempting auto-login with stored license key');
      
      // Perform full login process with the stored license key
      final result = await login(licenseKey);
      
      if (result['status'] == 'success') {
        commonPrint.log('Auto-login successful');
        return true;
      } else {
        commonPrint.log('Auto-login failed: ${result['message']}');
        // Clear login state since validation failed
        await _updateLoginState(false);
        return false;
      }
    } catch (e) {
      commonPrint.log('Auto-login error: $e');
      // Clear login state on error
      await _updateLoginState(false);
      return false;
    }
  }
  
  // Check if WebSocket connection is active, reconnect or logout if not
  void checkConnection() {
    // If no license key, we're not logged in
    if (_licenseKey == null) {
      return;
    }
    
    // If WebSocket is null, but we have a license key, we should be connected
    if (_webSocketChannel == null) {
      commonPrint.log('WebSocket connection check failed - no active connection');
      
      // Try to reconnect once
      try {
        _connectWebSocket();
        
        // Wait a moment and verify connection was established
        Future.delayed(const Duration(seconds: 2), () {
          if (_webSocketChannel == null) {
            commonPrint.log('WebSocket reconnection failed - logging out');
            _triggerLogout('Connection to server lost');
          } else {
            commonPrint.log('WebSocket reconnection successful');
          }
        });
      } catch (e) {
        commonPrint.log('Error reconnecting WebSocket: $e');
        _triggerLogout('Connection to server lost');
      }
      return;
    }
    
    // If last ping was too long ago, connection might be stale
    final now = DateTime.now();
    final timeSinceLastPing = _lastPingTime != null ? 
      now.difference(_lastPingTime!) : const Duration(seconds: 0);
      
    if (_lastPingTime != null && timeSinceLastPing.inSeconds > 60) {
      commonPrint.log('Last ping was ${timeSinceLastPing.inSeconds} seconds ago - connection likely lost');
      
      // Close existing connection and try to reconnect
      try {
        _webSocketChannel?.sink.close();
        _webSocketChannel = null;
        
        // Try to reconnect
        _connectWebSocket();
        
        // Verify connection after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_webSocketChannel == null) {
            _triggerLogout('Connection to server lost');
          }
        });
      } catch (e) {
        commonPrint.log('Error handling stale connection: $e');
        _triggerLogout('Connection to server lost');
      }
      return;
    }
    
    // If we have an active connection, send a ping to verify it's responsive
    try {
      _sendPong();
    } catch (e) {
      commonPrint.log('Error sending ping to check connection: $e');
      _handleWebSocketReconnect();
    }
  }
  
  // Check if WebSocket is connected
  bool isWebSocketConnected() {
    if (_webSocketChannel == null || _licenseKey == null) {
      return false;
    }
    
    // If last ping was too long ago, consider connection lost
    if (_lastPingTime != null) {
      final now = DateTime.now();
      final timeSinceLastPing = now.difference(_lastPingTime!);
      if (timeSinceLastPing.inSeconds > 60) {
        return false;
      }
    }
    
    return true;
  }
}
