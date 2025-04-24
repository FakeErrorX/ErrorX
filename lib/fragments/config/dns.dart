import 'dart:io';
import 'dart:math';
import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:errorx/models/clash_config.dart';
import '../../state.dart';

class OverrideItem extends ConsumerWidget {
  const OverrideItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final override = ref.watch(overrideDnsProvider);
    return ListItem.switchItem(
      title: Text(appLocalizations.overrideDns),
      subtitle: Text(appLocalizations.overrideDnsDesc),
      delegate: SwitchDelegate(
        value: override,
        onChanged: (bool value) async {
          ref.read(overrideDnsProvider.notifier).value = value;
        },
      ),
    );
  }
}

class StatusItem extends ConsumerWidget {
  const StatusItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enable =
        ref.watch(patchClashConfigProvider.select((state) => state.dns.enable));
    return ListItem.switchItem(
      title: Text(appLocalizations.status),
      subtitle: Text(appLocalizations.statusDesc),
      delegate: SwitchDelegate(
        value: enable,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(enable: value));
        },
      ),
    );
  }
}

class ListenItem extends ConsumerWidget {
  const ListenItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final listen =
        ref.watch(patchClashConfigProvider.select((state) => state.dns.listen));
    return ListItem.input(
      title: Text(appLocalizations.listen),
      subtitle: Text(listen),
      delegate: InputDelegate(
        title: appLocalizations.listen,
        value: listen,
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(listen: value));
        },
      ),
    );
  }
}

class PreferH3Item extends ConsumerWidget {
  const PreferH3Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final preferH3 = ref
        .watch(patchClashConfigProvider.select((state) => state.dns.preferH3));
    return ListItem.switchItem(
      title: const Text("PreferH3"),
      subtitle: Text(appLocalizations.preferH3Desc),
      delegate: SwitchDelegate(
        value: preferH3,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(preferH3: value));
        },
      ),
    );
  }
}

class IPv6Item extends ConsumerWidget {
  const IPv6Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ipv6 = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.ipv6),
    );
    return ListItem.switchItem(
      title: const Text("IPv6"),
      delegate: SwitchDelegate(
        value: ipv6,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(ipv6: value));
        },
      ),
    );
  }
}

class RespectRulesItem extends ConsumerWidget {
  const RespectRulesItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final respectRules = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.respectRules),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.respectRules),
      subtitle: Text(appLocalizations.respectRulesDesc),
      delegate: SwitchDelegate(
        value: respectRules,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(respectRules: value));
        },
      ),
    );
  }
}

class DnsModeItem extends ConsumerWidget {
  const DnsModeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enhancedMode = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.enhancedMode),
    );
    return ListItem<DnsMode>.options(
      title: Text(appLocalizations.dnsMode),
      subtitle: Text(enhancedMode.name),
      delegate: OptionsDelegate(
        title: appLocalizations.dnsMode,
        options: DnsMode.values,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(enhancedMode: value));
        },
        textBuilder: (dnsMode) => dnsMode.name,
        value: enhancedMode,
      ),
    );
  }
}

class FakeIpRangeItem extends ConsumerWidget {
  const FakeIpRangeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final fakeIpRange = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.fakeIpRange),
    );
    return ListItem.input(
      title: Text(appLocalizations.fakeipRange),
      subtitle: Text(fakeIpRange),
      delegate: InputDelegate(
        title: appLocalizations.fakeipRange,
        value: fakeIpRange,
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(fakeIpRange: value));
        },
      ),
    );
  }
}

class FakeIpFilterItem extends StatelessWidget {
  const FakeIpFilterItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.fakeipFilter),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.fakeipFilter,
        widget: Consumer(
          builder: (_, ref, __) {
            final fakeIpFilter = ref.watch(
              patchClashConfigProvider
                  .select((state) => state.dns.fakeIpFilter),
            );
            return ListInputPage(
              title: appLocalizations.fakeipFilter,
              items: fakeIpFilter,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref
                    .read(patchClashConfigProvider.notifier)
                    .updateState((state) => state.copyWith.dns(
                          fakeIpFilter: List.from(items),
                        ));
              },
            );
          },
        ),
      ),
    );
  }
}

