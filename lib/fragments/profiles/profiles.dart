import 'dart:ui';

import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/fragments/profiles/edit_profile.dart';
import 'package:errorx/fragments/profiles/override_profile.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_profile.dart';

class ProfilesFragment extends StatefulWidget {
  const ProfilesFragment({super.key});

  @override
  State<ProfilesFragment> createState() => _ProfilesFragmentState();
}

class _ProfilesFragmentState extends State<ProfilesFragment> with PageMixin, SingleTickerProviderStateMixin {
  Function? applyConfigDebounce;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _handleShowAddExtendPage() {
    showExtend(
      globalState.navigatorKey.currentState!.context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: AddProfile(
            context: globalState.navigatorKey.currentState!.context,
          ),
          title: "${appLocalizations.add}${appLocalizations.profile}",
        );
      },
    );
  }

  _updateProfiles() async {
    final profiles = globalState.config.profiles;
    final messages = [];
    final updateProfiles = profiles.map<Future>(
      (profile) async {
        if (profile.type == ProfileType.file) return;
        globalState.appController.setProfile(
          profile.copyWith(isUpdating: true),
        );
        try {
          await globalState.appController.updateProfile(profile);
        } catch (e) {
          messages.add("${profile.label ?? profile.id}: $e \n");
          globalState.appController.setProfile(
            profile.copyWith(
              isUpdating: false,
            ),
          );
        }
      },
    );
    final titleMedium = context.textTheme.titleMedium;
    await Future.wait(updateProfiles);
    if (messages.isNotEmpty) {
      globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(
          children: [
            for (final message in messages)
              TextSpan(text: message, style: titleMedium)
          ],
        ),
      );
    }
  }

  @override
  List<Widget> get actions => [
        IconButton(
          onPressed: () {
            _updateProfiles();
          },
          icon: const Icon(Icons.sync),
          tooltip: appLocalizations.sync,
        ),
        IconButton(
          onPressed: () {
            final profiles = globalState.config.profiles;
            showSheet(
              context: context,
              builder: (_, type) {
                return ReorderableProfilesSheet(
                  type: type,
                  profiles: profiles,
                );
              },
            );
          },
          icon: const Icon(Icons.sort),
          iconSize: 26,
          tooltip: appLocalizations.profilesSort,
        ),
      ];

  @override
  Widget? get floatingActionButton => FloatingActionButton(
        heroTag: null,
        onPressed: _handleShowAddExtendPage,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.add,
        ),
      );
      
  @override
  void initPageState() {
    super.initPageState();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        ref.listenManual(
          isCurrentPageProvider(PageLabel.profiles),
          (prev, next) {
            if (prev != next && next == true) {
              initPageState();
            }
          },
          fireImmediately: true,
        );
        final profilesSelectorState = ref.watch(profilesSelectorStateProvider);
        if (profilesSelectorState.profiles.isEmpty) {
          return _buildEmptyState();
        }
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
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 88,
              ),
              child: Column(
                children: [
                  Grid(
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    crossAxisCount: profilesSelectorState.columns,
                    children: [
                      for (int i = 0; i < profilesSelectorState.profiles.length; i++)
                        GridItem(
                          child: ProfileItem(
                            key: Key(profilesSelectorState.profiles[i].id),
                            profile: profilesSelectorState.profiles[i],
                            groupValue: profilesSelectorState.currentProfileId,
                            onChanged: (profileId) {
                              ref.read(currentProfileIdProvider.notifier).value =
                                  profileId;
                            },
                            index: i,
                            animationController: _animationController,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_off_rounded,
                  size: 48,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations.nullProfileDesc,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLocalizations.nullProfileDesc,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _handleShowAddExtendPage,
                icon: const Icon(Icons.add),
                label: Text("${appLocalizations.add}${appLocalizations.profile}"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final Profile profile;
  final String? groupValue;
  final void Function(String? value) onChanged;
  final int index;
  final AnimationController animationController;

  const ProfileItem({
    super.key,
    required this.profile,
    required this.groupValue,
    required this.onChanged,
    required this.index,
    required this.animationController,
  });

  _handleDeleteProfile(BuildContext context) async {
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteProfileTip,
      ),
    );
    if (res != true) {
      return;
    }
    await globalState.appController.deleteProfile(profile.id);
  }

  Future updateProfile() async {
    final appController = globalState.appController;
    if (profile.type == ProfileType.file) return;
    await globalState.safeRun(silence: false, () async {
      try {
        appController.setProfile(
          profile.copyWith(
            isUpdating: true,
          ),
        );
        await appController.updateProfile(profile);
      } catch (e) {
        appController.setProfile(
          profile.copyWith(
            isUpdating: false,
          ),
        );
        rethrow;
      }
    });
  }

  _handleShowEditExtendPage(BuildContext context) {
    showExtend(
      context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: EditProfile(
            profile: profile,
            context: context,
          ),
          title: "${appLocalizations.edit}${appLocalizations.profile}",
        );
      },
    );
  }

  List<Widget> _buildUrlProfileInfo(BuildContext context) {
    final subscriptionInfo = profile.subscriptionInfo;
    return [
      const SizedBox(
        height: 8,
      ),
      if (subscriptionInfo != null)
        SubscriptionInfoView(
          subscriptionInfo: subscriptionInfo,
        ),
      Text(
        profile.lastUpdateDate?.lastUpdateTimeDesc ?? "",
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
    ];
  }

  List<Widget> _buildFileProfileInfo(BuildContext context) {
    return [
      const SizedBox(
        height: 8,
      ),
      Text(
        profile.lastUpdateDate?.lastUpdateTimeDesc ?? "",
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
    ];
  }

  _handlePushGenProfilePage(BuildContext context, String id) {
    BaseNavigator.push(
      context,
      OverrideProfile(
        profileId: id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate animation timing based on index
    // Stagger the animations for a nice cascading effect
    final double delayFactor = 0.1;
    final double startTime = 0.3 + (index * delayFactor > 0.6 ? 0.6 : index * delayFactor);
    final double endTime = 0.7 + (index * delayFactor > 0.6 ? 0.6 : index * delayFactor);
    
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(startTime, endTime, curve: Curves.easeOutBack),
    );
    
    final Color cardColor = profile.id == groupValue 
        ? context.colorScheme.primaryContainer.withOpacity(0.6)
        : context.colorScheme.surface;
    
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                onChanged(profile.id);
              },
              splashColor: context.colorScheme.primary.withOpacity(0.1),
              highlightColor: context.colorScheme.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (profile.id == groupValue)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: context.colorScheme.primary,
                              size: 16,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: switch (profile.type) {
                                ProfileType.file => Colors.blue.withOpacity(0.1),
                                ProfileType.url => Colors.orange.withOpacity(0.1),
                              },
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              switch (profile.type) {
                                ProfileType.file => Icons.insert_drive_file_rounded,
                                ProfileType.url => Icons.link_rounded,
                              },
                              color: switch (profile.type) {
                                ProfileType.file => Colors.blue,
                                ProfileType.url => Colors.orange,
                              },
                              size: 16,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.label ?? profile.id,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: profile.id == groupValue
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          width: 36,
                          child: FadeThroughBox(
                            child: profile.isUpdating
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : CommonPopupBox(
                                    popup: CommonPopupMenu(
                                      items: [
                                        PopupMenuItemData(
                                          icon: Icons.edit_outlined,
                                          label: appLocalizations.edit,
                                          onPressed: () {
                                            _handleShowEditExtendPage(context);
                                          },
                                        ),
                                        if (profile.type == ProfileType.url) ...[
                                          PopupMenuItemData(
                                            icon: Icons.sync_alt_sharp,
                                            label: appLocalizations.sync,
                                            onPressed: () {
                                              updateProfile();
                                            },
                                          ),
                                        ],
                                        PopupMenuItemData(
                                          icon: Icons.extension_outlined,
                                          label: appLocalizations.override,
                                          onPressed: () {
                                            _handlePushGenProfilePage(context, profile.id);
                                          },
                                        ),
                                        PopupMenuItemData(
                                          icon: Icons.delete_outlined,
                                          iconSize: 20,
                                          label: appLocalizations.delete,
                                          onPressed: () {
                                            _handleDeleteProfile(context);
                                          },
                                          type: PopupMenuItemType.danger,
                                        ),
                                      ],
                                    ),
                                    targetBuilder: (open) {
                                      return IconButton(
                                        onPressed: () {
                                          open();
                                        },
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: context.colorScheme.onSurfaceVariant,
                                        ),
                                        style: IconButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...switch (profile.type) {
                          ProfileType.file => _buildFileProfileInfo(context),
                          ProfileType.url => _buildUrlProfileInfo(context),
                        },
                      ],
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
}

class ReorderableProfilesSheet extends StatefulWidget {
  final List<Profile> profiles;
  final SheetType type;

  const ReorderableProfilesSheet({
    super.key,
    required this.profiles,
    required this.type,
  });

  @override
  State<ReorderableProfilesSheet> createState() => _ReorderableProfilesSheetState();
}

class _ReorderableProfilesSheetState extends State<ReorderableProfilesSheet> with SingleTickerProviderStateMixin {
  late List<Profile> profiles;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    profiles = List.from(widget.profiles);
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

  Widget proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final profile = profiles[index];
    return AnimatedBuilder(
      animation: animation,
      builder: (_, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = lerpDouble(1, 1.02, animValue)!;
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        key: Key(profile.id),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            profile.label ?? profile.id,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            profile.type.name,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSheetScaffold(
      type: widget.type,
      title: appLocalizations.profilesSort,
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            globalState.appController.setProfiles(profiles);
          },
          icon: Icon(Icons.save),
          label: Text(appLocalizations.save),
          style: FilledButton.styleFrom(
            backgroundColor: context.colorScheme.primary,
            foregroundColor: context.colorScheme.onPrimary,
          ),
        )
      ],
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              proxyDecorator: proxyDecorator,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final profile = profiles.removeAt(oldIndex);
                  profiles.insert(newIndex, profile);
                });
              },
              itemBuilder: (_, index) {
                final profile = profiles[index];
                
                // Animate each item with a staggered delay
                final animation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.1 + (index * 0.05 > 0.6 ? 0.6 : index * 0.05), 
                                 0.5 + (index * 0.05 > 0.6 ? 0.6 : index * 0.05), 
                                 curve: Curves.easeOutQuad),
                );
                
                return SlideTransition(
                  key: Key(profile.id),
                  position: Tween<Offset>(begin: Offset(0.3, 0), end: Offset.zero).animate(animation),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(animation),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: switch (profile.type) {
                              ProfileType.file => Colors.blue.withOpacity(0.1),
                              ProfileType.url => Colors.orange.withOpacity(0.1),
                            },
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            switch (profile.type) {
                              ProfileType.file => Icons.insert_drive_file_rounded,
                              ProfileType.url => Icons.link_rounded,
                            },
                            color: switch (profile.type) {
                              ProfileType.file => Colors.blue,
                              ProfileType.url => Colors.orange,
                            },
                            size: 20,
                          ),
                        ),
                        title: Text(
                          profile.label ?? profile.id,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          profile.type.name,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: profiles.length,
            ),
          ),
        ],
      ),
    );
  }
}
