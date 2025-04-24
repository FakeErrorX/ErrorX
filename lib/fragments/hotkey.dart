import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/card.dart';
import 'package:errorx/widgets/dialog.dart';
import 'package:errorx/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

extension IntlExt on Intl {
  static actionMessage(String messageText) =>
      Intl.message("action_$messageText");
}

class HotKeyFragment extends StatefulWidget {
  const HotKeyFragment({super.key});

  @override
  State<HotKeyFragment> createState() => _HotKeyFragmentState();
}

class _HotKeyFragmentState extends State<HotKeyFragment> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
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

  String getSubtitle(HotKeyAction hotKeyAction) {
    final key = hotKeyAction.key;
    if (key == null) {
      return appLocalizations.noHotKey;
    }
    final modifierLabels =
        hotKeyAction.modifiers.map((item) => item.physicalKeys.first.label);
    var text = "";
    if (modifierLabels.isNotEmpty) {
      text += "${modifierLabels.join(" ")}+";
    }
    text += PhysicalKeyboardKey(key).label;
    return text;
  }

  Color _getActionColor(HotAction action) {
    switch (action) {
      case HotAction.mode:
        return Colors.purple.shade600;
      case HotAction.start:
        return Colors.green.shade600;
      case HotAction.view:
        return Colors.blue.shade600;
      case HotAction.proxy:
        return Colors.orange.shade600;
      case HotAction.tun:
        return Colors.teal.shade600;
    }
  }
  
  IconData _getActionIcon(HotAction action) {
    switch (action) {
      case HotAction.mode:
        return Icons.mode_rounded;
      case HotAction.start:
        return Icons.play_arrow_rounded;
      case HotAction.view:
        return Icons.visibility_rounded;
      case HotAction.proxy:
        return Icons.lan_rounded;
      case HotAction.tun:
        return Icons.vpn_lock_rounded;
    }
  }

  Widget _buildHotkeyCard(BuildContext context, HotAction hotAction, HotKeyAction hotKeyAction, int index) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.1 * index, 0.2 + (0.1 * index), curve: Curves.easeOutBack),
    );
    
    final hasHotkey = hotKeyAction.key != null;
    final actionColor = _getActionColor(hotAction);
    
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                globalState.showCommonDialog(
                  child: HotKeyRecorder(
                    hotKeyAction: hotKeyAction,
                  ),
                );
              },
              splashColor: actionColor.withOpacity(0.1),
              highlightColor: actionColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getActionIcon(hotAction),
                        color: actionColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            IntlExt.actionMessage(hotAction.name),
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasHotkey)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                getSubtitle(hotKeyAction),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: actionColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Text(
                              appLocalizations.noHotKey,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_rounded,
                      size: 20,
                      color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Header animation
    final headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutQuint),
    );
    
    return Container(
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: HotAction.values.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header section
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(headerAnimation),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(headerAnimation),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_alt_rounded,
                        size: 48,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        appLocalizations.hotkeyManagement,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLocalizations.hotkeyManagementDesc,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          // Hotkey items
          final actualIndex = index - 1;
          final hotAction = HotAction.values[actualIndex];
          
          return Consumer(
            builder: (_, ref, __) {
              final hotKeyAction = ref.watch(getHotKeyActionProvider(hotAction));
              return _buildHotkeyCard(context, hotAction, hotKeyAction, actualIndex);
            },
          );
        },
      ),
    );
  }
}

class HotKeyRecorder extends StatefulWidget {
  final HotKeyAction hotKeyAction;

  const HotKeyRecorder({
    super.key,
    required this.hotKeyAction,
  });

  @override
  State<HotKeyRecorder> createState() => _HotKeyRecorderState();
}

class _HotKeyRecorderState extends State<HotKeyRecorder> with SingleTickerProviderStateMixin {
  late ValueNotifier<HotKeyAction> hotKeyActionNotifier;
  late AnimationController _animationController;
  bool _isRecording = false;
  
  @override
  void initState() {
    super.initState();
    hotKeyActionNotifier = ValueNotifier<HotKeyAction>(
      widget.hotKeyAction.copyWith(),
    );
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
    
    // Auto-start recording mode after a brief delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    });
  }

