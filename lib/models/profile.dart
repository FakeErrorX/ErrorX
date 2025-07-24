// ignore_for_file: invalid_annotation_target
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/common/encryption_service.dart';
import 'package:errorx/common/secure_memory_service.dart';
import 'package:errorx/enum/enum.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'clash_config.dart';

part 'generated/profile.freezed.dart';

part 'generated/profile.g.dart';

typedef SelectedMap = Map<String, String>;

@freezed
class SubscriptionInfo with _$SubscriptionInfo {
  const factory SubscriptionInfo({
    @Default(0) int upload,
    @Default(0) int download,
    @Default(0) int total,
    @Default(0) int expire,
  }) = _SubscriptionInfo;

  factory SubscriptionInfo.fromJson(Map<String, Object?> json) =>
      _$SubscriptionInfoFromJson(json);

  factory SubscriptionInfo.formHString(String? info) {
    if (info == null) return const SubscriptionInfo();
    final list = info.split(";");
    Map<String, int?> map = {};
    for (final i in list) {
      final keyValue = i.trim().split("=");
      map[keyValue[0]] = int.tryParse(keyValue[1]);
    }
    return SubscriptionInfo(
      upload: map["upload"] ?? 0,
      download: map["download"] ?? 0,
      total: map["total"] ?? 0,
      expire: map["expire"] ?? 0,
    );
  }
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? label,
    String? currentGroupName,
    @Default("") String url,
    DateTime? lastUpdateDate,
    required Duration autoUpdateDuration,
    SubscriptionInfo? subscriptionInfo,
    @Default(true) bool autoUpdate,
    @Default({}) SelectedMap selectedMap,
    @Default({}) Set<String> unfoldSet,
    @Default(OverrideData()) OverrideData overrideData,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default(false)
    bool isUpdating,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);

  factory Profile.normal({
    String? label,
    String url = '',
  }) {
    return Profile(
      label: label,
      url: url,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      autoUpdateDuration: defaultUpdateDuration,
    );
  }

  /// Ensures that the Go core is initialized with encryption capability
  /// This eliminates the need for temporary decryption to disk
  static Future<void> ensureGoEncryptionInitialized() async {
    if (!EncryptionService.isGoEncryptionInitialized) {
      final success = await EncryptionService.initializeGoEncryption();
      if (!success) {
        throw Exception('Failed to initialize Go encryption service');
      }
      EncryptionService.markGoEncryptionInitialized();
    }
  }
}

@freezed
class OverrideData with _$OverrideData {
  const factory OverrideData({
    @Default(false) bool enable,
    @Default(OverrideRule()) OverrideRule rule,
  }) = _OverrideData;

  factory OverrideData.fromJson(Map<String, Object?> json) =>
      _$OverrideDataFromJson(json);
}

extension OverrideDataExt on OverrideData {
  List<String> get runningRule {
    if (!enable) {
      return [];
    }
    return rule.rules.map((item) => item.value).toList();
  }
}

@freezed
class OverrideRule with _$OverrideRule {
  const factory OverrideRule({
    @Default(OverrideRuleType.added) OverrideRuleType type,
    @Default([]) List<Rule> overrideRules,
    @Default([]) List<Rule> addedRules,
  }) = _OverrideRule;

  factory OverrideRule.fromJson(Map<String, Object?> json) =>
      _$OverrideRuleFromJson(json);
}

extension OverrideRuleExt on OverrideRule {
  List<Rule> get rules => switch (type == OverrideRuleType.override) {
        true => overrideRules,
        false => addedRules,
      };

  OverrideRule updateRules(List<Rule> Function(List<Rule> rules) builder) {
    if (type == OverrideRuleType.added) {
      return copyWith(addedRules: builder(addedRules));
    }
    return copyWith(overrideRules: builder(overrideRules));
  }
}

extension ProfilesExt on List<Profile> {
  Profile? getProfile(String? profileId) {
    final index = indexWhere((profile) => profile.id == profileId);
    return index == -1 ? null : this[index];
  }
}

extension ProfileExtension on Profile {
  ProfileType get type =>
      url.isEmpty == true ? ProfileType.file : ProfileType.url;

  bool get realAutoUpdate => url.isEmpty == true ? false : autoUpdate;

  Future<void> checkAndUpdate() async {
    final isExists = await check();
    if (!isExists) {
      if (url.isNotEmpty) {
        await update();
      }
    }
  }

  Future<bool> check() async {
    final profilePath = await appPath.getProfilePath(id);
    return await File(profilePath!).exists();
  }

  Future<File> getFile() async {
    final path = await appPath.getProfilePath(id);
    final file = File(path!);
    final isExists = await file.exists();
    if (!isExists) {
      await file.create(recursive: true);
    }
    return file;
  }

  /// Get file content using secure memory service
  /// This no longer stores readable YAML in memory
  Future<String> getFileContent() async {
    final file = await getFile();
    final bytes = await file.readAsBytes();
    
    // Check if the file is already in secure cache
    if (SecureMemoryService.isProfileSecured(id)) {
      // Use secure profile access - only decrypts temporarily
      return await SecureMemoryService.withSecureProfile(id, (yamlContent) async {
        return yamlContent;
      });
    }
    
    // Store in secure cache and return content
    SecureMemoryService.storeSecureProfile(id, bytes);
    return await SecureMemoryService.withSecureProfile(id, (yamlContent) async {
      return yamlContent;
    });
  }

