import 'dart:io';
import 'dart:math';
import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogLevelItem extends ConsumerWidget {
  const LogLevelItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final logLevel =
        ref.watch(patchClashConfigProvider.select((state) => state.logLevel));
    return ListItem<LogLevel>.options(
      leading: const Icon(Icons.info_outline),
      title: Text(appLocalizations.logLevel),
      subtitle: Text(logLevel.name),
      delegate: OptionsDelegate<LogLevel>(
        title: appLocalizations.logLevel,
        options: LogLevel.values,
        onChanged: (LogLevel? value) {
          if (value == null) {
            return;
          }
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  logLevel: value,
                ),
              );
        },
        textBuilder: (logLevel) => logLevel.name,
        value: logLevel,
      ),
    );
  }
}

class UaItem extends ConsumerWidget {
  const UaItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final globalUa =
        ref.watch(patchClashConfigProvider.select((state) => state.globalUa));
    return ListItem<String?>.options(
      leading: const Icon(Icons.computer_outlined),
      title: const Text("UA"),
      subtitle: Text(globalUa ?? appLocalizations.defaultText),
      delegate: OptionsDelegate<String?>(
        title: "UA",
        options: [
          null,
          "clash-verge/v1.6.6",
          "ClashforWindows/0.19.23",
        ],
        value: globalUa,
        onChanged: (value) {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  globalUa: value,
                ),
              );
        },
        textBuilder: (ua) => ua ?? appLocalizations.defaultText,
      ),
    );
  }
}

class KeepAliveIntervalItem extends ConsumerWidget {
  const KeepAliveIntervalItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final keepAliveInterval = ref.watch(
        patchClashConfigProvider.select((state) => state.keepAliveInterval));
    return ListItem.input(
      leading: const Icon(Icons.timer_outlined),
      title: Text(appLocalizations.keepAliveIntervalDesc),
      subtitle: Text("$keepAliveInterval ${appLocalizations.seconds}"),
      delegate: InputDelegate(
        title: appLocalizations.keepAliveIntervalDesc,
        suffixText: appLocalizations.seconds,
        resetValue: "$defaultKeepAliveInterval",
        value: "$keepAliveInterval",
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          globalState.safeRun(
            () {
              final intValue = int.parse(value);
              if (intValue <= 0) {
                throw "Invalid keepAliveInterval";
              }
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith(
                      keepAliveInterval: intValue,
                    ),
                  );
            },
            silence: false,
            title: appLocalizations.keepAliveIntervalDesc,
          );
        },
      ),
    );
  }
}

class TestUrlItem extends ConsumerWidget {
  const TestUrlItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final testUrl =
        ref.watch(appSettingProvider.select((state) => state.testUrl));
    return ListItem.input(
      leading: const Icon(Icons.timeline),
      title: Text(appLocalizations.testUrl),
      subtitle: Text(testUrl),
      delegate: InputDelegate(
          resetValue: defaultTestUrl,
          title: appLocalizations.testUrl,
          value: testUrl,
          onChanged: (String? value) {
            if (value == null) {
              return;
            }
            globalState.safeRun(
              () {
                if (!value.isUrl) {
                  throw "Invalid url";
                }
                ref.read(appSettingProvider.notifier).updateState(
                      (state) => state.copyWith(
                        testUrl: value,
                      ),
                    );
              },
              silence: false,
              title: appLocalizations.testUrl,
            );
          }),
    );
  }
}

class MixedPortItem extends ConsumerWidget {
  const MixedPortItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final mixedPort =
        ref.watch(patchClashConfigProvider.select((state) => state.mixedPort));
    return ListItem.input(
      leading: const Icon(Icons.adjust_outlined),
      title: Text(appLocalizations.proxyPort),
      subtitle: Text("$mixedPort"),
      delegate: InputDelegate(
        title: appLocalizations.proxyPort,
        value: "$mixedPort",
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          globalState.safeRun(
            () {
              final mixedPort = int.parse(value);
              if (mixedPort < 1024 || mixedPort > 49151) {
                throw "Invalid port";
              }
              ref.read(patchClashConfigProvider.notifier).updateState(
                    (state) => state.copyWith(
                      mixedPort: mixedPort,
                    ),
                  );
            },
            silence: false,
            title: appLocalizations.proxyPort,
          );
        },
        resetValue: "$defaultMixedPort",
      ),
    );
  }
}