class DefaultNameserverItem extends StatelessWidget {
  const DefaultNameserverItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.defaultNameserver),
      subtitle: Text(appLocalizations.defaultNameserverDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.defaultNameserver,
        widget: Consumer(builder: (_, ref, __) {
          final defaultNameserver = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.defaultNameserver),
          );
          return ListInputPage(
            title: appLocalizations.defaultNameserver,
            items: defaultNameserver,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      defaultNameserver: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class NameserverItem extends StatelessWidget {
  const NameserverItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.nameserver),
      subtitle: Text(appLocalizations.nameserverDesc),
      delegate: OpenDelegate(
        title: appLocalizations.nameserver,
        blur: false,
        widget: Consumer(builder: (_, ref, __) {
          final nameserver = ref.watch(
            patchClashConfigProvider.select((state) => state.dns.nameserver),
          );
          return ListInputPage(
            title: appLocalizations.nameserver,
            items: nameserver,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      nameserver: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class UseHostsItem extends ConsumerWidget {
  const UseHostsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final useHosts = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.useHosts),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.useHosts),
      delegate: SwitchDelegate(
        value: useHosts,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(useHosts: value));
        },
      ),
    );
  }
}

class UseSystemHostsItem extends ConsumerWidget {
  const UseSystemHostsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final useSystemHosts = ref.watch(
      patchClashConfigProvider.select((state) => state.dns.useSystemHosts),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.useSystemHosts),
      delegate: SwitchDelegate(
        value: useSystemHosts,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns(
                    useSystemHosts: value,
                  ));
        },
      ),
    );
  }
}

class NameserverPolicyItem extends StatelessWidget {
  const NameserverPolicyItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.nameserverPolicy),
      subtitle: Text(appLocalizations.nameserverPolicyDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.nameserverPolicy,
        widget: Consumer(builder: (_, ref, __) {
          final nameserverPolicy = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.nameserverPolicy),
          );
          return MapInputPage(
            title: appLocalizations.nameserverPolicy,
            map: nameserverPolicy,
            titleBuilder: (item) => Text(item.key),
            subtitleBuilder: (item) => Text(item.value),
            onChange: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      nameserverPolicy: value,
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class ProxyServerNameserverItem extends StatelessWidget {
  const ProxyServerNameserverItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.proxyNameserver),
      subtitle: Text(appLocalizations.proxyNameserverDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.proxyNameserver,
        widget: Consumer(
          builder: (_, ref, __) {
            final proxyServerNameserver = ref.watch(
              patchClashConfigProvider
                  .select((state) => state.dns.proxyServerNameserver),
            );
            return ListInputPage(
              title: appLocalizations.proxyNameserver,
              items: proxyServerNameserver,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith.dns(
                        proxyServerNameserver: List.from(items),
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

class FallbackItem extends StatelessWidget {
  const FallbackItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.fallback),
      subtitle: Text(appLocalizations.fallbackDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.fallback,
        widget: Consumer(builder: (_, ref, __) {
          final fallback = ref.watch(
            patchClashConfigProvider.select((state) => state.dns.fallback),
          );
          return ListInputPage(
            title: appLocalizations.fallback,
            items: fallback,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns(
                      fallback: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class GeoipItem extends ConsumerWidget {
  const GeoipItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final geoip = ref.watch(
      patchClashConfigProvider
          .select((state) => state.dns.fallbackFilter.geoip),
    );
    return ListItem.switchItem(
      title: const Text("Geoip"),
      delegate: SwitchDelegate(
        value: geoip,
        onChanged: (bool value) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState((state) => state.copyWith.dns.fallbackFilter(
                    geoip: value,
                  ));
        },
      ),
    );
  }
}

class GeoipCodeItem extends ConsumerWidget {
  const GeoipCodeItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final geoipCode = ref.watch(
      patchClashConfigProvider
          .select((state) => state.dns.fallbackFilter.geoipCode),
    );
    return ListItem.input(
      title: Text(appLocalizations.geoipCode),
      subtitle: Text(geoipCode),
      delegate: InputDelegate(
        title: appLocalizations.geoipCode,
        value: geoipCode,
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith.dns.fallbackFilter(
                  geoipCode: value,
                ),
              );
        },
      ),
    );
  }
}

class GeositeItem extends StatelessWidget {
  const GeositeItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: const Text("Geosite"),
      delegate: OpenDelegate(
        blur: false,
        title: "Geosite",
        widget: Consumer(builder: (_, ref, __) {
          final geosite = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.fallbackFilter.geosite),
          );
          return ListInputPage(
            title: "Geosite",
            items: geosite,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns.fallbackFilter(
                      geosite: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class IpcidrItem extends StatelessWidget {
  const IpcidrItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.ipcidr),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.ipcidr,
        widget: Consumer(builder: (_, ref, ___) {
          final ipcidr = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.fallbackFilter.ipcidr),
          );
          return ListInputPage(
            title: appLocalizations.ipcidr,
            items: ipcidr,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref
                  .read(patchClashConfigProvider.notifier)
                  .updateState((state) => state.copyWith.dns.fallbackFilter(
                        ipcidr: List.from(items),
                      ));
            },
          );
        }),
      ),
    );
  }
}

class DomainItem extends StatelessWidget {
  const DomainItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.domain),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.domain,
        widget: Consumer(builder: (_, ref, __) {
          final domain = ref.watch(
            patchClashConfigProvider
                .select((state) => state.dns.fallbackFilter.domain),
          );
          return ListInputPage(
            title: appLocalizations.domain,
            items: domain,
            titleBuilder: (item) => Text(item),
            onChange: (items) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith.dns.fallbackFilter(
                      domain: List.from(items),
                    ),
                  );
            },
          );
        }),
      ),
    );
  }
}

