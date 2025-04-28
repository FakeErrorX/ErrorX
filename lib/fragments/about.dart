import 'dart:math';
import 'package:errorx/common/common.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

@immutable
class Contributor {
  final String avatar;
  final String name;
  final String link;
  final String role;

  const Contributor({
    required this.avatar,
    required this.name,
    required this.link,
    required this.role,
  });
}

class AboutFragment extends StatefulWidget {
  const AboutFragment({super.key});

  @override
  State<AboutFragment> createState() => _AboutFragmentState();
}

class _AboutFragmentState extends State<AboutFragment> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showVersionEasterEgg = false;
  int _tapCount = 0;
  
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

  _checkUpdate(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    if (commonScaffoldState?.mounted != true) return;
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    final data = await commonScaffoldState?.loadingRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
    );
    globalState.appController.checkUpdateResultHandle(
      data: data,
      handleError: true,
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
    int index = 0,
  }) {
    // Ensure the end value never exceeds 1.0
    final double start = min(0.05 * index, 0.6);
    final double end = min(0.7, start + 0.3);
    
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        start, 
        end,
        curve: Curves.easeOutQuint,
      ),
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.06),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: color.withOpacity(0.1),
              highlightColor: color.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: context.colorScheme.onSurfaceVariant,
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

  Widget _buildMoreSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 16, bottom: 4),
          child: Text(
            appLocalizations.more.toUpperCase(),
            style: TextStyle(
              color: context.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildActionCard(
          title: appLocalizations.checkUpdate,
          subtitle: "Check for the latest version",
          icon: Icons.system_update_rounded,
          color: Colors.blue.shade600,
          index: 0,
          onTap: () => _checkUpdate(context),
        ),
        _buildActionCard(
          title: "Website",
          subtitle: "Visit our official website",
          icon: Icons.language_rounded,
          color: Colors.teal.shade600,
          index: 1,
          onTap: () {
            globalState.openUrl("https://errorx.net");
          },
        ),
        _buildActionCard(
          title: "Facebook",
          subtitle: "Follow us on Facebook",
          icon: Icons.facebook_rounded,
          color: Colors.blue.shade800,
          index: 2,
          onTap: () {
            globalState.openUrl("https://facebook.com/ErrorX.gg");
          },
        ),
        _buildActionCard(
          title: "Telegram",
          subtitle: "Join our Telegram community",
          icon: Icons.telegram_rounded,
          color: Colors.lightBlue.shade600,
          index: 3,
          onTap: () {
            globalState.openUrl("https://t.me/ErrorX_BD");
          },
        ),
        _buildActionCard(
          title: "Discord",
          subtitle: "Join our Discord server",
          icon: Icons.discord_rounded,
          color: Colors.deepPurple.shade500,
          index: 4,
          onTap: () {
            globalState.openUrl("https://discord.gg/sG8FYe8Npf");
          },
        ),
        _buildActionCard(
          title: appLocalizations.project,
          subtitle: "View source code on GitHub",
          icon: Icons.code_rounded,
          color: Colors.purple.shade600,
          index: 5,
          onTap: () {
            globalState.openUrl("https://github.com/$repository");
          },
        ),
        _buildActionCard(
          title: appLocalizations.core,
          subtitle: "Explore the core engine",
          icon: Icons.settings_ethernet_rounded,
          color: Colors.green.shade600,
          index: 6,
          onTap: () {
            globalState.openUrl("https://github.com/FakeErrorX/Clash.Meta");
          },
        ),
      ],
    );
  }

  List<Widget> _buildContributorsSection() {
    const contributors = [
      Contributor(
        avatar: "assets/images/avatars/errorx.jpg",
        name: "ErrorX",
        link: "https://t.me/FakeErrorX",
        role: "Team Lead / Full-stack",
      ),
      Contributor(
        avatar: "assets/images/avatars/revilx.jpg",
        name: "REvilX",
        link: "https://t.me/REvilX",
        role: "Backend Developer",
      ),
      Contributor(
        avatar: "assets/images/avatars/smraaz.jpg",
        name: "Your Raaz",
        link: "https://t.me/smraaz",
        role: "UI/UX Designer",
      ),
      Contributor(
        avatar: "assets/images/avatars/inhumantt.jpg",
        name: "Kaniel Outis",
        link: "https://t.me/inhumantt",
        role: "Contributor",
      ),
      Contributor(
        avatar: "assets/images/avatars/Ninja2249.jpg",
        name: "Ninja",
        link: "https://t.me/Ninja2249",
        role: "Contributor",
      ),
      Contributor(
        avatar: "assets/images/avatars/Vampire.jpg",
        name: "Vampire",
        link: "https://t.me/vampirerrors",
        role: "Contributor",
      ),
    ];
    
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
    
    return [
      FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  "Development Team",
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                InfiniteScrollContributors(
                  contributors: contributors,
                  animationController: _animationController,
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Header animation
    final headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuint),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          children: [
          // App Header with Logo
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(headerAnimation),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(headerAnimation),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
              children: [
                    // App Logo with pulse animation
                    GestureDetector(
                      onTap: () {
                        _tapCount++;
                        if (_tapCount >= 5) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _showVersionEasterEgg = !_showVersionEasterEgg;
                            _tapCount = 0;
                          });
                        } else {
                          HapticFeedback.lightImpact();
                        }
                      },
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 64,
                    height: 64,
                  ),
                ),
                    const SizedBox(height: 12),
                    // App Name and Version
                    Text(
                      appName,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showVersionEasterEgg 
                          ? "Build with ❤️ by ErrorX Team"
                          : "Version ${globalState.packageInfo.version}",
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
              appLocalizations.desc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
            ),
          ],
        ),
      ),
            ),
      ),
          
          // Contributors
      ..._buildContributorsSection(),
          
          // Actions
          _buildMoreSection(context),
        ],
      ),
    );
  }
}

