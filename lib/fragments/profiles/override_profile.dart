import 'dart:ui';

import 'package:errorx/clash/core.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/common/encryption_service.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:errorx/widgets/scroll.dart';

class OverrideProfile extends StatefulWidget {
  final String profileId;

  const OverrideProfile({
    super.key,
    required this.profileId,
  });

  @override
  State<OverrideProfile> createState() => _OverrideProfileState();
}

class _OverrideProfileState extends State<OverrideProfile> with SingleTickerProviderStateMixin {
  final GlobalKey<CacheItemExtentListViewState> _ruleListKey = GlobalKey();
  final _controller = ScrollController();
  double _currentMaxWidth = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _initState(WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () async {
        // First ensure the profile is decrypted for core operations
        try {
          // Get the profile by ID and ensure it's decrypted
          final profiles = ref.read(profilesProvider);
          final profileIndex = profiles.indexWhere((p) => p.id == widget.profileId);
          
          if (profileIndex >= 0) {
            final profile = profiles[profileIndex];
            // First prepare the profile in memory
            await profile.prepareForClashCore();
            // Then temporarily decrypt it for Clash Core to read
            await profile.temporarilyDecryptForCore();
          }
        } catch (e) {
          commonPrint.log("Failed to prepare profile for override: $e");
        }
        
        // Now get the profile snippet
        final snippet = await clashCore.getProfile(widget.profileId);
        final overrideData = ref.read(
          getProfileOverrideDataProvider(widget.profileId),
        );
        ref.read(profileOverrideStateProvider.notifier).updateState(
              (state) => state.copyWith(
                snippet: snippet,
                overrideData: overrideData,
              ),
            );
      });
    });
  }

  _handleSave(WidgetRef ref, OverrideData overrideData) {
    ref.read(profilesProvider.notifier).updateProfile(
          widget.profileId,
          (state) => state.copyWith(
            overrideData: overrideData,
          ),
        );
  }

  _handleDelete(WidgetRef ref) async {
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.deleteRuleTip),
    );
    if (res != true) {
      return;
    }
    final selectedRules = ref.read(
      profileOverrideStateProvider.select(
        (state) => state.selectedRules,
      ),
    );
    ref.read(profileOverrideStateProvider.notifier).updateState(
      (state) {
        final overrideRule = state.overrideData!.rule.updateRules(
          (rules) => List.from(
            rules.where(
              (item) => !selectedRules.contains(item.id),
            ),
          ),
        );
        return state.copyWith.overrideData!(
          rule: overrideRule,
        );
      },
    );
    ref.read(profileOverrideStateProvider.notifier).updateState(
          (state) => state.copyWith(isEdit: false, selectedRules: {}),
        );
  }

  _handleTryClearCache(double maxWidth) {
    if (_currentMaxWidth != maxWidth) {
      _currentMaxWidth = maxWidth;
      _ruleListKey.currentState?.clearCache();
    }
  }

  _buildContent() {
    return Consumer(
      builder: (_, ref, child) {
        final isInit = ref.watch(
          profileOverrideStateProvider.select(
            (state) => state.snippet != null && state.overrideData != null,
          ),
        );
        if (!isInit) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return FadeBox(
          child: !isInit
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : child!,
        );
      },
      child: LayoutBuilder(
        builder: (_, constraints) {
          _handleTryClearCache(constraints.maxWidth - 104);
          return CommonAutoHiddenScrollBar(
            controller: _controller,
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16,
                  ),
                ),
                // Header section with animations
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(0.0, 0.4, curve: Curves.easeOut),
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.0, 0.4, curve: Curves.easeOutCubic),
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rule_folder_rounded,
                              size: 48,
                              color: context.colorScheme.primary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              appLocalizations.override,
                              style: context.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Customize your profile rules",
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: SlideTransition(
                      position: Tween<Offset>(begin: Offset(0.3, 0), end: Offset.zero).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.2, 0.6, curve: Curves.easeOutBack),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.2, 0.6, curve: Curves.easeOut),
                          ),
                        ),
                        child: OverrideSwitch(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: Offset(0.3, 0), end: Offset.zero).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.3, 0.7, curve: Curves.easeOutBack),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.3, 0.7, curve: Curves.easeOut),
                          ),
                        ),
                        child: RuleTitle(
                          profileId: widget.profileId,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  sliver: RuleContent(
                    maxWidth: _currentMaxWidth,
                    ruleListKey: _ruleListKey,
                    animationController: _animationController,
                    profileId: widget.profileId,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        profileOverrideStateProvider.overrideWith(() => ProfileOverrideState()),
      ],
      child: Consumer(
        builder: (_, ref, child) {
          _initState(ref);
          return child!;
        },
        child: Consumer(
          builder: (_, ref, ___) {
            final vm2 = ref.watch(
              profileOverrideStateProvider.select(
                (state) => VM2(
                  a: state.isEdit,
                  b: state.selectedRules.length,
                ),
              ),
            );
            final isEdit = vm2.a;
            final editCount = vm2.b;
            return CommonScaffold(
              title: appLocalizations.override,
              body: _buildContent(),
              actions: [
                if (!isEdit)
                  Consumer(
                    builder: (_, ref, child) {
                      final overrideData = ref.watch(
                          getProfileOverrideDataProvider(widget.profileId));
                      final newOverrideData = ref.watch(
                        profileOverrideStateProvider.select(
                          (state) => state.overrideData,
                        ),
                      );
                      final equals = overrideData == newOverrideData;
                      if (equals || newOverrideData == null) {
                        return SizedBox();
                      }
                      return CommonPopScope(
                        onPop: () async {
                          if (equals) {
                            return true;
                          }
                          final res = await globalState.showMessage(
                            message: TextSpan(
                              text: appLocalizations.saveChanges,
                            ),
                            confirmText: appLocalizations.save,
                          );
                          if (!context.mounted || res != true) {
                            return true;
                          }
                          _handleSave(ref, newOverrideData);
                          return true;
                        },
                        child: IconButton(
                          onPressed: () async {
                            final res = await globalState.showMessage(
                              message: TextSpan(
                                text: appLocalizations.saveTip,
                              ),
                              confirmText: appLocalizations.tip,
                            );
                            if (res != true) {
                              return;
                            }
                            _handleSave(ref, newOverrideData);
                          },
                          icon: Icon(
                            Icons.save,
                          ),
                        ),
                      );
                    },
                  ),
                if (editCount == 1)
                  IconButton(
                    onPressed: () {
                      final rule = ref.read(profileOverrideStateProvider.select(
                        (state) {
                          return state.overrideData?.rule.rules.firstWhere(
                            (item) => item.id == state.selectedRules.first,
                          );
                        },
                      ));
                      if (rule == null) {
                        return;
                      }
                      globalState.appController.handleAddOrUpdate(
                        ref,
                        rule,
                      );
                    },
                    icon: Icon(
                      Icons.edit,
                    ),
                  ),
                if (editCount > 0)
                  IconButton(
                    onPressed: () {
                      _handleDelete(ref);
                    },
                    icon: Icon(
                      Icons.delete,
                    ),
                  )
              ],
              appBarEditState: AppBarEditState(
                isEdit: isEdit,
                editCount: editCount,
                onExit: () {
                  ref.read(profileOverrideStateProvider.notifier).updateState(
                        (state) => state.copyWith(
                          isEdit: false,
                          selectedRules: {},
                        ),
                      );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class OverrideSwitch extends ConsumerWidget {
  const OverrideSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enable = ref.watch(
      profileOverrideStateProvider.select(
        (state) => state.overrideData?.enable,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enable == true 
                    ? context.colorScheme.primary.withOpacity(0.1)
                    : context.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.toggle_on_rounded,
                color: enable == true 
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalizations.enableOverride,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Apply custom rule modifications",
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enable ?? false,
              onChanged: (value) {
                ref.read(profileOverrideStateProvider.notifier).updateState(
                      (state) => state.copyWith.overrideData!(
                        enable: value,
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

class RuleTitle extends ConsumerWidget {
  final String profileId;

  const RuleTitle({
    super.key,
    required this.profileId,
  });

  _handleChangeType(WidgetRef ref, isOverrideRule) {
    ref.read(profileOverrideStateProvider.notifier).updateState(
          (state) => state.copyWith.overrideData!.rule(
            type: isOverrideRule
                ? OverrideRuleType.added
                : OverrideRuleType.override,
          ),
        );
  }

  @override
  Widget build(BuildContext context, ref) {
    final vm3 = ref.watch(
      profileOverrideStateProvider.select(
        (state) {
          final overrideRule = state.overrideData?.rule;
          return VM3(
            a: state.isEdit,
            b: state.selectedRules.containsAll(
              overrideRule?.rules.map((item) => item.id).toSet() ?? {},
            ),
            c: overrideRule?.type == OverrideRuleType.override,
          );
        },
      ),
    );
    final isEdit = vm3.a;
    final isSelectAll = vm3.b;
    final isOverrideRule = vm3.c;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOverrideRule ? Icons.edit_document : Icons.note_add,
                    color: context.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations.rule,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOverrideRule
                            ? appLocalizations.overrideOriginRules
                            : appLocalizations.addedOriginRules,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEdit)
                  IconButton(
                    icon: Icon(
                      isOverrideRule ? Icons.edit_document : Icons.note_add,
                      color: context.colorScheme.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colorScheme.primaryContainer.withOpacity(0.4),
                      alignment: Alignment.center,
                      fixedSize: Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      _handleChangeType(
                        ref,
                        isOverrideRule,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                !isEdit
                    ? FilledButton.icon(
                        onPressed: () {
                          globalState.appController.handleAddOrUpdate(ref);
                        },
                        icon: Icon(Icons.add_rounded),
                        label: Text(appLocalizations.add),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colorScheme.primary,
                          foregroundColor: context.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : isSelectAll
                        ? FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(profileOverrideStateProvider.notifier)
                                  .updateState(
                                    (state) => state.copyWith(
                                      selectedRules: {},
                                    ),
                                  );
                            },
                            icon: Icon(Icons.deselect_rounded),
                            label: Text(appLocalizations.selectAll),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.colorScheme.primary,
                              foregroundColor: context.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(profileOverrideStateProvider.notifier)
                                  .updateState(
                                    (state) => state.copyWith(
                                      selectedRules: state.overrideData?.rule.rules
                                              .map((item) => item.id)
                                              .toSet() ??
                                          {},
                                    ),
                                  );
                            },
                            icon: Icon(Icons.select_all_rounded),
                            label: Text(appLocalizations.selectAll),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.colorScheme.secondary,
                              foregroundColor: context.colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RuleContent extends ConsumerWidget {
  final Key ruleListKey;
  final double maxWidth;
  final AnimationController animationController;
  final String profileId;

  const RuleContent({
    super.key,
    required this.ruleListKey,
    required this.maxWidth,
    required this.animationController,
    required this.profileId,
  });

  Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = lerpDouble(1, 1.02, animValue)!;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildItem(BuildContext context, Rule rule, int index) {
    return Consumer(
      builder: (context, ref, ___) {
        final vm2 = ref.watch(profileOverrideStateProvider.select(
          (item) => VM2(
            a: item.isEdit,
            b: item.selectedRules.contains(rule.id),
          ),
        ));
        final isEdit = vm2.a;
        final isSelected = vm2.b;

        final animation = CurvedAnimation(
          parent: animationController,
          curve: Interval(0.4 + (index * 0.05 > 0.8 ? 0.8 : index * 0.05), 
                          0.8 + (index * 0.05 > 0.8 ? 0.8 : index * 0.05), 
                          curve: Curves.easeOutQuad),
        );

        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(animation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1.0).animate(animation),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorScheme.secondaryContainer
                      : context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: ListTile(
                  minTileHeight: 0,
                  minVerticalPadding: 0,
                  titleTextStyle: context.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  trailing: SizedBox(
                    width: 32,
                    height: 32,
                    child: !isEdit
                        ? ReorderableDragStartListener(
                            index: index,
                            child: Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.drag_handle, size: 18),
                              ),
                            ),
                          )
                        : CommonCheckBox(
                            value: isSelected,
                            isCircle: true,
                            onChanged: (_) {
                              _handleSelect(ref, rule.id);
                            },
                          ),
                  ),
                  title: Text(rule.value),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _handleSelect(WidgetRef ref, ruleId) {
    if (!ref.read(profileOverrideStateProvider).isEdit) {
      return;
    }
    ref.read(profileOverrideStateProvider.notifier).updateState(
      (state) {
        final newSelectedRules = Set<String>.from(state.selectedRules);
        if (newSelectedRules.contains(ruleId)) {
          newSelectedRules.remove(ruleId);
        } else {
          newSelectedRules.add(ruleId);
        }
        return state.copyWith(
          selectedRules: newSelectedRules,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final vm2 = ref.watch(
      profileOverrideStateProvider.select(
        (state) {
          final overrideRule = state.overrideData?.rule;
          return VM2(
            a: overrideRule?.rules ?? [],
            b: overrideRule?.type ?? OverrideRuleType.added,
          );
        },
      ),
    );
    final rules = vm2.a;
    final type = vm2.b;
    
    if (rules.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          margin: EdgeInsets.symmetric(vertical: 8),
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
          child: Center(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animationController,
                  curve: Interval(0.5, 0.9, curve: Curves.easeOut),
                ),
              ),
              child: type == OverrideRuleType.added
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          appLocalizations.noData,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: () async {
                        try {
                          // Make sure the profile is decrypted for Clash Core to read
                          final profiles = ref.read(profilesProvider);
                          final profileIndex = profiles.indexWhere((p) => p.id == profileId);
                          
                          if (profileIndex >= 0) {
                            final profile = profiles[profileIndex];
                            // First prepare the profile in memory
                            await profile.prepareForClashCore();
                            // Then temporarily decrypt it for Clash Core to read
                            await profile.temporarilyDecryptForCore();
                          }
                          
                          // Now get the rules from core
                          final snippet = await clashCore.getProfile(profileId);
                          if (snippet?.rule != null && snippet!.rule.isNotEmpty) {
                            ref.read(profileOverrideStateProvider.notifier).updateState(
                              (state) {
                                return state.copyWith.overrideData!.rule(
                                  overrideRules: snippet.rule,
                                );
                              },
                            );
                          } else {
                            // Show error if rules couldn't be retrieved
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Could not retrieve original rules. Please try again."),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          commonPrint.log("Error getting original rules: $e");
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error retrieving rules: $e"),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.file_download_rounded),
                      label: Text(appLocalizations.getOriginRules),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    }
    return CacheItemExtentSliverReorderableList(
      key: ruleListKey,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return GestureDetector(
          key: ObjectKey(rule),
          child: _buildItem(
            context,
            rule,
            index,
          ),
          onTap: () {
            _handleSelect(ref, rule.id);
          },
          onLongPress: () {
            if (ref.read(profileOverrideStateProvider).isEdit) {
              return;
            }
            ref.read(profileOverrideStateProvider.notifier).updateState(
                  (state) => state.copyWith(
                    isEdit: true,
                    selectedRules: {
                      rule.id,
                    },
                  ),
                );
          },
        );
      },
      proxyDecorator: _proxyDecorator,
      itemCount: rules.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final newRules = List<Rule>.from(rules);
        final item = newRules.removeAt(oldIndex);
        newRules.insert(newIndex, item);
        ref.read(profileOverrideStateProvider.notifier).updateState(
              (state) => state.copyWith.overrideData!(
                rule: state.overrideData!.rule.updateRules((_) => newRules),
              ),
            );
      },
      keyBuilder: (int index) {
        return rules[index].value;
      },
      itemExtentBuilder: (index) {
        final rule = rules[index];
        return 40 +
            globalState.measure
                .computeTextSize(
                  Text(
                    rule.value,
                    style: context.textTheme.bodyMedium?.toJetBrainsMono,
                  ),
                  maxWidth: maxWidth,
                )
                .height;
      },
    );
  }
}

class AddRuleDialog extends StatefulWidget {
  final ClashConfigSnippet snippet;
  final Rule? rule;

  const AddRuleDialog({
    super.key,
    required this.snippet,
    this.rule,
  });

  @override
  State<AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends State<AddRuleDialog> {
  late RuleAction _ruleAction;
  final _ruleTargetController = TextEditingController();
  final _contentController = TextEditingController();
  final _ruleProviderController = TextEditingController();
  final _subRuleController = TextEditingController();
  bool _noResolve = false;
  bool _src = false;
  List<DropdownMenuEntry> _targetItems = [];
  List<DropdownMenuEntry> _ruleProviderItems = [];
  List<DropdownMenuEntry> _subRuleItems = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _initState();
    super.initState();
  }

  _initState() {
    _targetItems = [
      ...widget.snippet.proxyGroups.map(
        (item) => DropdownMenuEntry(
          value: item.name,
          label: item.name,
        ),
      ),
      ...RuleTarget.values.map(
        (item) => DropdownMenuEntry(
          value: item.name,
          label: item.name,
        ),
      ),
    ];
    _ruleProviderItems = [
      ...widget.snippet.ruleProvider.map(
        (item) => DropdownMenuEntry(
          value: item.name,
          label: item.name,
        ),
      ),
    ];
    _subRuleItems = [
      ...widget.snippet.subRules.map(
        (item) => DropdownMenuEntry(
          value: item.name,
          label: item.name,
        ),
      ),
    ];
    if (widget.rule != null) {
      final parsedRule = ParsedRule.parseString(widget.rule!.value);
      _ruleAction = parsedRule.ruleAction;
      _contentController.text = parsedRule.content ?? "";
      _ruleTargetController.text = parsedRule.ruleTarget ?? "";
      _ruleProviderController.text = parsedRule.ruleProvider ?? "";
      _subRuleController.text = parsedRule.subRule ?? "";
      _noResolve = parsedRule.noResolve;
      _src = parsedRule.src;
      return;
    }
    _ruleAction = RuleAction.values.first;
    if (_targetItems.isNotEmpty) {
      _ruleTargetController.text = _targetItems.first.value;
    }
    if (_ruleProviderItems.isNotEmpty) {
      _ruleProviderController.text = _ruleProviderItems.first.value;
    }
    if (_subRuleItems.isNotEmpty) {
      _subRuleController.text = _subRuleItems.first.value;
    }
  }

  @override
  void didUpdateWidget(AddRuleDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule != widget.rule) {
      _initState();
    }
  }

  _handleSubmit() {
    final res = _formKey.currentState?.validate();
    if (res == false) {
      return;
    }
    final parsedRule = ParsedRule(
      ruleAction: _ruleAction,
      content: _contentController.text,
      ruleProvider: _ruleProviderController.text,
      ruleTarget: _ruleTargetController.text,
      subRule: _subRuleController.text,
      noResolve: _noResolve,
      src: _src,
    );
    final rule = widget.rule != null
        ? widget.rule!.copyWith(value: parsedRule.value)
        : Rule.value(
            parsedRule.value,
          );
    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.addRule,
      actions: [
        TextButton(
          onPressed: _handleSubmit,
          child: Text(
            appLocalizations.confirm,
          ),
        ),
      ],
      child: DropdownMenuTheme(
        data: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(),
            labelStyle: context.textTheme.bodyLarge
                ?.copyWith(overflow: TextOverflow.ellipsis),
          ),
        ),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (_, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      _ruleAction =
                          await globalState.showCommonDialog<RuleAction>(
                                child: OptionsDialog<RuleAction>(
                                  title: appLocalizations.ruleName,
                                  options: RuleAction.values,
                                  textBuilder: (item) => item.value,
                                  value: _ruleAction,
                                ),
                              ) ??
                              _ruleAction;
                      setState(() {});
                    },
                    child: Text(_ruleAction.name),
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  _ruleAction == RuleAction.RULE_SET
                      ? FormField(
                          validator: (_) {
                            if (_ruleProviderController.text.isEmpty) {
                              return appLocalizations.ruleProviderEmptyTip;
                            }
                            return null;
                          },
                          builder: (field) {
                            return DropdownMenu(
                              expandedInsets: EdgeInsets.zero,
                              controller: _ruleProviderController,
                              label: Text(appLocalizations.ruleProviders),
                              menuHeight: 250,
                              errorText: field.errorText,
                              dropdownMenuEntries: _ruleProviderItems,
                            );
                          },
                        )
                      : TextFormField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: appLocalizations.content,
                          ),
                          validator: (_) {
                            if (_contentController.text.isEmpty) {
                              return appLocalizations.contentEmptyTip;
                            }
                            return null;
                          },
                        ),
                  SizedBox(
                    height: 24,
                  ),
                  _ruleAction == RuleAction.SUB_RULE
                      ? FormField(
                          validator: (_) {
                            if (_subRuleController.text.isEmpty) {
                              return appLocalizations.subRuleEmptyTip;
                            }
                            return null;
                          },
                          builder: (filed) {
                            return DropdownMenu(
                              width: 200,
                              controller: _subRuleController,
                              label: Text(appLocalizations.subRule),
                              menuHeight: 250,
                              dropdownMenuEntries: _subRuleItems,
                            );
                          },
                        )
                      : FormField<String>(
                          validator: (_) {
                            if (_ruleTargetController.text.isEmpty) {
                              return appLocalizations.ruleTargetEmptyTip;
                            }
                            return null;
                          },
                          builder: (filed) {
                            return DropdownMenu(
                              controller: _ruleTargetController,
                              initialSelection: filed.value,
                              label: Text(appLocalizations.ruleTarget),
                              width: 200,
                              menuHeight: 250,
                              enableFilter: true,
                              dropdownMenuEntries: _targetItems,
                              errorText: filed.errorText,
                            );
                          },
                        ),
                  if (_ruleAction.hasParams) ...[
                    SizedBox(
                      height: 20,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        CommonCard(
                          radius: 8,
                          isSelected: _src,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Text(
                              appLocalizations.sourceIp,
                              style: context.textTheme.bodyMedium,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _src = !_src;
                            });
                          },
                        ),
                        CommonCard(
                          radius: 8,
                          isSelected: _noResolve,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Text(
                              appLocalizations.noResolve,
                              style: context.textTheme.bodyMedium,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _noResolve = !_noResolve;
                            });
                          },
                        )
                      ],
                    ),
                  ],
                  SizedBox(
                    height: 20,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