class DnsOptions extends StatelessWidget {
  const DnsOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: generateSection(
        title: appLocalizations.options,
        items: [
          const StatusItem(),
          const ListenItem(),
          const UseHostsItem(),
          const UseSystemHostsItem(),
          const IPv6Item(),
          const RespectRulesItem(),
          const PreferH3Item(),
          const DnsModeItem(),
          const FakeIpRangeItem(),
          const FakeIpFilterItem(),
          const DefaultNameserverItem(),
          const NameserverPolicyItem(),
          const NameserverItem(),
          const FallbackItem(),
          const ProxyServerNameserverItem(),
        ],
      ),
    );
  }
}

class FallbackFilterOptions extends StatelessWidget {
  const FallbackFilterOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: generateSection(
        title: appLocalizations.fallbackFilter,
        items: [
          const GeoipItem(),
          const GeoipCodeItem(),
          const GeositeItem(),
          const IpcidrItem(),
          const DomainItem(),
        ],
      ),
    );
  }
}

const dnsItems = <Widget>[
  OverrideItem(),
  DnsOptions(),
  FallbackFilterOptions(),
];

class DnsListView extends ConsumerStatefulWidget {
  const DnsListView({super.key});

  @override
  ConsumerState<DnsListView> createState() => _DnsListViewState();
}