  bool _handleKeyEvent(KeyEvent keyEvent) {
    if (!_isRecording) return false;
    if (keyEvent is KeyUpEvent) return false;
    
    final keys = HardwareKeyboard.instance.physicalKeysPressed;
    final key = keyEvent.physicalKey;

    final modifiers = KeyboardModifier.values
        .where((e) =>
            e.physicalKeys.any(keys.contains) && !e.physicalKeys.contains(key))
        .toSet();
    hotKeyActionNotifier.value = hotKeyActionNotifier.value.copyWith(
      modifiers: modifiers,
      key: key.usbHidUsage,
    );
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _animationController.dispose();
    super.dispose();
  }

  _handleRemove() {
    Navigator.of(context).pop();
    globalState.appController.updateOrAddHotKeyAction(
      hotKeyActionNotifier.value.copyWith(
        modifiers: {},
        key: null,
      ),
    );
  }

  _handleConfirm() {
    Navigator.of(context).pop();
    final config = globalState.config;
    final currentHotkeyAction = hotKeyActionNotifier.value;
    if (currentHotkeyAction.key == null ||
        currentHotkeyAction.modifiers.isEmpty) {
      globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(text: appLocalizations.inputCorrectHotkey),
      );
      return;
    }
    final hotKeyActions = config.hotKeyActions;
    final index = hotKeyActions.indexWhere(
      (item) =>
          item.key == currentHotkeyAction.key &&
          keyboardModifierListEquality.equals(
            item.modifiers,
            currentHotkeyAction.modifiers,
          ),
    );
    if (index != -1) {
      globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(text: appLocalizations.hotkeyConflict),
      );
      return;
    }
    globalState.appController.updateOrAddHotKeyAction(
      currentHotkeyAction,
    );
  }

  Color _getActionColor(HotAction action) {
    switch (action) {
      case HotAction.mode:
        return Colors.purple.shade600;
      case HotAction.start:
        return Colors.green.shade600;
      case HotAction.view:
        return Colors.blue.shade600;
      case HotAction.proxy:
        return Colors.orange.shade600;
      case HotAction.tun:
        return Colors.teal.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    final actionColor = _getActionColor(widget.hotKeyAction.action);
    
    return CommonDialog(
      title: IntlExt.actionMessage(widget.hotKeyAction.action.name),
      actions: [
        TextButton.icon(
          onPressed: _handleRemove,
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(appLocalizations.remove),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade400,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleConfirm,
          icon: const Icon(Icons.check_rounded),
          label: Text(appLocalizations.confirm),
          style: FilledButton.styleFrom(
            backgroundColor: context.colorScheme.primary,
          ),
        ),
      ],
      child: Container(
        width: dialogCommonWidth,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            FadeTransition(
              opacity: fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecording 
                      ? actionColor.withOpacity(0.1)
                      : context.colorScheme.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRecording 
                        ? actionColor.withOpacity(0.3)
                        : context.colorScheme.outline.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecording) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: actionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isRecording 
                          ? appLocalizations.pressKeyboard
                          : "Preparing for recording...",
                      style: context.textTheme.titleMedium?.copyWith(
                        color: _isRecording ? actionColor : context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: hotKeyActionNotifier,
              builder: (_, hotKeyAction, ___) {
                final key = hotKeyAction.key;
                final modifiers = hotKeyAction.modifiers;
                
                if (key == null) {
                  return const SizedBox.shrink();
                }
                
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Hotkey Combination",
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final modifier in modifiers)
                            KeyboardKeyBox(
                              keyboardKey: modifier.physicalKeys.first,
                              color: actionColor,
                            ),
                          if (modifiers.isNotEmpty)
                            Text(
                              "+",
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          KeyboardKeyBox(
                            keyboardKey: PhysicalKeyboardKey(key),
                            isMainKey: true,
                            color: actionColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class KeyboardKeyBox extends StatelessWidget {
  final KeyboardKey keyboardKey;
  final bool isMainKey;
  final Color color;

  const KeyboardKeyBox({
    super.key,
    required this.keyboardKey,
    this.isMainKey = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMainKey ? 16 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isMainKey 
            ? color.withOpacity(0.15)
            : context.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMainKey
              ? color.withOpacity(0.3)
              : context.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isMainKey
                ? color.withOpacity(0.2)
                : context.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        keyboardKey.label,
        style: TextStyle(
          fontSize: isMainKey ? 18 : 14,
          fontWeight: isMainKey ? FontWeight.bold : FontWeight.w500,
          color: isMainKey 
              ? color
              : context.colorScheme.onSurface,
        ),
      ),
    );
  }
}