class HostsItem extends StatelessWidget {
  const HostsItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.view_list_outlined),
      title: const Text("Hosts"),
      subtitle: Text(appLocalizations.hostsDesc),
      delegate: OpenDelegate(
        blur: false,
        title: "Hosts",
        widget: Consumer(
          builder: (_, ref, __) {
            final hosts = ref
                .watch(patchClashConfigProvider.select((state) => state.hosts));
            return MapInputPage(
              title: "Hosts",
              map: hosts,
              titleBuilder: (item) => Text(item.key),
              subtitleBuilder: (item) => Text(item.value),
              onChange: (value) {
                ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith(
                        hosts: value,
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

class Ipv6Item extends ConsumerWidget {
  const Ipv6Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ipv6 =
        ref.watch(patchClashConfigProvider.select((state) => state.ipv6));
    return ListItem.switchItem(
      leading: const Icon(Icons.water_outlined),
      title: const Text("IPv6"),
      subtitle: Text(appLocalizations.ipv6Desc),
      delegate: SwitchDelegate(
        value: ipv6,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  ipv6: value,
                ),
              );
        },
      ),
    );
  }
}

class AllowLanItem extends ConsumerWidget {
  const AllowLanItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final allowLan =
        ref.watch(patchClashConfigProvider.select((state) => state.allowLan));
    return ListItem.switchItem(
      leading: const Icon(Icons.device_hub),
      title: Text(appLocalizations.allowLan),
      subtitle: Text(appLocalizations.allowLanDesc),
      delegate: SwitchDelegate(
        value: allowLan,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  allowLan: value,
                ),
              );
        },
      ),
    );
  }
}

class UnifiedDelayItem extends ConsumerWidget {
  const UnifiedDelayItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final unifiedDelay = ref
        .watch(patchClashConfigProvider.select((state) => state.unifiedDelay));

    return ListItem.switchItem(
      leading: const Icon(Icons.compress_outlined),
      title: Text(appLocalizations.unifiedDelay),
      subtitle: Text(appLocalizations.unifiedDelayDesc),
      delegate: SwitchDelegate(
        value: unifiedDelay,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  unifiedDelay: value,
                ),
              );
        },
      ),
    );
  }
}

class FindProcessItem extends ConsumerWidget {
  const FindProcessItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final findProcess = ref.watch(patchClashConfigProvider
        .select((state) => state.findProcessMode == FindProcessMode.always));

    return ListItem.switchItem(
      leading: const Icon(Icons.polymer_outlined),
      title: Text(appLocalizations.findProcessMode),
      subtitle: Text(appLocalizations.findProcessModeDesc),
      delegate: SwitchDelegate(
        value: findProcess,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  findProcessMode:
                      value ? FindProcessMode.always : FindProcessMode.off,
                ),
              );
        },
      ),
    );
  }
}

class TcpConcurrentItem extends ConsumerWidget {
  const TcpConcurrentItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final tcpConcurrent = ref
        .watch(patchClashConfigProvider.select((state) => state.tcpConcurrent));
    return ListItem.switchItem(
      leading: const Icon(Icons.double_arrow_outlined),
      title: Text(appLocalizations.tcpConcurrent),
      subtitle: Text(appLocalizations.tcpConcurrentDesc),
      delegate: SwitchDelegate(
        value: tcpConcurrent,
        onChanged: (value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  tcpConcurrent: value,
                ),
              );
        },
      ),
    );
  }
}

class GeodataLoaderItem extends ConsumerWidget {
  const GeodataLoaderItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final isMemconservative = ref.watch(patchClashConfigProvider.select(
        (state) => state.geodataLoader == GeodataLoader.memconservative));
    return ListItem.switchItem(
      leading: const Icon(Icons.memory),
      title: Text(appLocalizations.geodataLoader),
      subtitle: Text(appLocalizations.geodataLoaderDesc),
      delegate: SwitchDelegate(
        value: isMemconservative,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  geodataLoader: value
                      ? GeodataLoader.memconservative
                      : GeodataLoader.standard,
                ),
              );
        },
      ),
    );
  }
}

class ExternalControllerItem extends ConsumerWidget {
  const ExternalControllerItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final hasExternalController = ref.watch(patchClashConfigProvider.select(
        (state) => state.externalController == ExternalControllerStatus.open));
    return ListItem.switchItem(
      leading: const Icon(Icons.api_outlined),
      title: Text(appLocalizations.externalController),
      subtitle: Text(appLocalizations.externalControllerDesc),
      delegate: SwitchDelegate(
        value: hasExternalController,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  externalController: value
                      ? ExternalControllerStatus.open
                      : ExternalControllerStatus.close,
                ),
              );
        },
      ),
    );
  }
}

final generalItems = <Widget>[
  LogLevelItem(),
  UaItem(),
  if (system.isDesktop) KeepAliveIntervalItem(),
  TestUrlItem(),
  MixedPortItem(),
  HostsItem(),
  Ipv6Item(),
  AllowLanItem(),
  UnifiedDelayItem(),
  FindProcessItem(),
  TcpConcurrentItem(),
  GeodataLoaderItem(),
  ExternalControllerItem(),
]
    .separated(
      const Divider(
        height: 0,
      ),
    )
    .toList();