class ModernAvatar extends StatelessWidget {
  final Contributor contributor;
  final int index;
  final AnimationController animationController;

  const ModernAvatar({
    super.key,
    required this.contributor,
    required this.index,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the end value never exceeds 1.0
    final double start = min(0.4 + (0.05 * index), 0.6);
    final double end = min(0.9, start + 0.3);
    
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutBack,
      ),
    );
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.5 + (0.1 * min(index, 5))),
          end: Offset.zero,
        ).animate(animation),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          splashColor: context.colorScheme.primary.withOpacity(0.1),
          onTap: () {
            HapticFeedback.selectionClick();
            globalState.openUrl(contributor.link);
          },
      child: Column(
        children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colorScheme.shadow.withOpacity(0.15),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                contributor.avatar,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contributor.name,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              Text(
                contributor.role,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.primary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfiniteScrollContributors extends StatefulWidget {
  final List<Contributor> contributors;
  final AnimationController animationController;

  const InfiniteScrollContributors({
    Key? key,
    required this.contributors,
    required this.animationController,
  }) : super(key: key);

  @override
  _InfiniteScrollContributorsState createState() => _InfiniteScrollContributorsState();
}

class _InfiniteScrollContributorsState extends State<InfiniteScrollContributors> {
  late ScrollController _scrollController;
  late Timer _timer;
  final double _scrollSpeed = 15.0; // Pixels per second
  final int _scrollDuration = 16; // Milliseconds between each scroll

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Delay starting the animation until the initial build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }
  
  void _startScrolling() {
    _timer = Timer.periodic(Duration(milliseconds: _scrollDuration), (timer) {
      if (!mounted) return;
      
      final double maxExtent = _scrollController.position.maxScrollExtent;
      final double currentPosition = _scrollController.position.pixels;
      final double step = _scrollSpeed * _scrollDuration / 1000;
      
      // Reset to beginning when we reach the end
      if (currentPosition >= maxExtent) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          currentPosition + step,
          duration: Duration(milliseconds: _scrollDuration),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Fixed height for the scrolling area
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Repeat the list multiple times to create a longer looping effect
            ...List.generate(5, (_) => 
              Row(
                children: List.generate(widget.contributors.length, (i) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ModernAvatar(
                      contributor: widget.contributors[i],
                      index: i,
                      animationController: widget.animationController,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
