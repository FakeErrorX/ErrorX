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

// Enhanced logout listener class with metadata
class LogoutListener {
  final String id;
  final void Function(String) callback;
  final int priority;
  final bool runOnce;
  final DateTime createdAt;
  bool hasRun = false;
  
  LogoutListener({
    required this.id,
    required this.callback,
    this.priority = 0,
    this.runOnce = false,
  }) : createdAt = DateTime.now();
  
  @override
  String toString() {
    return 'LogoutListener(id: $id, priority: $priority, runOnce: $runOnce, hasRun: $hasRun)';
  }
}

// Logout event details
class LogoutEvent {
  final String reason;
  final LogoutType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  LogoutEvent({
    required this.reason,
    required this.type,
    Map<String, dynamic>? metadata,
  }) : timestamp = DateTime.now(),
       metadata = metadata ?? {};
       
  @override
  String toString() {
    return 'LogoutEvent(reason: $reason, type: $type, timestamp: $timestamp)';
  }
}

// Types of logout events
enum LogoutType {
  manual,           // User initiated logout
  sessionExpired,   // License/session expired
  connectionLost,   // WebSocket connection lost
  networkChanged,   // Network change triggered logout
  error,           // Error-based logout
  forced,          // Forced logout by system
}

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
  
  // Network change handling
  Timer? _networkChangeDebouncer;
  bool _isHandlingNetworkChange = false;
  
  // Enhanced logout listener system
  final List<LogoutListener> _logoutListeners = [];
  bool _isLoggingOut = false;
  
  // Getters for internal state (needed by WebSocket service)
  String? get licenseKey => _licenseKey;
  bool get isReconnecting => _isReconnecting;
  bool get isLoggingOut => _isLoggingOut;
  
  // Public method to trigger WebSocket connection (for external services)
  void connectWebSocket() {
    _connectWebSocket();
  }
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Add a logout listener with priority and metadata
  void addLogoutListener(
    void Function(String) listener, {
    String? id,
    int priority = 0,
    bool runOnce = false,
  }) {
    final logoutListener = LogoutListener(
      id: id ?? 'listener_${DateTime.now().millisecondsSinceEpoch}',
      callback: listener,
      priority: priority,
      runOnce: runOnce,
    );
    
    // Check if listener with same ID already exists
    _logoutListeners.removeWhere((l) => l.id == logoutListener.id);
    
    // Insert based on priority (higher priority first)
    _logoutListeners.add(logoutListener);
    _logoutListeners.sort((a, b) => b.priority.compareTo(a.priority));
    
    commonPrint.log('Added logout listener: ${logoutListener.id} (priority: ${logoutListener.priority})');
  }
  
  // Remove a logout listener by callback or ID
  void removeLogoutListener(dynamic identifier) {
    if (identifier is String) {
      // Remove by ID
      final initialCount = _logoutListeners.length;
      _logoutListeners.removeWhere((l) => l.id == identifier);
      if (_logoutListeners.length < initialCount) {
        commonPrint.log('Removed logout listener by ID: $identifier');
      }
    } else if (identifier is Function) {
      // Remove by callback function
      final initialCount = _logoutListeners.length;
      _logoutListeners.removeWhere((l) => l.callback == identifier);
      if (_logoutListeners.length < initialCount) {
        commonPrint.log('Removed logout listener by callback');
      }
    }
  }
  
  // Clear all logout listeners
  void clearLogoutListeners() {
    final count = _logoutListeners.length;
    _logoutListeners.clear();
    commonPrint.log('Cleared $count logout listeners');
  }
  
  // Set the logout callback (for backwards compatibility)
  void setLogoutCallback(void Function(String) callback) {
    // Clear existing listeners to maintain old behavior
    clearLogoutListeners();
    addLogoutListener(callback, id: 'legacy_callback', priority: 100);
  }
  
  // Get current logout listeners count
  int get logoutListenersCount => _logoutListeners.length;
  
  // Get logout listener details for debugging
  List<String> getLogoutListenerInfo() {
    return _logoutListeners.map((l) => l.toString()).toList();
  }
  
  // Get connection status details
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': isWebSocketConnected(),
      'isReconnecting': _isReconnecting,
      'isLoggingOut': _isLoggingOut,
      'licenseKeyPresent': _licenseKey != null,
      'lastPingTime': _lastPingTime?.toIso8601String(),
      'sessionToken': _sessionToken != null,
      'logoutListenersCount': logoutListenersCount,
    };
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
      
      // Set up ping response timer - more frequent pings
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        const Duration(seconds: 15), // Reduced from 20 seconds for better connection detection
        (_) => _sendPong(),
      );
      
      // Set initial ping time so we can detect if pings stop
      _lastPingTime = DateTime.now();
      
      // Add ping checker to detect silent disconnections - more sensitive
      _pingChecker?.cancel();
      _pingChecker = Timer.periodic(const Duration(seconds: 20), (_) { // Reduced from 30 seconds
        final now = DateTime.now();
        final timeSinceLastPing = _lastPingTime != null ? 
          now.difference(_lastPingTime!) : const Duration(seconds: 0);
          
        if (_lastPingTime != null && timeSinceLastPing.inSeconds > 45) { // Reduced from 60 seconds
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
    _triggerLogout('Connection to server lost', type: LogoutType.connectionLost);
    
    // Reset reconnecting flag
    Future.delayed(const Duration(seconds: 2), () {
      _isReconnecting = false;
    });
  }
  
  // Handle network changes (called when VPN connects/disconnects)
  void handleNetworkChange(Map<String, dynamic> networkInfo) {
    if (_isHandlingNetworkChange) {
      return;
    }
    
    final type = networkInfo['type'] as String?;
    final hasVpn = networkInfo['hasVpn'] as bool? ?? false;
    
    commonPrint.log('Network change detected: $type, hasVpn: $hasVpn');
    
    // Only handle VPN-related network changes or significant connectivity changes
    if (type == 'vpn_changed' || type == 'link_changed') {
      _isHandlingNetworkChange = true;
      
      // Debounce network change handling to avoid rapid reconnections
      _networkChangeDebouncer?.cancel();
      _networkChangeDebouncer = Timer(const Duration(seconds: 2), () {
        _handleNetworkChangeReconnection();
      });
    }
  }
  
  // Handle WebSocket reconnection due to network changes
  void _handleNetworkChangeReconnection() {
    _isHandlingNetworkChange = false;
    
    if (_licenseKey == null) {
      return; // Not logged in
    }
    
    commonPrint.log('Handling WebSocket reconnection due to network change');
    
    // Close existing connection if it exists
    if (_webSocketChannel != null) {
      try {
        _webSocketChannel?.sink.close();
      } catch (e) {
        commonPrint.log('Error closing existing WebSocket: $e');
      }
      _webSocketChannel = null;
    }
    
    // Cancel existing timers
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingChecker?.cancel();
    _pingChecker = null;
    
    // Wait a moment before reconnecting to allow network to stabilize
    Future.delayed(const Duration(seconds: 1), () {
      if (_licenseKey != null) {
        commonPrint.log('Attempting WebSocket reconnection after network change');
        _connectWebSocket();
        
        // Verify connection after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (_webSocketChannel == null && _licenseKey != null) {
            commonPrint.log('WebSocket reconnection failed after network change');
            // Don't trigger logout immediately for network changes, give it more time
            Future.delayed(const Duration(seconds: 5), () {
              if (_webSocketChannel == null && _licenseKey != null) {
                _triggerLogout('Connection to server lost after network change', type: LogoutType.networkChanged);
              }
            });
          } else {
            commonPrint.log('WebSocket reconnection successful after network change');
          }
        });
      }
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
          _triggerLogout(data['message'] ?? 'Your license has expired', type: LogoutType.sessionExpired);
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
  
  // Enhanced logout trigger with detailed event handling
  void _triggerLogout(String reason, {LogoutType? type, Map<String, dynamic>? metadata}) {
    // Prevent multiple simultaneous logout operations
    if (_isLoggingOut) {
      commonPrint.log('Logout already in progress, ignoring: $reason');
      return;
    }
    
    _isLoggingOut = true;
    commonPrint.log('Triggering logout: $reason (type: ${type ?? LogoutType.connectionLost})');
    
    try {
      // Create logout event
      final logoutEvent = LogoutEvent(
        reason: reason,
        type: type ?? _determineLogoutType(reason),
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'wasStart': globalState.isStart,
          'licenseKey': _licenseKey?.substring(0, 8) ?? 'none', // Only log first 8 chars for privacy
          'webSocketConnected': _webSocketChannel != null,
          ...?metadata,
        },
      );
      
      // Stop any running processes directly
      if (globalState.isStart) {
        commonPrint.log('ApiService: Stopping active processes during logout (${logoutEvent.type})');
        
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
      
      // Execute logout listeners in priority order with error handling
      _executeLogoutListeners(logoutEvent);
      
    } catch (e) {
      commonPrint.log('Error during logout process: $e');
    } finally {
      // Reset logout flag after a brief delay to prevent rapid re-triggers
      Future.delayed(const Duration(milliseconds: 500), () {
        _isLoggingOut = false;
      });
    }
  }
  
  // Determine logout type based on reason
  LogoutType _determineLogoutType(String reason) {
    final lowerReason = reason.toLowerCase();
    
    if (lowerReason.contains('expire')) {
      return LogoutType.sessionExpired;
    } else if (lowerReason.contains('network') || lowerReason.contains('vpn')) {
      return LogoutType.networkChanged;
    } else if (lowerReason.contains('connection') || lowerReason.contains('websocket')) {
      return LogoutType.connectionLost;
    } else if (lowerReason.contains('error')) {
      return LogoutType.error;
    } else if (lowerReason.isEmpty) {
      return LogoutType.manual;
    } else {
      return LogoutType.forced;
    }
  }
  
  // Execute logout listeners with enhanced error handling and metrics
  void _executeLogoutListeners(LogoutEvent event) {
    if (_logoutListeners.isEmpty) {
      commonPrint.log('No logout listeners to execute');
      return;
    }
    
    final startTime = DateTime.now();
    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];
    
    commonPrint.log('Executing ${_logoutListeners.length} logout listeners for event: ${event.type}');
    
    // Create a copy to avoid concurrent modification
    final listenersToExecute = List<LogoutListener>.from(_logoutListeners);
    
    for (final listener in listenersToExecute) {
      try {
        // Skip if already run and marked as runOnce
        if (listener.runOnce && listener.hasRun) {
          commonPrint.log('Skipping runOnce listener ${listener.id} (already executed)');
          continue;
        }
        
        // Execute listener with timeout protection
        final stopwatch = Stopwatch()..start();
        
        listener.callback(event.reason);
        listener.hasRun = true;
        
        stopwatch.stop();
        successCount++;
        
        if (stopwatch.elapsedMilliseconds > 1000) {
          commonPrint.log('Warning: Logout listener ${listener.id} took ${stopwatch.elapsedMilliseconds}ms');
        }
        
      } catch (e) {
        errorCount++;
        final errorMsg = 'Error in logout listener ${listener.id}: $e';
        errors.add(errorMsg);
        commonPrint.log(errorMsg);
      }
    }
    
    // Remove runOnce listeners that have been executed
    _logoutListeners.removeWhere((l) => l.runOnce && l.hasRun);
    
    final executionTime = DateTime.now().difference(startTime);
    commonPrint.log(
      'Logout listeners execution completed: '
      '$successCount successful, $errorCount errors, '
      'took ${executionTime.inMilliseconds}ms'
    );
    
    if (errors.isNotEmpty) {
      commonPrint.log('Logout listener errors: ${errors.join('; ')}');
    }
  }
  
  // Clean up WebSocket connection and state
  void _cleanupConnection() {
    // Cancel timers
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingChecker?.cancel();
    _pingChecker = null;
    _networkChangeDebouncer?.cancel();
    _networkChangeDebouncer = null;
    
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
  
  // Enhanced manual logout with better user experience
  Future<void> logout({String? reason, Map<String, dynamic>? metadata}) async {
    final logoutReason = reason ?? 'User requested logout';
    commonPrint.log('Manual logout initiated: $logoutReason');
    
    // Prevent multiple logout calls
    if (_isLoggingOut) {
      commonPrint.log('Logout already in progress, ignoring manual logout request');
      return;
    }
    
    try {
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
      
      // Clear license key from preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('license_key');
      
      // Create enhanced logout event for manual logout
      final logoutEvent = LogoutEvent(
        reason: logoutReason,
        type: LogoutType.manual,
        metadata: {
          'userInitiated': true,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      // Execute logout listeners
      _executeLogoutListeners(logoutEvent);
      
      commonPrint.log('Manual logout completed successfully');
      
    } catch (e) {
      commonPrint.log('Error during manual logout: $e');
      // Still try to trigger basic logout on error
      _triggerLogout(logoutReason, type: LogoutType.error, metadata: {'error': e.toString()});
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
            _triggerLogout('Connection to server lost', type: LogoutType.connectionLost);
          } else {
            commonPrint.log('WebSocket reconnection successful');
          }
        });
      } catch (e) {
        commonPrint.log('Error reconnecting WebSocket: $e');
        _triggerLogout('Connection to server lost', type: LogoutType.connectionLost);
      }
      return;
    }
    
    // If last ping was too long ago, connection might be stale
    final now = DateTime.now();
    final timeSinceLastPing = _lastPingTime != null ? 
      now.difference(_lastPingTime!) : const Duration(seconds: 0);
      
    if (_lastPingTime != null && timeSinceLastPing.inSeconds > 45) { // Reduced from 60 seconds
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
            _triggerLogout('Connection to server lost', type: LogoutType.connectionLost);
          }
        });
      } catch (e) {
        commonPrint.log('Error handling stale connection: $e');
        _triggerLogout('Connection to server lost', type: LogoutType.connectionLost);
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
