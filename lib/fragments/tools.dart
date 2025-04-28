import 'dart:io';
import 'dart:ui';
import 'package:errorx/common/common.dart';
import 'package:errorx/fragments/about.dart';
import 'package:errorx/fragments/access.dart';
import 'package:errorx/fragments/account.dart';
import 'package:errorx/fragments/application_setting.dart';
import 'package:errorx/fragments/config/config.dart';
import 'package:errorx/fragments/hotkey.dart';
import 'package:errorx/l10n/l10n.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/pages/login.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/services/api_service.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'package:path/path.dart' show dirname, join;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToolsFragment extends ConsumerStatefulWidget {
  const ToolsFragment({super.key});

  @override
  ConsumerState<ToolsFragment> createState() => _ToolboxFragmentState();
}

class _ToolboxFragmentState extends ConsumerState<ToolsFragment> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // Setup logout callback
    _apiService.setLogoutCallback((reason) {
      if (mounted) {
        // If reason is empty, it's a manual logout, don't show notification
        if (reason.isNotEmpty) {
          // Show notification for non-manual logout
          globalState.showMessage(
            title: "Session Ended",
            message: TextSpan(text: reason),
          );
        }
        
        // Return to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  _buildNavigationMenuItem(NavigationItem navigationItem, int index) {
    // Staggered animation effect
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.1 * index, // Stagger start times
        1.0,
        curve: Curves.easeOutQuint,
      ),
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.07),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: context.colorScheme.primary.withOpacity(0.1),
                highlightColor: context.colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Use existing open navigation from ListItem.open
                  final openDelegate = OpenDelegate(
                    title: Intl.message(navigationItem.label.name),
                    widget: navigationItem.fragment,
                  );
                  
                  final isMobile = Platform.isAndroid || Platform.isIOS;
                  if (!isMobile) {
                    showExtend(
                      context,
                      props: ExtendProps(
                        blur: true,
                      ),
                      builder: (_, type) {
                        return AdaptiveSheetScaffold(
                          type: type,
                          body: navigationItem.fragment,
                          title: Intl.message(navigationItem.label.name),
                        );
                      },
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommonScaffold.open(
                          key: Key(Intl.message(navigationItem.label.name)),
                          onBack: () => Navigator.of(context).pop(),
                          title: Intl.message(navigationItem.label.name),
                          body: SafeArea(child: navigationItem.fragment),
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Icon with glowing effect
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: context.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: navigationItem.icon,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Intl.message(navigationItem.label.name),
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (navigationItem.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                Intl.message(navigationItem.description!),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationMenu(List<NavigationItem> navigationItems) {
    return Column(
      children: [
        for (int i = 0; i < navigationItems.length; i++)
          _buildNavigationMenuItem(navigationItems[i], i),
      ],
    );
  }

  List<Widget> _getOtherList() {
    return generateSection(
      title: appLocalizations.other,
      items: [
        _ModernItem(
          icon: Icons.description,
          iconColor: Colors.blue.shade700,
          title: "Docs",
          subtitle: "View documentation and guides",
          index: 0,
          animationController: _animationController,
          onTap: () async {
            await launchUrl(Uri.parse("https://errorx.net/docs"));
          },
        ),
        _ModernItem(
          icon: Icons.info_rounded,
          iconColor: Colors.indigo.shade700,
          title: appLocalizations.about,
          subtitle: "App information and version details",
          index: 1,
          animationController: _animationController,
          delegate: OpenDelegate(
            title: appLocalizations.about,
            widget: const AboutFragment(),
          ),
        ),
        _ModernItem(
          icon: Icons.logout_rounded,
          iconColor: Colors.red.shade600,
          title: "Logout",
          subtitle: "Sign out from the application",
          index: 2,
          animationController: _animationController,
          onTap: () async {
            final confirm = await globalState.showMessage(
              title: "Confirm Logout",
              message: const TextSpan(text: "Are you sure you want to logout?"),
              confirmText: "Logout",
            );
            
            if (confirm == true) {
              // Instead of using showLoading/hideLoading, just call logout
              // The navigation will be handled by the logout callback
              await _apiService.logout();
            }
          },
        ),
      ],
      separated: false,
    );
  }

  _getSettingList() {
    return generateSection(
      title: appLocalizations.settings,
      items: [
        _ModernItem(
          icon: Icons.account_circle_rounded,
          iconColor: Colors.indigo.shade600,
          title: "Account",
          subtitle: "View license and subscription information",
          index: 0,
          animationController: _animationController,
          delegate: OpenDelegate(
            title: "Account",
            widget: const AccountFragment(),
          ),
        ),
        _ModernItem(
          icon: Icons.palette_rounded,
          iconColor: Colors.purple.shade600,
          title: appLocalizations.theme,
          subtitle: appLocalizations.themeDesc,
          index: 1,
          animationController: _animationController,
          delegate: OpenDelegate(
            title: appLocalizations.theme,
            widget: const ThemeFragment(),
          ),
        ),
        if (system.isDesktop)
          _ModernItem(
            icon: Icons.keyboard_rounded,
            iconColor: Colors.teal.shade600,
            title: appLocalizations.hotkeyManagement,
            subtitle: appLocalizations.hotkeyManagementDesc,
            index: 2,
            animationController: _animationController,
            delegate: OpenDelegate(
              title: appLocalizations.hotkeyManagement,
              widget: const HotKeyFragment(),
            ),
          ),
        if (Platform.isWindows)
          _ModernItem(
            icon: Icons.admin_panel_settings_rounded,
            iconColor: Colors.amber.shade800,
            title: appLocalizations.loopback,
            subtitle: appLocalizations.loopbackDesc,
            index: 3,
            animationController: _animationController,
            onTap: () {
              windows?.runas(
                '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
                "",
              );
            },
          ),
        if (Platform.isAndroid)
          _ModernItem(
            icon: Icons.app_blocking_rounded,
            iconColor: Colors.pink.shade600,
            title: appLocalizations.accessControl,
            subtitle: appLocalizations.accessControlDesc,
            index: 4,
            animationController: _animationController,
            delegate: OpenDelegate(
              title: appLocalizations.appAccessControl,
              widget: const AccessFragment(),
            ),
          ),
        _ModernItem(
          icon: Icons.edit_note_rounded,
          iconColor: Colors.green.shade600,
          title: appLocalizations.basicConfig,
          subtitle: appLocalizations.basicConfigDesc,
          index: 5,
          animationController: _animationController,
          delegate: OpenDelegate(
            title: appLocalizations.override,
            widget: const ConfigFragment(),
          ),
        ),
        _ModernItem(
          icon: Icons.settings_rounded,
          iconColor: Colors.blue.shade600,
          title: appLocalizations.application,
          subtitle: appLocalizations.applicationDesc,
          index: 6,
          animationController: _animationController,
          delegate: OpenDelegate(
            title: appLocalizations.application,
            widget: const ApplicationSettingFragment(),
          ),
        ),
      ],
      separated: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      Consumer(
        builder: (_, ref, __) {
          final state = ref.watch(moreToolsSelectorStateProvider);
          if (state.navigationItems.isEmpty) {
            return Container();
          }
          return Column(
            children: [
              _AnimatedHeader(
                title: appLocalizations.more,
                animationController: _animationController,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNavigationMenu(state.navigationItems),
              ),
            ],
          );
        },
      ),
      ..._getSettingList(),
      ..._getOtherList(),
    ];
    
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
        itemCount: items.length,
        itemBuilder: (_, index) => items[index],
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      ),
    );
  }
}

class _AnimatedHeader extends StatelessWidget {
  final String title;
  final AnimationController animationController;

  const _AnimatedHeader({
    required this.title,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final OpenDelegate? delegate;
  final Function()? onTap;
  final int index;
  final AnimationController animationController;

  const _ModernItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.animationController,
    this.delegate,
    this.onTap,
  }) : assert(delegate != null || onTap != null);

  @override
  Widget build(BuildContext context) {
    // Staggered animation effect
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.1 * index, // Stagger start times
        1.0,
        curve: Curves.easeOutQuint,
      ),
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.07),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: iconColor.withOpacity(0.1),
                highlightColor: iconColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                onTap: delegate != null
                    ? () {
                        // Use existing open navigation
                        final isMobile = Platform.isAndroid || Platform.isIOS;
                        if (!isMobile) {
                          showExtend(
                            context,
                            props: ExtendProps(
                              blur: true,
                            ),
                            builder: (_, type) {
                              return AdaptiveSheetScaffold(
                                type: type,
                                body: delegate!.widget,
                                title: delegate!.title,
                              );
                            },
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommonScaffold.open(
                                key: Key(delegate!.title),
                                onBack: () => Navigator.of(context).pop(),
                                title: delegate!.title,
                                body: SafeArea(child: delegate!.widget),
                              ),
                            ),
                          );
                        }
                      }
                    : onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Icon with glowing effect
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 22,
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
                                letterSpacing: 0.2,
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
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
