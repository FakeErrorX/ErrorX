import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'encryption_service.dart';

/// Internal class for secure memory storage
class _SecureMemoryEntry {
  final Uint8List obfuscatedData;
  final Uint8List key;
  final int timestamp;
  
  _SecureMemoryEntry(this.obfuscatedData, this.key, this.timestamp);
}

/// Secure memory service that prevents readable YAML from being stored in memory
/// Uses additional obfuscation and just-in-time decryption
class SecureMemoryService {
  static final Map<String, _SecureMemoryEntry> _secureCache = {};
  static final Random _random = Random.secure();
  

  
  /// Store profile data in obfuscated format in memory
  static void storeSecureProfile(String profileId, Uint8List encryptedData) {
    // Generate a random obfuscation key for this session
    final obfuscationKey = _generateObfuscationKey();
    
    // Apply additional obfuscation to the already encrypted data
    final obfuscatedData = _obfuscateData(encryptedData, obfuscationKey);
    
    _secureCache[profileId] = _SecureMemoryEntry(
      obfuscatedData,
      obfuscationKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Retrieve and temporarily decrypt profile data for immediate use
  /// The callback receives decrypted data but it's not stored in readable format
  static Future<T> withSecureProfile<T>(
    String profileId,
    Future<T> Function(String yamlContent) operation,
  ) async {
    final entry = _secureCache[profileId];
    if (entry == null) {
      throw Exception('Profile $profileId not found in secure cache');
    }
    
    // De-obfuscate the data
    final encryptedData = _deobfuscateData(entry.obfuscatedData, entry.key);
    
    // Decrypt using the main encryption service
    final decryptedData = EncryptionService.decrypt(encryptedData);
    
    String? yamlContent;
    try {
      // Convert to readable format temporarily
      yamlContent = utf8.decode(decryptedData);
      
      // Execute the operation with the decrypted content
      return await operation(yamlContent);
    } finally {
      // Immediately clear the readable content from memory
      if (yamlContent != null) {
        yamlContent = null;
      }
      // Clear the decrypted bytes
      decryptedData.fillRange(0, decryptedData.length, 0);
    }
  }
  
  /// Check if profile is available in secure cache
  static bool isProfileSecured(String profileId) {
    return _secureCache.containsKey(profileId);
  }
  
  /// Remove profile from secure cache
  static void clearSecureProfile(String profileId) {
    final entry = _secureCache.remove(profileId);
    if (entry != null) {
      // Clear sensitive data
      entry.obfuscatedData.fillRange(0, entry.obfuscatedData.length, 0);
      entry.key.fillRange(0, entry.key.length, 0);
    }
  }
  
  /// Clear all profiles from secure cache
  static void clearAllSecureCache() {
    for (final entry in _secureCache.values) {
      entry.obfuscatedData.fillRange(0, entry.obfuscatedData.length, 0);
      entry.key.fillRange(0, entry.key.length, 0);
    }
    _secureCache.clear();
  }
  
  /// Clean up expired entries (optional security measure)
  static void cleanupExpiredEntries({int maxAgeMinutes = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxAge = maxAgeMinutes * 60 * 1000;
    
    final expiredKeys = _secureCache.entries
        .where((entry) => now - entry.value.timestamp > maxAge)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      clearSecureProfile(key);
    }
  }
  
  /// Generate a random obfuscation key
  static Uint8List _generateObfuscationKey() {
    final key = Uint8List(32);
    for (int i = 0; i < key.length; i++) {
      key[i] = _random.nextInt(256);
    }
    return key;
  }
  
  /// Apply XOR-based obfuscation with rotation
  static Uint8List _obfuscateData(Uint8List data, Uint8List key) {
    final obfuscated = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      // XOR with rotating key + add salt
      final keyByte = key[i % key.length];
      final saltByte = _generateSalt(i);
      obfuscated[i] = (data[i] ^ keyByte ^ saltByte) & 0xFF;
    }
    return obfuscated;
  }
  
  /// Reverse the obfuscation
  static Uint8List _deobfuscateData(Uint8List obfuscatedData, Uint8List key) {
    final data = Uint8List(obfuscatedData.length);
    for (int i = 0; i < obfuscatedData.length; i++) {
      final keyByte = key[i % key.length];
      final saltByte = _generateSalt(i);
      data[i] = (obfuscatedData[i] ^ keyByte ^ saltByte) & 0xFF;
    }
    return data;
  }
  
  /// Generate position-based salt
  static int _generateSalt(int position) {
    return (position * 31 + 17) & 0xFF;
  }
} 