  /// Prepares the profile for Clash Core using secure memory
  /// This method ensures no readable YAML is cached in memory
  Future<void> prepareForClashCore() async {
    final file = await getFile();
    final bytes = await file.readAsBytes();
    
    // Don't do anything for empty files
    if (bytes.isEmpty) {
      return;
    }
    
    // Check if this content is already in secure cache
    if (SecureMemoryService.isProfileSecured(id)) {
      return; // Already prepared securely
    }
    
    // Store in secure cache (encrypted + obfuscated format)
    SecureMemoryService.storeSecureProfile(id, bytes);
  }

  /// Access the profile content securely with a callback function
  /// The content is only decrypted temporarily during the operation
  Future<T> withSecureContent<T>(Future<T> Function(String yamlContent) operation) async {
    final file = await getFile();
    final bytes = await file.readAsBytes();
    
    // Ensure it's in secure cache
    if (!SecureMemoryService.isProfileSecured(id)) {
      SecureMemoryService.storeSecureProfile(id, bytes);
    }
    
    // Use secure access - content is only readable during the callback
    return await SecureMemoryService.withSecureProfile(id, operation);
  }

  /// Legacy method - now redirects to secure content access
  @Deprecated('Use withSecureContent instead for better security')
  Future<T> withDecryptedContent<T>(Future<T> Function(Uint8List decryptedBytes) operation) async {
    return await withSecureContent<T>((yamlContent) async {
      final bytes = Uint8List.fromList(utf8.encode(yamlContent));
      try {
        return await operation(bytes);
      } finally {
        // Clear the temporary bytes
        bytes.fillRange(0, bytes.length, 0);
      }
    });
  }

  Future<int> get profileLastModified async {
    final file = await getFile();
    return (await file.lastModified()).microsecondsSinceEpoch;
  }

  Future<Profile> update() async {
    final response = await request.getFileResponseForUrl(url);
    final disposition = response.headers.value("content-disposition");
    final userinfo = response.headers.value('subscription-userinfo');
    return await copyWith(
      label: label ?? other.getFileNameForDisposition(disposition) ?? id,
      subscriptionInfo: SubscriptionInfo.formHString(userinfo),
    ).saveFile(response.data);
  }

  Future<Profile> saveFile(Uint8List bytes) async {
    try {
      // Check if the incoming data is already encrypted
      if (EncryptionService.hasEncryptionHeader(bytes)) {
        commonPrint.log("Importing encrypted profile - processing securely");
        try {
          // Process using secure content access
          final data = utf8.decode(EncryptionService.decrypt(bytes), allowMalformed: false).trim();
          return await saveFileWithString(data);
        } catch (e) {
          commonPrint.log("Failed to decrypt encrypted profile: $e");
          throw "Unable to import encrypted profile: The file appears to be corrupted or uses a different encryption key";
        }
      } else {
        // Handle as plain text (unencrypted) data
        try {
          final data = utf8.decode(bytes, allowMalformed: false).trim();
          return await saveFileWithString(data);
        } catch (e) {
          commonPrint.log("UTF-8 decode error: $e");
          throw "Profile decode error: The file is not a valid UTF-8 text or YAML configuration";
        }
      }
    } catch (e) {
      // Only log specific error if it's not already a formatted message string
      if (e is! String) {
        commonPrint.log("Profile import error: $e");
        throw "Profile import failed: The file format is not supported";
      }
      throw e;
    }
  }

  Future<Profile> saveFileWithString(String data) async {
    if (data.trim().isEmpty) {
      throw "Profile is empty";
    }
    
    try {
      // Validate the configuration using Clash Core
      final message = await clashCore.validateConfig(data);
      if (message.isNotEmpty) {
        commonPrint.log("Profile validation error: $message");
        throw message;
      }
      
      final file = await getFile();
      
      // Convert string to bytes
      final rawBytes = utf8.encode(data);
      
      // Always encrypt before saving to disk
      final encryptedBytes = EncryptionService.encrypt(Uint8List.fromList(rawBytes));
      
      await file.writeAsBytes(encryptedBytes);
      
      // Store in secure memory cache (removes any old cache)
      SecureMemoryService.clearSecureProfile(id);
      SecureMemoryService.storeSecureProfile(id, encryptedBytes);
      
      return copyWith(lastUpdateDate: DateTime.now());
    } catch (e) {
      // Add better error logging
      if (e is String) {
        throw e; // Already formatted error message
      } else {
        commonPrint.log("Error saving profile: $e");
        throw "Failed to save profile: ${e.toString()}";
      }
    }
  }

  @Deprecated('Use ensureGoEncryptionInitialized instead - this method creates security vulnerability')
  Future<void> temporarilyDecryptForCore() async {
    throw UnimplementedError('Use ensureGoEncryptionInitialized instead');
  }
}
