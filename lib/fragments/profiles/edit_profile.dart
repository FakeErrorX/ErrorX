import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/pages/editor.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  final Profile profile;
  final BuildContext context;

  const EditProfile({
    super.key,
    required this.context,
    required this.profile,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> with SingleTickerProviderStateMixin {
  late TextEditingController labelController;
  late TextEditingController urlController;
  late TextEditingController autoUpdateDurationController;
  late bool autoUpdate;
  String? rawText;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final fileInfoNotifier = ValueNotifier<FileInfo?>(null);
  Uint8List? fileData;
  late AnimationController _animationController;

  Profile get profile => widget.profile;

  @override
  void initState() {
    super.initState();
    labelController = TextEditingController(text: widget.profile.label);
    urlController = TextEditingController(text: widget.profile.url);
    autoUpdate = widget.profile.autoUpdate;
    autoUpdateDurationController = TextEditingController(
      text: widget.profile.autoUpdateDuration.inMinutes.toString(),
    );
    appPath.getProfilePath(widget.profile.id).then((path) async {
      if (path == null) return;
      fileInfoNotifier.value = await _getFileInfo(path);
    });
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final appController = globalState.appController;
    Profile profile = this.profile.copyWith(
          url: urlController.text,
          label: labelController.text,
          autoUpdate: autoUpdate,
          autoUpdateDuration: Duration(
            minutes: int.parse(
              autoUpdateDurationController.text,
            ),
          ),
        );
    final hasUpdate = widget.profile.url != profile.url;
    if (fileData != null) {
      if (profile.type == ProfileType.url && autoUpdate) {
        final res = await globalState.showMessage(
          title: appLocalizations.tip,
          message: TextSpan(
            text: appLocalizations.profileHasUpdate,
          ),
        );
        if (res == true) {
          profile = profile.copyWith(
            autoUpdate: false,
          );
        }
      }
      appController.setProfileAndAutoApply(await profile.saveFile(fileData!));
    } else if (!hasUpdate) {
      appController.setProfileAndAutoApply(profile);
    } else {
      globalState.homeScaffoldKey.currentState?.loadingRun(
        () async {
          await Future.delayed(
            commonDuration,
          );
          if (hasUpdate) {
            await appController.updateProfile(profile);
          }
        },
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _setAutoUpdate(bool value) {
    if (autoUpdate == value) return;
    setState(() {
      autoUpdate = value;
    });
  }

  Future<FileInfo?> _getFileInfo(path) async {
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }
    final lastModified = await file.lastModified();
    final size = await file.length();
    return FileInfo(
      size: size,
      lastModified: lastModified,
    );
  }

  _handleSaveEdit(BuildContext context, String data) async {
    final message = await globalState.safeRun<String>(
      () async {
        final message = await clashCore.validateConfig(data);
        return message;
      },
      silence: false,
    );
    if (message?.isNotEmpty == true) {
      globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(text: message),
      );
      return;
    }
    if (context.mounted) {
      Navigator.of(context).pop(data);
    }
  }

  // Mask sensitive content in YAML files before displaying in editor
  String _maskSensitiveContent(String content) {
    // Use RegExp to find and mask sensitive fields
    final serverRegex = RegExp(r'(\s*server:\s*)([^\s#]+)', multiLine: true);
    final portRegex = RegExp(r'(\s*port:\s*)(\d+)', multiLine: true);
    final usernameRegex = RegExp(r'(\s*username:\s*)([^\s#]+)', multiLine: true);
    final passwordRegex = RegExp(r'(\s*password:\s*)([^\s#]+)', multiLine: true);
    
    // Replace with masked values but preserve formatting
    content = content.replaceAllMapped(serverRegex, (match) => '${match.group(1)}*****');
    content = content.replaceAllMapped(portRegex, (match) => '${match.group(1)}*****');
    content = content.replaceAllMapped(usernameRegex, (match) => '${match.group(1)}*****');
    content = content.replaceAllMapped(passwordRegex, (match) => '${match.group(1)}*****');
    
    return content;
  }

  // Store original unmasked content
  String? _originalContent;

  _editProfileFile() async {
    if (_originalContent == null) {
      _originalContent = await profile.getFileContent();
      rawText = _maskSensitiveContent(_originalContent!);
    }
    
    if (!mounted) return;
    final title = widget.profile.label ?? widget.profile.id ?? "Profile";
    
    // Show masked content in the editor
    final data = await BaseNavigator.push<String>(
      globalState.homeScaffoldKey.currentContext!,
      EditorPage(
        title: title,
        content: rawText!,
        onSave: (context, editedContent) {
          // Silently keep masked fields from original content
          // while preserving user edits to non-sensitive fields
          String mergedContent = _preserveOriginalSensitiveData(editedContent, _originalContent!);
          _handleSaveEdit(context, mergedContent);
        },
        onPop: (context, data) async {
          if (data == rawText) {
            return true;
          }
          final res = await globalState.showMessage(
            title: title,
            message: TextSpan(
              text: appLocalizations.hasCacheChange,
            ),
          );
          if (res == true && context.mounted) {
            // Merge changes without warning
            String mergedContent = _preserveOriginalSensitiveData(data, _originalContent!);
            _handleSaveEdit(context, mergedContent);
          } else {
            return true;
          }
          return false;
        },
      ),
    );
    
    if (data == null) {
      return;
    }
    
    // Update with original (unmasked) content plus user edits to non-sensitive fields
    String mergedContent = _preserveOriginalSensitiveData(data, _originalContent!);
    _originalContent = mergedContent;
    rawText = _maskSensitiveContent(mergedContent);
    fileData = Uint8List.fromList(utf8.encode(mergedContent));
    fileInfoNotifier.value = fileInfoNotifier.value?.copyWith(
      size: fileData?.length ?? 0,
      lastModified: DateTime.now(),
    );
  }

  // Preserve original sensitive data while keeping user edits to non-sensitive fields
  String _preserveOriginalSensitiveData(String editedContent, String originalContent) {
    // Parse YAML line by line to preserve non-sensitive edits while keeping sensitive data
    final originalLines = originalContent.split('\n');
    final editedLines = editedContent.split('\n');
    final result = <String>[];
    
    // Map to track sensitive field line numbers from the original
    final sensitiveLineIndices = <int>{};
    
    // Identify sensitive lines in the original content
    for (int i = 0; i < originalLines.length; i++) {
      final line = originalLines[i];
      if (_isSensitiveLine(line)) {
        sensitiveLineIndices.add(i);
      }
    }
    
    // Build a new merged content with original sensitive lines and edited non-sensitive lines
    // For simplicity, we're using line numbers, assuming the structure hasn't changed too much
    for (int i = 0; i < editedLines.length; i++) {
      // If this is a known sensitive line index (adjusted for possible changed line count)
      if (i < originalLines.length && sensitiveLineIndices.contains(i)) {
        // Use the original line that contains real unmasked sensitive data
        result.add(originalLines[i]);
      } else {
        // Use the user's edited line for non-sensitive data
        result.add(editedLines[i]);
      }
    }
    
    // Include any remaining original lines if the user's edit is shorter
    if (originalLines.length > editedLines.length) {
      for (int i = editedLines.length; i < originalLines.length; i++) {
        result.add(originalLines[i]);
      }
    }
    
    return result.join('\n');
  }
  
  // Check if a line contains sensitive information
  bool _isSensitiveLine(String line) {
    final sensitiveFields = [
      RegExp(r'^\s*server:\s*'),
      RegExp(r'^\s*port:\s*'),
      RegExp(r'^\s*username:\s*'),
      RegExp(r'^\s*password:\s*'),
    ];
    
    for (final regex in sensitiveFields) {
      if (regex.hasMatch(line)) {
        return true;
      }
    }
    
    return false;
  }

  _uploadProfileFile() async {
    final platformFile = await globalState.safeRun(picker.pickerFile);
    if (platformFile?.bytes == null) return;
    fileData = platformFile?.bytes;
    fileInfoNotifier.value = fileInfoNotifier.value?.copyWith(
      size: fileData?.length ?? 0,
      lastModified: DateTime.now(),
    );
  }

  _handleBack() async {
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.fileIsUpdate),
    );
    if (res == true) {
      _handleConfirm();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildFormCard({
    required Widget child,
    int index = 0,
    bool withAnimation = true,
  }) {
    if (!withAnimation) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
    }
    
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.1 * index, 0.2 + (0.1 * index), curve: Curves.easeOutBack),
    );
    
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      minLines: 1,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.colorScheme.primary,
            width: 2,
          ),
        ),
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: iconColor ?? context.colorScheme.primary,
        ),
        filled: true,
        fillColor: context.colorScheme.surfaceVariant.withOpacity(0.1),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Header animation
    final headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutQuint),
    );
    
    final items = [
      _buildFormCard(
        index: 0,
        child: _buildModernTextField(
          controller: labelController,
          label: appLocalizations.name,
          icon: Icons.label_rounded,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return appLocalizations.profileNameNullValidationDesc;
            }
            return null;
          },
        ),
      ),
      if (widget.profile.type == ProfileType.url) ...[
        _buildFormCard(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernTextField(
                controller: urlController,
                label: appLocalizations.url,
                icon: Icons.link_rounded,
                iconColor: Colors.blue.shade600,
                maxLines: 5,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.profileUrlNullValidationDesc;
                  }
                  if (!value.isUrl) {
                    return appLocalizations.profileUrlInvalidValidationDesc;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sync_rounded,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appLocalizations.autoUpdate,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: autoUpdate,
                    onChanged: _setAutoUpdate,
                  ),
                ],
              ),
              if (autoUpdate) ...[
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: autoUpdateDurationController,
                  label: appLocalizations.autoUpdateInterval,
                  icon: Icons.timer_rounded,
                  iconColor: Colors.orange.shade600,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.profileAutoUpdateIntervalNullValidationDesc;
                    }
                    try {
                      int.parse(value);
                    } catch (_) {
                      return appLocalizations.profileAutoUpdateIntervalInvalidValidationDesc;
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ],
      ValueListenableBuilder<FileInfo?>(
        valueListenable: fileInfoNotifier,
        builder: (_, fileInfo, __) {
          return FadeThroughBox(
            child: fileInfo == null
                ? Container()
                : _buildFormCard(
                    index: widget.profile.type == ProfileType.url ? 2 : 1,
                    withAnimation: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.colorScheme.tertiaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description_rounded,
                                color: context.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appLocalizations.profile,
                                    style: context.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fileInfo.desc,
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      color: context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _editProfileFile,
                                icon: const Icon(Icons.edit_rounded),
                                label: Text(appLocalizations.edit),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _uploadProfileFile,
                                icon: const Icon(Icons.upload_rounded),
                                label: Text(appLocalizations.upload),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    ];
    
    return CommonPopScope(
      onPop: () {
        if (fileData == null) {
          return true;
        }
        _handleBack();
        return false;
      },
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colorScheme.background,
                  context.colorScheme.surface,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 100),
                  children: [
                    // Animated header
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(headerAnimation),
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
                            .animate(headerAnimation),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 48,
                                color: context.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.profile.label ?? widget.profile.id ?? "Profile",
                                style: context.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appLocalizations.edit,
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ...items,
                  ],
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _handleConfirm,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(appLocalizations.save),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: context.colorScheme.onPrimary,
                          backgroundColor: context.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