class _DnsListViewState extends ConsumerState<DnsListView> with SingleTickerProviderStateMixin {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dns_rounded,
                          size: 48,
                          color: context.colorScheme.primary,
                        ),
                        const Spacer(),
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
                            ref.read(patchClashConfigProvider.notifier).updateState(
                                  (state) => state.copyWith(
                                    dns: defaultDns,
                                  ),
                                );
                          },
                          tooltip: appLocalizations.reset,
                          icon: const Icon(
                            Icons.replay,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "DNS",
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.dnsDesc,
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
          
          // Global setting
          _ModernSwitchCard(
            title: appLocalizations.overrideDns,
            subtitle: appLocalizations.overrideDnsDesc,
            icon: Icons.settings_applications_rounded,
            iconColor: Colors.indigo.shade600,
            animationController: _animationController,
            animationIndex: 0,
            valueProvider: (ref) => ref.watch(overrideDnsProvider),
            onChanged: (value) {
              ref.read(overrideDnsProvider.notifier).value = value;
            },
          ),
          
          // DNS Options section
          _buildSectionHeader(
            title: appLocalizations.options,
            icon: Icons.tune_rounded,
            color: Colors.blue.shade600,
            animationIndex: 1,
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.status,
            subtitle: appLocalizations.statusDesc,
            icon: Icons.power_settings_new_rounded,
            iconColor: Colors.green.shade600,
            animationController: _animationController,
            animationIndex: 2,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.dns.enable)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState((state) => state.copyWith.dns(enable: value));
            },
          ),
          
          _ModernInputCard(
            title: appLocalizations.listen,
            subtitle: ref.watch(patchClashConfigProvider.select((state) => state.dns.listen)),
            icon: Icons.hearing_rounded,
            iconColor: Colors.orange.shade600,
            animationController: _animationController,
            animationIndex: 3,
            inputDelegate: InputDelegate(
              title: appLocalizations.listen,
              value: ref.watch(patchClashConfigProvider.select((state) => state.dns.listen)),
              onChanged: (String? value) {
                if (value == null) return;
                ref.read(patchClashConfigProvider.notifier)
                    .updateState((state) => state.copyWith.dns(listen: value));
              },
            ),
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.useHosts,
            subtitle: "",
            icon: Icons.account_tree_rounded,
            iconColor: Colors.pink.shade600,
            animationController: _animationController,
            animationIndex: 4,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.dns.useHosts)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier)
                .updateState((state) => state.copyWith.dns(useHosts: value));
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.useSystemHosts,
            subtitle: "",
            icon: Icons.computer_rounded,
            iconColor: Colors.teal.shade600,
            animationController: _animationController,
            animationIndex: 5,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.dns.useSystemHosts)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier)
                .updateState((state) => state.copyWith.dns(useSystemHosts: value));
            },
          ),
          
          _ModernSwitchCard(
            title: "IPv6",
            subtitle: "",
            icon: Icons.water_rounded,
            iconColor: Colors.cyan.shade600,
            animationController: _animationController,
            animationIndex: 6,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.dns.ipv6)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier)
                .updateState((state) => state.copyWith.dns(ipv6: value));
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.respectRules,
            subtitle: appLocalizations.respectRulesDesc,
            icon: Icons.rule_rounded,
            iconColor: Colors.deepPurple.shade600,
            animationController: _animationController,
            animationIndex: 7,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.dns.respectRules)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier)
                .updateState((state) => state.copyWith.dns(respectRules: value));
            },
          ),
          
          _ModernSwitchCard(
            title: "PreferH3",
            subtitle: appLocalizations.preferH3Desc,
            icon: Icons.upgrade_rounded,
            iconColor: Colors.blue.shade600,
            animationController: _animationController,
            animationIndex: 8,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.dns.preferH3)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier)
                .updateState((state) => state.copyWith.dns(preferH3: value));
            },
          ),
          
          _ModernOptionsCard<DnsMode>(
            title: appLocalizations.dnsMode,
            subtitle: ref.watch(patchClashConfigProvider.select((state) => state.dns.enhancedMode)).name,
            icon: Icons.mode_rounded,
            iconColor: Colors.amber.shade600,
            animationController: _animationController,
            animationIndex: 9,
            value: ref.watch(patchClashConfigProvider.select((state) => state.dns.enhancedMode)),
            options: DnsMode.values,
            textBuilder: (dnsMode) => dnsMode.name,
            onChanged: (DnsMode? value) {
              if (value == null) return;
              ref.read(patchClashConfigProvider.notifier)
                .updateState((state) => state.copyWith.dns(enhancedMode: value));
            },
            optionsTitle: appLocalizations.dnsMode,
          ),
          
          _ModernInputCard(
            title: appLocalizations.fakeipRange,
            subtitle: ref.watch(patchClashConfigProvider.select((state) => state.dns.fakeIpRange)),
            icon: Icons.filter_alt_rounded,
            iconColor: Colors.red.shade600,
            animationController: _animationController,
            animationIndex: 10,
            inputDelegate: InputDelegate(
              title: appLocalizations.fakeipRange,
              value: ref.watch(patchClashConfigProvider.select((state) => state.dns.fakeIpRange)),
              onChanged: (String? value) {
                if (value == null) return;
                ref.read(patchClashConfigProvider.notifier)
                    .updateState((state) => state.copyWith.dns(fakeIpRange: value));
              },
            ),
          ),
          
          _ModernNavigationCard(
            title: appLocalizations.fakeipFilter,
            subtitle: "",
            icon: Icons.filter_list_rounded,
            iconColor: Colors.orange.shade600,
            animationController: _animationController,
            animationIndex: 11,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.fakeipFilter,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final fakeIpFilter = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.fakeIpFilter),
                    );
                    return ListInputPage(
                      title: appLocalizations.fakeipFilter,
                      items: fakeIpFilter,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier)
                            .updateState((state) => state.copyWith.dns(
                                  fakeIpFilter: List.from(items),
                                ));
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
          
          _ModernNavigationCard(
            title: appLocalizations.defaultNameserver,
            subtitle: appLocalizations.defaultNameserverDesc,
            icon: Icons.dns_rounded,
            iconColor: Colors.indigo.shade600,
            animationController: _animationController,
            animationIndex: 12,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.defaultNameserver,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final defaultNameserver = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.defaultNameserver),
                    );
                    return ListInputPage(
                      title: appLocalizations.defaultNameserver,
                      items: defaultNameserver,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns(
                                defaultNameserver: List.from(items),
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
          
          _ModernNavigationCard(
            title: appLocalizations.nameserverPolicy,
            subtitle: appLocalizations.nameserverPolicyDesc,
            icon: Icons.policy_rounded,
            iconColor: Colors.purple.shade600,
            animationController: _animationController,
            animationIndex: 13,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.nameserverPolicy,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final nameserverPolicy = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.nameserverPolicy),
                    );
                    return MapInputPage(
                      title: appLocalizations.nameserverPolicy,
                      map: nameserverPolicy,
                      titleBuilder: (item) => Text(item.key),
                      subtitleBuilder: (item) => Text(item.value),
                      onChange: (value) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns(
                                nameserverPolicy: value,
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
          
          _ModernNavigationCard(
            title: appLocalizations.nameserver,
            subtitle: appLocalizations.nameserverDesc,
            icon: Icons.language_rounded,
            iconColor: Colors.green.shade600,
            animationController: _animationController,
            animationIndex: 14,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.nameserver,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final nameserver = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.nameserver),
                    );
                    return ListInputPage(
                      title: appLocalizations.nameserver,
                      items: nameserver,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns(
                                nameserver: List.from(items),
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
          
          _ModernNavigationCard(
            title: appLocalizations.fallback,
            subtitle: appLocalizations.fallbackDesc,
            icon: Icons.backup_rounded,
            iconColor: Colors.amber.shade600,
            animationController: _animationController,
            animationIndex: 15,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.fallback,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final fallback = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.fallback),
                    );
                    return ListInputPage(
                      title: appLocalizations.fallback,
                      items: fallback,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns(
                                fallback: List.from(items),
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
          
          _ModernNavigationCard(
            title: appLocalizations.proxyNameserver,
            subtitle: appLocalizations.proxyNameserverDesc,
            icon: Icons.security_rounded,
            iconColor: Colors.blueGrey.shade600,
            animationController: _animationController,
            animationIndex: 16,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.proxyNameserver,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final proxyServerNameserver = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.proxyServerNameserver),
                    );
                    return ListInputPage(
                      title: appLocalizations.proxyNameserver,
                      items: proxyServerNameserver,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns(
                                proxyServerNameserver: List.from(items),
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
          
          // Fallback Filter section
          _buildSectionHeader(
            title: appLocalizations.fallbackFilter,
            icon: Icons.filter_list_rounded,
            color: Colors.deepOrange.shade600,
            animationIndex: 17,
          ),
          
          _ModernSwitchCard(
            title: "Geoip",
            subtitle: "",
            icon: Icons.public_rounded,
            iconColor: Colors.indigo.shade600,
            animationController: _animationController,
            animationIndex: 18,
            valueProvider: (ref) => ref.watch(
              patchClashConfigProvider.select((state) => state.dns.fallbackFilter.geoip),
            ),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier)
                  .updateState((state) => state.copyWith.dns.fallbackFilter(
                        geoip: value,
                      ));
            },
          ),
          
          _ModernInputCard(
            title: appLocalizations.geoipCode,
            subtitle: ref.watch(
              patchClashConfigProvider.select((state) => state.dns.fallbackFilter.geoipCode),
            ),
            icon: Icons.language_rounded,
            iconColor: Colors.blue.shade600,
            animationController: _animationController,
            animationIndex: 19,
            inputDelegate: InputDelegate(
              title: appLocalizations.geoipCode,
              value: ref.watch(
                patchClashConfigProvider.select((state) => state.dns.fallbackFilter.geoipCode),
              ),
              onChanged: (String? value) {
                if (value == null) return;
                ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith.dns.fallbackFilter(
                        geoipCode: value,
                      ),
                    );
              },
            ),
          ),
          
          _ModernNavigationCard(
            title: "Geosite",
            subtitle: "",
            icon: Icons.travel_explore_rounded,
            iconColor: Colors.teal.shade600,
            animationController: _animationController,
            animationIndex: 20,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: "Geosite",
                widget: Consumer(
                  builder: (_, ref, __) {
                    final geosite = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.fallbackFilter.geosite),
                    );
                    return ListInputPage(
                      title: "Geosite",
                      items: geosite,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns.fallbackFilter(
                                geosite: List.from(items),
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
          
          _ModernNavigationCard(
            title: appLocalizations.ipcidr,
            subtitle: "",
            icon: Icons.filter_alt_rounded,
            iconColor: Colors.purple.shade600,
            animationController: _animationController,
            animationIndex: 21,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.ipcidr,
                widget: Consumer(
                  builder: (_, ref, ___) {
                    final ipcidr = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.fallbackFilter.ipcidr),
                    );
                    return ListInputPage(
                      title: appLocalizations.ipcidr,
                      items: ipcidr,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier)
                            .updateState((state) => state.copyWith.dns.fallbackFilter(
                                  ipcidr: List.from(items),
                                ));
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
          
          _ModernNavigationCard(
            title: appLocalizations.domain,
            subtitle: "",
            icon: Icons.domain_rounded,
            iconColor: Colors.orange.shade600,
            animationController: _animationController,
            animationIndex: 22,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: appLocalizations.domain,
                widget: Consumer(
                  builder: (_, ref, __) {
                    final domain = ref.watch(
                      patchClashConfigProvider.select((state) => state.dns.fallbackFilter.domain),
                    );
                    return ListInputPage(
                      title: appLocalizations.domain,
                      items: domain,
                      titleBuilder: (item) => Text(item),
                      onChange: (items) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                              (state) => state.copyWith.dns.fallbackFilter(
                                domain: List.from(items),
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

// Modern card widgets
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
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
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

class _ModernInputCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final AnimationController animationController;
  final int animationIndex;
  final InputDelegate inputDelegate;

  const _ModernInputCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.animationController,
    required this.animationIndex,
    required this.inputDelegate,
  });

  @override
  Widget build(BuildContext context) {
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
            child: ListItem.input(
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
              delegate: inputDelegate,
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
