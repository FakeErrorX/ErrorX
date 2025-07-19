import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:errorx/clash/clash.dart';
import 'package:errorx/services/secrets.dart'; // Import secrets

class EncryptionService {
  // Using the centralized encryption key from secrets.dart
  // Application-specific encryption key for AES-256
  static const String _secretKeyString = encryptionSecretKey;
  
  // Header to identify encrypted files (custom magic bytes)
  static final List<int> _encryptionHeader = [0xEE, 0xCC, 0x55, 0x88];
  
  // In-memory cache for decrypted profile data
  static final Map<String, Uint8List> _decryptedCache = {};
  
  // Track if Go encryption has been initialized
  static bool _goEncryptionInitialized = false;
  
  // Initialize encryption in the Go core
  static Future<bool> initializeGoEncryption() async {
    try {
      return await clashCore.initEncryption(_secretKeyString);
    } catch (e) {
      return false;
    }
  }
  
  // Check if Go encryption is initialized
  static bool get isGoEncryptionInitialized => _goEncryptionInitialized;
  
  // Mark Go encryption as initialized
  static void markGoEncryptionInitialized() {
    _goEncryptionInitialized = true;
  }
  
  // Get the encryption key
  static Key _getKey() {
    // Use only the first 32 bytes of the key string (for AES-256)
    final keyBytes = utf8.encode(_secretKeyString).sublist(0, 32);
    return Key(Uint8List.fromList(keyBytes));
  }
  
  // Check if data has the encryption header
  static bool hasEncryptionHeader(Uint8List data) {
    if (data.length < _encryptionHeader.length) return false;
    
    for (int i = 0; i < _encryptionHeader.length; i++) {
      if (data[i] != _encryptionHeader[i]) return false;
    }
    
    return true;
  }
  
  // Encrypt data using AES-256 in CBC mode
  static Uint8List encrypt(Uint8List data) {
    // If data is already encrypted, return as is
    if (hasEncryptionHeader(data)) {
      return data;
    }
    
    final key = _getKey();
    final iv = IV.fromSecureRandom(16); // Random IV for each encryption
    
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // Combine header, IV, and encrypted data
    final result = BytesBuilder();
    result.add(_encryptionHeader);
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    
    return result.toBytes();
  }
  
  // Decrypt data
  static Uint8List decrypt(Uint8List encryptedData) {
    // Check if data has encryption header
    if (!hasEncryptionHeader(encryptedData)) {
      // Not encrypted, return as is (for backward compatibility)
      return encryptedData;
    }
    
    // Extract IV and encrypted content
    final headerSize = _encryptionHeader.length;
    final iv = IV(encryptedData.sublist(headerSize, headerSize + 16));
    final encryptedBytes = encryptedData.sublist(headerSize + 16);
    
    // Decrypt
    final key = _getKey();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decryptBytes(
      Encrypted(encryptedBytes),
      iv: iv
    );
    
    return Uint8List.fromList(decrypted);
  }
  
  // Helper method to encrypt a string
  static Uint8List encryptString(String data) {
    return encrypt(Uint8List.fromList(utf8.encode(data)));
  }
  
  // Helper method to decrypt to a string
  static String decryptToString(Uint8List encryptedData) {
    return utf8.decode(decrypt(encryptedData));
  }
  
  // DEPRECATED: Cache methods for in-memory profile storage
  // These methods store readable data in memory and should be avoided
  // Use SecureMemoryService instead for better security
  
  // Store decrypted profile data in the memory cache
  @Deprecated('Use SecureMemoryService.storeSecureProfile instead - this stores readable data in memory')
  static void cacheDecryptedProfile(String profileId, Uint8List decryptedData) {
    _decryptedCache[profileId] = decryptedData;
  }
  
  // Get cached decrypted profile data, or null if not in cache
  @Deprecated('Use SecureMemoryService.withSecureProfile instead - this exposes readable data')
  static Uint8List? getCachedProfile(String profileId) {
    return _decryptedCache[profileId];
  }
  
  // Check if a profile is cached
  @Deprecated('Use SecureMemoryService.isProfileSecured instead')
  static bool isProfileCached(String profileId) {
    return _decryptedCache.containsKey(profileId);
  }
  
  // Clear a specific profile from cache
  @Deprecated('Use SecureMemoryService.clearSecureProfile instead')
  static void clearProfileCache(String profileId) {
    _decryptedCache.remove(profileId);
  }
  
  // Clear all profiles from cache
  @Deprecated('Use SecureMemoryService.clearAllSecureCache instead')
  static void clearAllCache() {
    _decryptedCache.clear();
  }
  
  // Helper for reading and caching profile data - returns decrypted bytes
  @Deprecated('Use SecureMemoryService.withSecureProfile instead - this exposes readable data')
  static Future<Uint8List> decryptAndCacheProfile(String profileId, Uint8List encryptedData) {
    // Decrypt the data
    final decryptedData = decrypt(encryptedData);
    
    // Cache the decrypted data
    cacheDecryptedProfile(profileId, decryptedData);
    
    return Future.value(decryptedData);
  }

  // SECURITY: Clear all readable cache on app pause/background
  static void clearInsecureCache() {
    _decryptedCache.clear();
  }
} 