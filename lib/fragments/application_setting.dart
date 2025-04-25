import 'dart:io';

import 'package:errorx/common/common.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Modern setting toggle card widget
class ModernSettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;
  final Color color;
  final Animation<double> animation;

  const ModernSettingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(animation),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modernized application settings
class ApplicationSettingFragment extends StatefulWidget {
  const ApplicationSettingFragment({super.key});

  @override
  State<ApplicationSettingFragment> createState() => _ApplicationSettingFragmentState();
}

class _ApplicationSettingFragmentState extends State<ApplicationSettingFragment> with SingleTickerProviderStateMixin {
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
  
  IconData _getIconForSetting(String settingType) {
    switch (settingType) {
      case 'minimize':
        return Icons.minimize_rounded;
      case 'autoLaunch':
        return Icons.launch_rounded;
      case 'silentLaunch':
        return Icons.notifications_off_rounded;
      case 'autoRun':
        return Icons.play_circle_rounded;
      case 'hidden':
        return Icons.visibility_off_rounded;
      case 'tabAnimation':
        return Icons.animation_rounded;
      case 'closeConnections':
        return Icons.sync_disabled_rounded;
      case 'statistics':
        return Icons.data_usage_rounded;
      case 'update':
        return Icons.system_update_rounded;
      default:
        return Icons.settings_rounded;
    }
  }
  
  Color _getColorForSetting(String settingType) {
    switch (settingType) {
      case 'minimize':
        return Colors.purple.shade600;
      case 'autoLaunch':
        return Colors.blue.shade600;
      case 'silentLaunch':
        return Colors.teal.shade600;
      case 'autoRun':
        return Colors.green.shade600;
      case 'hidden':
        return Colors.indigo.shade600;
      case 'tabAnimation':
        return Colors.amber.shade600;
      case 'closeConnections':
        return Colors.red.shade600;
      case 'statistics':
        return Colors.orange.shade600;
      case 'update':
        return Colors.pink.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String getLocaleString(Locale? locale) {
    if (locale == null) return appLocalizations.defaultText;
    return Intl.message(locale.toString());
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
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Header
          FadeTransition(
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
                      Icons.settings_applications_rounded,
                      size: 48,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appLocalizations.application,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.applicationDesc,
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
          
          // Minimize on exit setting
          Consumer(
            builder: (context, ref, _) {
              final minimizeOnExit = ref.watch(
                appSettingProvider.select((state) => state.minimizeOnExit),
              );
              return ModernSettingCard(
                title: appLocalizations.minimizeOnExit,
                subtitle: appLocalizations.minimizeOnExitDesc,
                value: minimizeOnExit,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(minimizeOnExit: value),
                  );
                },
                icon: _getIconForSetting('minimize'),
                color: _getColorForSetting('minimize'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.4, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Auto launch setting (desktop only)
          if (system.isDesktop) Consumer(
            builder: (context, ref, _) {
              final autoLaunch = ref.watch(
                appSettingProvider.select((state) => state.autoLaunch),
              );
              return ModernSettingCard(
                title: appLocalizations.autoLaunch,
                subtitle: appLocalizations.autoLaunchDesc,
                value: autoLaunch,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(autoLaunch: value),
                  );
                },
                icon: _getIconForSetting('autoLaunch'),
                color: _getColorForSetting('autoLaunch'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.25, 0.45, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Silent launch setting (desktop only)
          if (system.isDesktop) Consumer(
            builder: (context, ref, _) {
              final silentLaunch = ref.watch(
                appSettingProvider.select((state) => state.silentLaunch),
              );
              return ModernSettingCard(
                title: appLocalizations.silentLaunch,
                subtitle: appLocalizations.silentLaunchDesc,
                value: silentLaunch,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(silentLaunch: value),
                  );
                },
                icon: _getIconForSetting('silentLaunch'),
                color: _getColorForSetting('silentLaunch'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 0.5, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Auto run setting
          Consumer(
            builder: (context, ref, _) {
              final autoRun = ref.watch(
                appSettingProvider.select((state) => state.autoRun),
              );
              return ModernSettingCard(
                title: appLocalizations.autoRun,
                subtitle: appLocalizations.autoRunDesc,
                value: autoRun,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(autoRun: value),
                  );
                },
                icon: _getIconForSetting('autoRun'),
                color: _getColorForSetting('autoRun'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.35, 0.55, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Hidden item (Android only)
          if (Platform.isAndroid) Consumer(
            builder: (context, ref, _) {
              final hidden = ref.watch(
                appSettingProvider.select((state) => state.hidden),
              );
              return ModernSettingCard(
                title: appLocalizations.exclude,
                subtitle: appLocalizations.excludeDesc,
                value: hidden,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(hidden: value),
                  );
                },
                icon: _getIconForSetting('hidden'),
                color: _getColorForSetting('hidden'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 0.6, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Tab animation setting
          Consumer(
            builder: (context, ref, _) {
              final isAnimateToPage = ref.watch(
                appSettingProvider.select((state) => state.isAnimateToPage),
              );
              return ModernSettingCard(
                title: appLocalizations.tabAnimation,
                subtitle: appLocalizations.tabAnimationDesc,
                value: isAnimateToPage,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(isAnimateToPage: value),
                  );
                },
                icon: _getIconForSetting('tabAnimation'),
                color: _getColorForSetting('tabAnimation'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.45, 0.65, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Close connections setting
          Consumer(
            builder: (context, ref, _) {
              final closeConnections = ref.watch(
                appSettingProvider.select((state) => state.closeConnections),
              );
              return ModernSettingCard(
                title: appLocalizations.autoCloseConnections,
                subtitle: appLocalizations.autoCloseConnectionsDesc,
                value: closeConnections,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(closeConnections: value),
                  );
                },
                icon: _getIconForSetting('closeConnections'),
                color: _getColorForSetting('closeConnections'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.5, 0.7, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Statistics proxy setting
          Consumer(
            builder: (context, ref, _) {
              final onlyStatisticsProxy = ref.watch(
                appSettingProvider.select((state) => state.onlyStatisticsProxy),
              );
              return ModernSettingCard(
                title: appLocalizations.onlyStatisticsProxy,
                subtitle: appLocalizations.onlyStatisticsProxyDesc,
                value: onlyStatisticsProxy,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(onlyStatisticsProxy: value),
                  );
                },
                icon: _getIconForSetting('statistics'),
                color: _getColorForSetting('statistics'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.55, 0.75, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
          
          // Auto check updates setting
          Consumer(
            builder: (context, ref, _) {
              final autoCheckUpdate = ref.watch(
                appSettingProvider.select((state) => state.autoCheckUpdate),
              );
              return ModernSettingCard(
                title: appLocalizations.autoCheckUpdate,
                subtitle: appLocalizations.autoCheckUpdateDesc,
                value: autoCheckUpdate,
                onChanged: (value) {
                  ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(autoCheckUpdate: value),
                  );
                },
                icon: _getIconForSetting('update'),
                color: _getColorForSetting('update'),
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.6, 0.8, curve: Curves.easeOutBack),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
