import 'dart:io';
import 'dart:math';

import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class VPNItem extends ConsumerWidget {
  const VPNItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enable =
        ref.watch(vpnSettingProvider.select((state) => state.enable));
    return ListItem.switchItem(
      title: const Text("VPN"),
      subtitle: Text(appLocalizations.vpnEnableDesc),
      delegate: SwitchDelegate(
        value: enable,
        onChanged: (value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  enable: value,
                ),
              );
        },
      ),
    );
  }
}

class TUNItem extends ConsumerWidget {
  const TUNItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enable =
        ref.watch(patchClashConfigProvider.select((state) => state.tun.enable));

    return ListItem.switchItem(
      title: Text(appLocalizations.tun),
      subtitle: Text(appLocalizations.tunDesc),
      delegate: SwitchDelegate(
        value: enable,
        onChanged: (value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith.tun(
                  enable: value,
                ),
              );
        },
      ),
    );
  }
}

class AllowBypassItem extends ConsumerWidget {
  const AllowBypassItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final allowBypass =
        ref.watch(vpnSettingProvider.select((state) => state.allowBypass));
    return ListItem.switchItem(
      title: Text(appLocalizations.allowBypass),
      subtitle: Text(appLocalizations.allowBypassDesc),
      delegate: SwitchDelegate(
        value: allowBypass,
        onChanged: (bool value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  allowBypass: value,
                ),
              );
        },
      ),
    );
  }
}

class VpnSystemProxyItem extends ConsumerWidget {
  const VpnSystemProxyItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final systemProxy =
        ref.watch(vpnSettingProvider.select((state) => state.systemProxy));
    return ListItem.switchItem(
      title: Text(appLocalizations.systemProxy),
      subtitle: Text(appLocalizations.systemProxyDesc),
      delegate: SwitchDelegate(
        value: systemProxy,
        onChanged: (bool value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  systemProxy: value,
                ),
              );
        },
      ),
    );
  }
}

class SystemProxyItem extends ConsumerWidget {
  const SystemProxyItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final systemProxy =
        ref.watch(networkSettingProvider.select((state) => state.systemProxy));

    return ListItem.switchItem(
      title: Text(appLocalizations.systemProxy),
      subtitle: Text(appLocalizations.systemProxyDesc),
      delegate: SwitchDelegate(
        value: systemProxy,
        onChanged: (bool value) async {
          ref.read(networkSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  systemProxy: value,
                ),
              );
        },
      ),
    );
  }
}

class Ipv6Item extends ConsumerWidget {
  const Ipv6Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ipv6 = ref.watch(vpnSettingProvider.select((state) => state.ipv6));
    return ListItem.switchItem(
      title: const Text("IPv6"),
      subtitle: Text(appLocalizations.ipv6InboundDesc),
      delegate: SwitchDelegate(
        value: ipv6,
        onChanged: (bool value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  ipv6: value,
                ),
              );
        },
      ),
    );
  }
}

class TunStackItem extends ConsumerWidget {
  const TunStackItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final stack =
        ref.watch(patchClashConfigProvider.select((state) => state.tun.stack));

    return ListItem.options(
      title: Text(appLocalizations.stackMode),
      subtitle: Text(stack.name),
      delegate: OptionsDelegate<TunStack>(
        value: stack,
        options: TunStack.values,
        textBuilder: (value) => value.name,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith.tun(
                  stack: value,
                ),
              );
        },
        title: appLocalizations.stackMode,
      ),
    );
  }
}

class BypassDomainItem extends StatelessWidget {
  const BypassDomainItem({super.key});

