import 'dart:async';
import 'package:errorx/common/secure_memory_service.dart';
import 'package:errorx/common/encryption_service.dart';
import 'package:errorx/clash/clash.dart';
import 'package:flutter/services.dart';

/// Manager for secure memory operations and lifecycle management
class SecureMemoryManager {
  static SecureMemoryManager? _instance;
  Timer? _cleanupTimer;
  
  SecureMemoryManager._();
  
  static SecureMemoryManager get instance {
    _instance ??= SecureMemoryManager._();
    return _instance!;
  }
  
  /// Initialize secure memory system
  void initialize() {
    // Start periodic cleanup of expired entries
    startPeriodicCleanup();
    
    // Set up app lifecycle monitoring
    _setupAppLifecycleHandlers();
  }
  
  /// Start periodic cleanup of expired cache entries
  void startPeriodicCleanup({int intervalMinutes = 10, int maxAgeMinutes = 30}) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => SecureMemoryService.cleanupExpiredEntries(maxAgeMinutes: maxAgeMinutes),
    );
  }
  
  /// Stop periodic cleanup
  void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
  
  /// Set up app lifecycle handlers for security
  void _setupAppLifecycleHandlers() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      switch (message) {
        case 'AppLifecycleState.paused':
        case 'AppLifecycleState.inactive':
          // Clear all insecure cached data when app goes to background
          await onAppPaused();
          break;
        case 'AppLifecycleState.resumed':
          // App resumed - could refresh security if needed
          await onAppResumed();
          break;
        case 'AppLifecycleState.detached':
          // App is being terminated
          await onAppTerminated();
          break;
      }
      return null;
    });
  }
  
  /// Handle app pause/background events
  Future<void> onAppPaused() async {
    try {
      // Clear any insecure cached data
      EncryptionService.clearInsecureCache();
      
      // Optionally clear secure cache for maximum security
      // SecureMemoryService.clearAllSecureCache();
      
      print('SecureMemoryManager: Cleared insecure cache on app pause');
    } catch (e) {
      print('SecureMemoryManager: Error during app pause cleanup: $e');
    }
  }
  
  /// Handle app resume events
  Future<void> onAppResumed() async {
    try {
      // Could trigger re-validation or refresh of profiles if needed
      print('SecureMemoryManager: App resumed');
    } catch (e) {
      print('SecureMemoryManager: Error during app resume: $e');
    }
  }
  
  /// Handle app termination
  Future<void> onAppTerminated() async {
    try {
      // Clear all cached data
      EncryptionService.clearInsecureCache();
      SecureMemoryService.clearAllSecureCache();
      stopPeriodicCleanup();
      
      print('SecureMemoryManager: Cleared all caches on app termination');
    } catch (e) {
      print('SecureMemoryManager: Error during app termination cleanup: $e');
    }
  }
  
  /// Validate profile securely without storing readable content in memory
  Future<String> validateProfileSecurely(String profileId) async {
    try {
      return await SecureMemoryService.withSecureProfile(profileId, (yamlContent) async {
        // Validate the configuration using clash core
        return await clashCore.validateConfig(yamlContent);
      });
    } catch (e) {
      return 'Validation error: $e';
    }
  }
  
  /// Process profile content securely for any operation
  Future<T> processProfileSecurely<T>(
    String profileId,
    Future<T> Function(String yamlContent) processor,
  ) async {
    return await SecureMemoryService.withSecureProfile(profileId, processor);
  }
  
  /// Get profile statistics without exposing content
  Future<Map<String, dynamic>> getProfileStats(String profileId) async {
    return await SecureMemoryService.withSecureProfile(profileId, (yamlContent) async {
      final lines = yamlContent.split('\n');
      final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).length;
      final proxyCount = lines.where((line) => line.trim().startsWith('- name:')).length;
      
      return {
        'totalLines': lines.length,
        'contentLines': nonEmptyLines,
        'estimatedProxies': proxyCount,
        'sizeBytes': yamlContent.length,
      };
    });
  }
  
  /// Force cleanup of all cached data (emergency security measure)
  void emergencyCleanup() {
    try {
      EncryptionService.clearInsecureCache();
      SecureMemoryService.clearAllSecureCache();
      print('SecureMemoryManager: Emergency cleanup completed');
    } catch (e) {
      print('SecureMemoryManager: Error during emergency cleanup: $e');
    }
  }
  
  /// Check system memory pressure and cleanup if needed
  void checkMemoryPressure() {
    // This could be enhanced with platform-specific memory monitoring
    // For now, just do a periodic cleanup
    SecureMemoryService.cleanupExpiredEntries(maxAgeMinutes: 15);
  }
  
  /// Dispose of the manager
  void dispose() {
    stopPeriodicCleanup();
    emergencyCleanup();
    _instance = null;
  }
} 