class GeneralListView extends ConsumerStatefulWidget {
  const GeneralListView({super.key});

  @override
  ConsumerState<GeneralListView> createState() => _GeneralListViewState();
}

class _GeneralListViewState extends ConsumerState<GeneralListView> with SingleTickerProviderStateMixin {
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
            ref.read(patchClashConfigProvider.notifier).updateState(
                  (state) => state.copyWith(
                    logLevel: LogLevel.info,
                    globalUa: null,
                    keepAliveInterval: defaultKeepAliveInterval,
                    mixedPort: defaultMixedPort,
                    hosts: {},
                    ipv6: false,
                    allowLan: false,
                    unifiedDelay: false,
                    findProcessMode: FindProcessMode.always,
                    tcpConcurrent: false,
                    geodataLoader: GeodataLoader.standard,
                    externalController: ExternalControllerStatus.open,
                  ),
                );
            ref.read(appSettingProvider.notifier).updateState(
                  (state) => state.copyWith(
                    testUrl: defaultTestUrl,
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
                      Icons.build_rounded,
                      size: 48,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appLocalizations.general,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appLocalizations.generalDesc,
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
          
          _buildSectionHeader(
            title: "Configuration",
            icon: Icons.settings_rounded,
            color: Colors.indigo.shade600,
            animationIndex: 0,
          ),
          
          _ModernOptionsCard<LogLevel>(
            title: appLocalizations.logLevel,
            subtitle: ref.watch(patchClashConfigProvider.select((state) => state.logLevel)).name,
            icon: Icons.info_outline,
            iconColor: Colors.blue.shade600,
            animationController: _animationController,
            animationIndex: 1,
            value: ref.watch(patchClashConfigProvider.select((state) => state.logLevel)),
            options: LogLevel.values,
            textBuilder: (logLevel) => logLevel.name,
            onChanged: (LogLevel? value) {
              if (value == null) return;
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(logLevel: value),
              );
            },
            optionsTitle: appLocalizations.logLevel,
          ),
          
          _ModernOptionsCard<String?>(
            title: "UA",
            subtitle: ref.watch(patchClashConfigProvider.select((state) => state.globalUa ?? appLocalizations.defaultText)),
            icon: Icons.computer_outlined,
            iconColor: Colors.purple.shade600,
            animationController: _animationController,
            animationIndex: 2,
            value: ref.watch(patchClashConfigProvider.select((state) => state.globalUa)),
            options: [
              null,
              "clash-verge/v1.6.6",
              "ClashforWindows/0.19.23",
            ],
            textBuilder: (ua) => ua ?? appLocalizations.defaultText,
            onChanged: (String? value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(globalUa: value),
              );
            },
            optionsTitle: "UA",
          ),
          
          if (system.isDesktop)
            _ModernInputCard(
              title: appLocalizations.keepAliveIntervalDesc,
              subtitle: "${ref.watch(patchClashConfigProvider.select((state) => state.keepAliveInterval))} ${appLocalizations.seconds}",
              icon: Icons.timer_outlined,
              iconColor: Colors.green.shade600,
              animationController: _animationController,
              animationIndex: 3,
              inputDelegate: InputDelegate(
                title: appLocalizations.keepAliveIntervalDesc,
                suffixText: appLocalizations.seconds,
                resetValue: "$defaultKeepAliveInterval",
                value: "${ref.watch(patchClashConfigProvider.select((state) => state.keepAliveInterval))}",
                onChanged: (String? value) {
                  if (value == null) return;
                  globalState.safeRun(
                    () {
                      final intValue = int.parse(value);
                      if (intValue <= 0) {
                        throw "Invalid keepAliveInterval";
                      }
                      ref.read(patchClashConfigProvider.notifier).updateState(
                        (state) => state.copyWith(keepAliveInterval: intValue),
                      );
                    },
                    silence: false,
                    title: appLocalizations.keepAliveIntervalDesc,
                  );
                },
              ),
            ),
          
          _ModernInputCard(
            title: appLocalizations.testUrl,
            subtitle: ref.watch(appSettingProvider.select((state) => state.testUrl)),
            icon: Icons.timeline,
            iconColor: Colors.orange.shade600,
            animationController: _animationController,
            animationIndex: 4,
            inputDelegate: InputDelegate(
              resetValue: defaultTestUrl,
              title: appLocalizations.testUrl,
              value: ref.watch(appSettingProvider.select((state) => state.testUrl)),
              onChanged: (String? value) {
                if (value == null) return;
                globalState.safeRun(
                  () {
                    if (!value.isUrl) {
                      throw "Invalid url";
                    }
                    ref.read(appSettingProvider.notifier).updateState(
                      (state) => state.copyWith(testUrl: value),
                    );
                  },
                  silence: false,
                  title: appLocalizations.testUrl,
                );
              },
            ),
          ),
          