  _initActions(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.commonScaffoldState?.actions = [
        IconButton(
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
            ref.read(networkSettingProvider.notifier).updateState(
                  (state) => state.copyWith(
                    bypassDomain: defaultBypassDomain,
                  ),
                );
          },
          tooltip: appLocalizations.reset,
          icon: const Icon(
            Icons.replay,
          ),
        )
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.bypassDomain),
      subtitle: Text(appLocalizations.bypassDomainDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.bypassDomain,
        widget: Consumer(
          builder: (_, ref, __) {
            _initActions(context, ref);
            final bypassDomain = ref.watch(
                networkSettingProvider.select((state) => state.bypassDomain));
            return ListInputPage(
              title: appLocalizations.bypassDomain,
              items: bypassDomain,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref.read(networkSettingProvider.notifier).updateState(
                      (state) => state.copyWith(
                        bypassDomain: List.from(items),
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}

class RouteModeItem extends ConsumerWidget {
  const RouteModeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final routeMode =
        ref.watch(networkSettingProvider.select((state) => state.routeMode));
    return ListItem<RouteMode>.options(
      title: Text(appLocalizations.routeMode),
      subtitle: Text(Intl.message("routeMode_${routeMode.name}")),
      delegate: OptionsDelegate<RouteMode>(
        title: appLocalizations.routeMode,
        options: RouteMode.values,
        onChanged: (RouteMode? value) {
          if (value == null) {
            return;
          }
          ref.read(networkSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  routeMode: value,
                ),
              );
        },
        textBuilder: (routeMode) => Intl.message(
          "routeMode_${routeMode.name}",
        ),
        value: routeMode,
      ),
    );
  }
}

class RouteAddressItem extends ConsumerWidget {
  const RouteAddressItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final bypassPrivate = ref.watch(networkSettingProvider
        .select((state) => state.routeMode == RouteMode.bypassPrivate));
    if (bypassPrivate) {
      return Container();
    }
    return ListItem.open(
      title: Text(appLocalizations.routeAddress),
      subtitle: Text(appLocalizations.routeAddressDesc),
      delegate: OpenDelegate(
        blur: false,
        maxWidth: 360,
        title: appLocalizations.routeAddress,
        widget: Consumer(
          builder: (_, ref, __) {
            final routeAddress = ref.watch(patchClashConfigProvider
                .select((state) => state.tun.routeAddress));
            return ListInputPage(
              title: appLocalizations.routeAddress,
              items: routeAddress,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith.tun(
                        routeAddress: List.from(items),
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}

final networkItems = [
  if (Platform.isAndroid) const VPNItem(),
  if (Platform.isAndroid)
    ...generateSection(
      title: "VPN",
      items: [
        const VpnSystemProxyItem(),
        const BypassDomainItem(),
        const AllowBypassItem(),
        const Ipv6Item(),
      ],
    ),
  if (system.isDesktop)
    ...generateSection(
      title: appLocalizations.system,
      items: [
        SystemProxyItem(),
        BypassDomainItem(),
      ],
    ),
  ...generateSection(
    title: appLocalizations.options,
    items: [
      if (system.isDesktop) const TUNItem(),
      const TunStackItem(),
      const RouteModeItem(),
      const RouteAddressItem(),
    ],
  ),
];

class NetworkListView extends ConsumerStatefulWidget {
  const NetworkListView({super.key});

  @override
  ConsumerState<NetworkListView> createState() => _NetworkListViewState();
}

class _NetworkListViewState extends ConsumerState<NetworkListView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _initActions();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _initActions() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.commonScaffoldState?.actions = [
        IconButton(
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
            ref.read(vpnSettingProvider.notifier).updateState(
                  (state) => defaultVpnProps,
                );
            ref.read(patchClashConfigProvider.notifier).updateState(
                  (state) => state.copyWith(
                    tun: defaultTun,
                  ),
                );
          },
          tooltip: appLocalizations.reset,
          icon: const Icon(
            Icons.replay,
          ),
        )
      ];
    });
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
                      Icons.router_rounded,
                      size: 48,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appLocalizations.network,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.networkDesc,
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
          
          // VPN Section (Android Only)
          if (Platform.isAndroid) ...[
            _buildSectionHeader(
              title: "VPN",
              icon: Icons.vpn_lock_rounded,
              color: Colors.indigo.shade600,
              animationIndex: 0,
            ),
            _ModernSwitchCard(
              title: "VPN",
              subtitle: appLocalizations.vpnEnableDesc,
              icon: Icons.vpn_key_rounded,
              iconColor: Colors.indigo.shade600,
              animationController: _animationController,
              animationIndex: 1,
              valueProvider: (ref) => ref.watch(vpnSettingProvider.select((state) => state.enable)),
              onChanged: (value) {
                ref.read(vpnSettingProvider.notifier).updateState(
                  (state) => state.copyWith(enable: value),
                );
              },
            ),
            _ModernSwitchCard(
              title: appLocalizations.systemProxy,
              subtitle: appLocalizations.systemProxyDesc,
              icon: Icons.phonelink_setup_rounded,
              iconColor: Colors.blue.shade600,
              animationController: _animationController,
              animationIndex: 2,
              valueProvider: (ref) => ref.watch(vpnSettingProvider.select((state) => state.systemProxy)),
              onChanged: (value) {
                ref.read(vpnSettingProvider.notifier).updateState(
                  (state) => state.copyWith(systemProxy: value),
                );
              },
            ),
            _ModernNavigationCard(
              title: appLocalizations.bypassDomain,
              subtitle: appLocalizations.bypassDomainDesc,
              icon: Icons.domain_verification_rounded,
              iconColor: Colors.green.shade600,
              animationController: _animationController,
              animationIndex: 3,
              onTap: () {
                final delegate = OpenDelegate(
                  blur: false,
                  title: appLocalizations.bypassDomain,
                  widget: Consumer(
                    builder: (_, ref, __) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        context.commonScaffoldState?.actions = [
                          IconButton(
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
                              ref.read(networkSettingProvider.notifier).updateState(
                                    (state) => state.copyWith(
                                      bypassDomain: defaultBypassDomain,
                                    ),
                                  );
                            },
                            tooltip: appLocalizations.reset,
                            icon: const Icon(
                              Icons.replay,
                            ),
                          )
                        ];
                      });
                      
                      final bypassDomain = ref.watch(
                        networkSettingProvider.select((state) => state.bypassDomain)
                      );
                      return ListInputPage(
                        title: appLocalizations.bypassDomain,
                        items: bypassDomain,
                        titleBuilder: (item) => Text(item),
                        onChange: (items) {
                          ref.read(networkSettingProvider.notifier).updateState(
                            (state) => state.copyWith(
                              bypassDomain: List.from(items),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
                
                final isMobile = Platform.isAndroid || Platform.isIOS;
                if (!isMobile) {
                  showExtend(
                    context,
                    props: ExtendProps(blur: true),
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
            ),
            _ModernSwitchCard(
              title: appLocalizations.allowBypass,
              subtitle: appLocalizations.allowBypassDesc,
              icon: Icons.block_rounded,
              iconColor: Colors.orange.shade600,
              animationController: _animationController,
              animationIndex: 4,
              valueProvider: (ref) => ref.watch(vpnSettingProvider.select((state) => state.allowBypass)),
              onChanged: (value) {
                ref.read(vpnSettingProvider.notifier).updateState(
                  (state) => state.copyWith(allowBypass: value),
                );
              },
            ),
            _ModernSwitchCard(
              title: "IPv6",
              subtitle: appLocalizations.ipv6InboundDesc,
              icon: Icons.language_rounded,
              iconColor: Colors.purple.shade600,
              animationController: _animationController,
              animationIndex: 5,
              valueProvider: (ref) => ref.watch(vpnSettingProvider.select((state) => state.ipv6)),
              onChanged: (value) {
                ref.read(vpnSettingProvider.notifier).updateState(
                  (state) => state.copyWith(ipv6: value),
                );
              },
            ),
          ],
          
          // System Section (Desktop Only)
          if (system.isDesktop) ...[
            _buildSectionHeader(
              title: appLocalizations.system,
              icon: Icons.laptop_mac_rounded,
              color: Colors.teal.shade600,
              animationIndex: 6,
            ),
            _ModernSwitchCard(
              title: appLocalizations.systemProxy,
              subtitle: appLocalizations.systemProxyDesc,
              icon: Icons.computer_rounded,
              iconColor: Colors.teal.shade600,
              animationController: _animationController,
              animationIndex: 7,
              valueProvider: (ref) => ref.watch(networkSettingProvider.select((state) => state.systemProxy)),
              onChanged: (value) {
                ref.read(networkSettingProvider.notifier).updateState(
                  (state) => state.copyWith(systemProxy: value),
                );
              },
            ),
            _ModernNavigationCard(
              title: appLocalizations.bypassDomain,
              subtitle: appLocalizations.bypassDomainDesc,
              icon: Icons.domain_verification_rounded,
              iconColor: Colors.green.shade600,
              animationController: _animationController,
              animationIndex: 8,
              onTap: () {
                final delegate = OpenDelegate(
                  blur: false,
                  title: appLocalizations.bypassDomain,
                  widget: Consumer(
                    builder: (_, ref, __) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        context.commonScaffoldState?.actions = [
                          IconButton(
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
                              ref.read(networkSettingProvider.notifier).updateState(
                                    (state) => state.copyWith(
                                      bypassDomain: defaultBypassDomain,
                                    ),
                                  );
                            },
                            tooltip: appLocalizations.reset,
                            icon: const Icon(
                              Icons.replay,
                            ),
                          )
                        ];
                      });
                      
                      final bypassDomain = ref.watch(
                        networkSettingProvider.select((state) => state.bypassDomain)
                      );
                      return ListInputPage(
                        title: appLocalizations.bypassDomain,
                        items: bypassDomain,
                        titleBuilder: (item) => Text(item),
                        onChange: (items) {
                          ref.read(networkSettingProvider.notifier).updateState(
                            (state) => state.copyWith(
                              bypassDomain: List.from(items),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
                
                showExtend(
                  context,
                  props: ExtendProps(blur: true),
                  builder: (_, type) {
                    return AdaptiveSheetScaffold(
                      type: type,
                      body: delegate.widget,
                      title: delegate.title,
                    );
                  },
                );
              },
            ),
          ],
          
          // Options Section
          _buildSectionHeader(
            title: appLocalizations.options,
            icon: Icons.tune_rounded,
            color: Colors.amber.shade700,
            animationIndex: 9,
          ),
          
          if (system.isDesktop)
            _ModernSwitchCard(
              title: appLocalizations.tun,
              subtitle: appLocalizations.tunDesc,
              icon: Icons.settings_ethernet_rounded,
              iconColor: Colors.pink.shade600,
              animationController: _animationController,
              animationIndex: 10,
              valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.tun.enable)),
              onChanged: (value) {
                ref.read(patchClashConfigProvider.notifier).updateState(
                  (state) => state.copyWith.tun(enable: value),
                );
              },
            ),
          
          _ModernOptionsCard<TunStack>(
            title: appLocalizations.stackMode,
            subtitle: ref.watch(patchClashConfigProvider.select((state) => state.tun.stack.name)),
            icon: Icons.layers_rounded,
            iconColor: Colors.blue.shade600,
            animationController: _animationController,
            animationIndex: 11,
            value: ref.watch(patchClashConfigProvider.select((state) => state.tun.stack)),
            options: TunStack.values,
            textBuilder: (value) => value.name,
            onChanged: (value) {
              if (value == null) return;
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith.tun(stack: value),
              );
            },
            optionsTitle: appLocalizations.stackMode,
          ),
          
          _ModernOptionsCard<RouteMode>(
            title: appLocalizations.routeMode,
            subtitle: Intl.message("routeMode_${ref.watch(networkSettingProvider.select((state) => state.routeMode.name))}"),
            icon: Icons.route_rounded,
            iconColor: Colors.deepPurple.shade600,
            animationController: _animationController,
            animationIndex: 12,
            value: ref.watch(networkSettingProvider.select((state) => state.routeMode)),
            options: RouteMode.values,
            textBuilder: (routeMode) => Intl.message("routeMode_${routeMode.name}"),
            onChanged: (value) {
              if (value == null) return;
              ref.read(networkSettingProvider.notifier).updateState(
                (state) => state.copyWith(routeMode: value),
              );
            },
            optionsTitle: appLocalizations.routeMode,
          ),
          
          Consumer(
            builder: (context, ref, _) {
              final bypassPrivate = ref.watch(networkSettingProvider
                  .select((state) => state.routeMode == RouteMode.bypassPrivate));
              if (bypassPrivate) {
                return SizedBox.shrink();
              }
              
              return _ModernNavigationCard(
                title: appLocalizations.routeAddress,
                subtitle: appLocalizations.routeAddressDesc,
                icon: Icons.alt_route_rounded,
                iconColor: Colors.green.shade600,
                animationController: _animationController,
                animationIndex: 13,
                onTap: () {
                  final delegate = OpenDelegate(
                    blur: false,
                    maxWidth: 360,
                    title: appLocalizations.routeAddress,
                    widget: Consumer(
                      builder: (_, ref, __) {
                        final routeAddress = ref.watch(patchClashConfigProvider
                            .select((state) => state.tun.routeAddress));
                        return ListInputPage(
                          title: appLocalizations.routeAddress,
                          items: routeAddress,
                          titleBuilder: (item) => Text(item),
                          onChange: (items) {
                            ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.tun(
                                routeAddress: List.from(items),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                  
                  final isMobile = Platform.isAndroid || Platform.isIOS;
                  if (!isMobile) {
                    showExtend(
                      context,
                      props: ExtendProps(blur: true),
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
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int animationIndex,
  }) {
    // Cap the animation values to prevent exceeding 1.0
    final double start = min(0.1 + (animationIndex * 0.03), 0.7);
    final double end = min(0.4 + (animationIndex * 0.03), 0.9);
    
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOut,
      ),
    );
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
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
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernSwitchCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final AnimationController animationController;
  final int animationIndex;
  final bool Function(WidgetRef) valueProvider;
  final Function(bool) onChanged;

  const _ModernSwitchCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.animationController,
    required this.animationIndex,
    required this.valueProvider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cap the animation values to prevent exceeding 1.0
    final double start = min(0.2 + (animationIndex * 0.03), 0.7);
    final double end = min(0.5 + (animationIndex * 0.03), 0.95);
    
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutBack,
      ),
    );
    
    final value = valueProvider(ref);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernNavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final AnimationController animationController;
  final int animationIndex;
  final VoidCallback onTap;

  const _ModernNavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.animationController,
    required this.animationIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cap the animation values to prevent exceeding 1.0
    final double start = min(0.2 + (animationIndex * 0.03), 0.7);
    final double end = min(0.5 + (animationIndex * 0.03), 0.95);
    
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutBack,
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
              onTap: onTap,
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

class _ModernOptionsCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final AnimationController animationController;
  final int animationIndex;
  final T value;
  final List<T> options;
  final String Function(T) textBuilder;
  final Function(T?) onChanged;
  final String optionsTitle;

  const _ModernOptionsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.animationController,
    required this.animationIndex,
    required this.value,
    required this.options,
    required this.textBuilder,
    required this.onChanged,
    required this.optionsTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Cap the animation values to prevent exceeding 1.0
    final double start = min(0.2 + (animationIndex * 0.03), 0.7);
    final double end = min(0.5 + (animationIndex * 0.03), 0.95);
    
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutBack,
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
            child: ListItem.options(
              leading: Container(
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
              title: Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              delegate: OptionsDelegate<T>(
                value: value,
                options: options,
                textBuilder: textBuilder,
                onChanged: onChanged,
                title: optionsTitle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
