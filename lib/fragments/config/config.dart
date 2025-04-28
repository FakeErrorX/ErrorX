import 'dart:io';
import 'package:errorx/common/common.dart';
import 'package:errorx/fragments/config/dns.dart';
import 'package:errorx/fragments/config/general.dart';
import 'package:errorx/fragments/config/network.dart';
import 'package:errorx/models/clash_config.dart';
import 'package:errorx/providers/config.dart' show patchClashConfigProvider;
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state.dart';

class ConfigFragment extends StatefulWidget {
  const ConfigFragment({super.key});

  @override
  State<ConfigFragment> createState() => _ConfigFragmentState();
}

class _ConfigFragmentState extends State<ConfigFragment> with SingleTickerProviderStateMixin {
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
                      Icons.tune_rounded,
                      size: 48,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appLocalizations.basicConfig,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.basicConfigDesc,
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
          
          // General Settings
          _ConfigCard(
            title: appLocalizations.general,
            subtitle: appLocalizations.generalDesc,
            icon: Icons.build_rounded,
            iconColor: Colors.blue.shade600,
            animationController: _animationController,
            animationIndex: 0,
            delegate: OpenDelegate(
              title: appLocalizations.general,
              widget: generateGeneralView(),
              blur: false,
            ),
          ),
          
          // Network Settings
          _ConfigCard(
            title: appLocalizations.network,
            subtitle: appLocalizations.networkDesc,
            icon: Icons.vpn_key_rounded,
            iconColor: Colors.green.shade600,
            animationController: _animationController,
            animationIndex: 1,
            delegate: OpenDelegate(
              title: appLocalizations.network,
              blur: false,
              widget: const NetworkListView(),
            ),
          ),
          
          // DNS Settings
          _ConfigCard(
            title: "DNS",
            subtitle: appLocalizations.dnsDesc,
            icon: Icons.dns_rounded,
            iconColor: Colors.purple.shade600,
            animationController: _animationController,
            animationIndex: 2,
            delegate: OpenDelegate(
              title: "DNS",
              action: Consumer(builder: (_, ref, __) {
                return IconButton(
                  onPressed: () async {
                    final res = await globalState.showMessage(
                      title: appLocalizations.reset,
                      message: TextSpan(
                        text: appLocalizations.resetTip,
                      ),
                    );
                    if (res != true) {
                      return;
                    }
                    ref.read(patchClashConfigProvider.notifier).updateState(
                          (state) => state.copyWith(
                            dns: defaultDns,
                          ),
                        );
                  },
                  tooltip: appLocalizations.reset,
                  icon: const Icon(
                    Icons.replay,
                  ),
                );
              }),
              widget: const DnsListView(),
              blur: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final OpenDelegate delegate;
  final AnimationController animationController;
  final int animationIndex;

  const _ConfigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.delegate,
    required this.animationController,
    required this.animationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.2 + (animationIndex * 0.1),
        0.5 + (animationIndex * 0.1),
        curve: Curves.easeOutBack,
      ),
    );

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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
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
                        body: delegate.widget,
                        title: delegate.title,
                      );
                    },
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommonScaffold.open(
                        key: Key(delegate.title),
                        onBack: () => Navigator.of(context).pop(),
                        title: delegate.title,
                        body: SafeArea(child: delegate.widget),
                      ),
                    ),
                  );
                }
              },
              splashColor: iconColor.withOpacity(0.1),
              highlightColor: iconColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
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
    );
  }
}