          _ModernInputCard(
            title: appLocalizations.proxyPort,
            subtitle: "${ref.watch(patchClashConfigProvider.select((state) => state.mixedPort))}",
            icon: Icons.adjust_outlined,
            iconColor: Colors.pink.shade600,
            animationController: _animationController,
            animationIndex: 5,
            inputDelegate: InputDelegate(
              title: appLocalizations.proxyPort,
              value: "${ref.watch(patchClashConfigProvider.select((state) => state.mixedPort))}",
              onChanged: (String? value) {
                if (value == null) return;
                globalState.safeRun(
                  () {
                    final mixedPort = int.parse(value);
                    if (mixedPort < 1024 || mixedPort > 49151) {
                      throw "Invalid port";
                    }
                    ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith(mixedPort: mixedPort),
                    );
                  },
                  silence: false,
                  title: appLocalizations.proxyPort,
                );
              },
              resetValue: "$defaultMixedPort",
            ),
          ),
          
          _ModernNavigationCard(
            title: "Hosts",
            subtitle: appLocalizations.hostsDesc,
            icon: Icons.view_list_outlined,
            iconColor: Colors.teal.shade600,
            animationController: _animationController,
            animationIndex: 6,
            onTap: () {
              final delegate = OpenDelegate(
                blur: false,
                title: "Hosts",
                widget: Consumer(
                  builder: (_, ref, __) {
                    final hosts = ref.watch(patchClashConfigProvider.select((state) => state.hosts));
                    return MapInputPage(
                      title: "Hosts",
                      map: hosts,
                      titleBuilder: (item) => Text(item.key),
                      subtitleBuilder: (item) => Text(item.value),
                      onChange: (value) {
                        ref.read(patchClashConfigProvider.notifier).updateState(
                          (state) => state.copyWith(hosts: value),
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
          
          _buildSectionHeader(
            title: "Network",
            icon: Icons.network_check_rounded,
            color: Colors.blue.shade600,
            animationIndex: 7,
          ),
          
          _ModernSwitchCard(
            title: "IPv6",
            subtitle: appLocalizations.ipv6Desc,
            icon: Icons.water_outlined,
            iconColor: Colors.cyan.shade600,
            animationController: _animationController,
            animationIndex: 8,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.ipv6)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(ipv6: value),
              );
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.allowLan,
            subtitle: appLocalizations.allowLanDesc,
            icon: Icons.device_hub,
            iconColor: Colors.green.shade600,
            animationController: _animationController,
            animationIndex: 9,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.allowLan)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(allowLan: value),
              );
            },
          ),
          
          _buildSectionHeader(
            title: "Advanced",
            icon: Icons.tune_rounded,
            color: Colors.amber.shade700,
            animationIndex: 10,
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.unifiedDelay,
            subtitle: appLocalizations.unifiedDelayDesc,
            icon: Icons.compress_outlined,
            iconColor: Colors.purple.shade600,
            animationController: _animationController,
            animationIndex: 11,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.unifiedDelay)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(unifiedDelay: value),
              );
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.findProcessMode,
            subtitle: appLocalizations.findProcessModeDesc,
            icon: Icons.polymer_outlined,
            iconColor: Colors.orange.shade600,
            animationController: _animationController,
            animationIndex: 12,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.findProcessMode == FindProcessMode.always)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  findProcessMode: value ? FindProcessMode.always : FindProcessMode.off,
                ),
              );
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.tcpConcurrent,
            subtitle: appLocalizations.tcpConcurrentDesc,
            icon: Icons.double_arrow_outlined,
            iconColor: Colors.red.shade600,
            animationController: _animationController,
            animationIndex: 13,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.tcpConcurrent)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(tcpConcurrent: value),
              );
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.geodataLoader,
            subtitle: appLocalizations.geodataLoaderDesc,
            icon: Icons.memory,
            iconColor: Colors.indigo.shade600,
            animationController: _animationController,
            animationIndex: 14,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.geodataLoader == GeodataLoader.memconservative)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  geodataLoader: value ? GeodataLoader.memconservative : GeodataLoader.standard,
                ),
              );
            },
          ),
          
          _ModernSwitchCard(
            title: appLocalizations.externalController,
            subtitle: appLocalizations.externalControllerDesc,
            icon: Icons.api_outlined,
            iconColor: Colors.blue.shade600,
            animationController: _animationController,
            animationIndex: 15,
            valueProvider: (ref) => ref.watch(patchClashConfigProvider.select((state) => state.externalController == ExternalControllerStatus.open)),
            onChanged: (value) {
              ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  externalController: value ? ExternalControllerStatus.open : ExternalControllerStatus.close,
                ),
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

final generateGeneralView = ({bool useLegacy = false}) {
  if (useLegacy) {
    return ListView(
      children: generalItems,
    );
  } else {
    return const GeneralListView();
  }
};
