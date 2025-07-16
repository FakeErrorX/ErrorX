import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/fragments/proxies/list.dart';
import 'package:errorx/fragments/proxies/providers.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:errorx/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common.dart';
import 'setting.dart';
import 'tab.dart';

class ProxiesFragment extends ConsumerStatefulWidget {
  const ProxiesFragment({super.key});

  @override
  ConsumerState<ProxiesFragment> createState() => _ProxiesFragmentState();
}

class _ProxiesFragmentState extends ConsumerState<ProxiesFragment>
    with PageMixin {
  final GlobalKey<ProxiesTabFragmentState> _proxiesTabKey = GlobalKey();
  bool _hasProviders = false;
  bool _isTab = false;

  @override
  get actions => [
        if (_hasProviders)
          _buildModernActionButton(
            Icons.analytics_rounded,
            "Providers",
            () {
              showExtend(
                context,
                builder: (_, type) {
                  return ProvidersView(
                    type: type,
                  );
                },
              );
            },
          ),
        _isTab
            ? _buildModernActionButton(
                Icons.my_location_rounded,
                "Locate Selected",
                () {
                  _proxiesTabKey.currentState?.scrollToGroupSelected();
                },
              )
            : _buildModernActionButton(
                Icons.palette_rounded,
                "Icon Style",
                () {
                  showExtend(
                    context,
                    builder: (_, type) {
                      return AdaptiveSheetScaffold(
                        type: type,
                        body: const _IconConfigView(),
                        title: appLocalizations.iconConfiguration,
                      );
                    },
                  );
                },
              ),
        _buildModernActionButton(
          Icons.tune_rounded,
          "Settings",
          () {
            showSheet(
              context: context,
              props: SheetProps(
                isScrollControlled: true,
              ),
              builder: (_, type) {
                return AdaptiveSheetScaffold(
                  type: type,
                  body: const ProxiesSetting(),
                  title: appLocalizations.proxiesSetting,
                );
              },
            );
          },
        )
      ];

  Widget _buildModernActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.primaryContainer.withOpacity(0.8),
              context.colorScheme.secondaryContainer.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: context.colorScheme.primary.withOpacity(0.1),
            child: Center(
              child: Icon(
                icon,
                color: context.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  get floatingActionButton => _isTab
      ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DelayTestButton(
            onClick: () async {
              await delayTest(
                currentTabProxies,
                currentTabTestUrl,
              );
            },
          ),
        )
      : null;

  // Ensure current profile is properly decrypted before displaying proxies
  Future<void> _ensureProfilesDecrypted() async {
    try {
      await globalState.appController.ensureCurrentProfileDecrypted();
    } catch (e) {
      commonPrint.log("Failed to ensure profiles are decrypted: $e");
    }
  }

  @override
  void initState() {
    // Ensure profiles are decrypted when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfilesDecrypted();
    });
    
    ref.listenManual(
      proxiesActionsStateProvider,
      fireImmediately: true,
      (prev, next) {
        if (prev == next) {
          return;
        }
        if (next.pageLabel == PageLabel.proxies) {
          _hasProviders = next.hasProviders;
          _isTab = next.type == ProxiesType.tab;
          initPageState();
          return;
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType =
        ref.watch(proxiesStyleSettingProvider.select((state) => state.type));
    return switch (proxiesType) {
      ProxiesType.tab => ProxiesTabFragment(
          key: _proxiesTabKey,
        ),
      ProxiesType.list => const ProxiesListFragment(),
    };
  }
}

class _IconConfigView extends ConsumerWidget {
  const _IconConfigView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconMap =
        ref.watch(proxiesStyleSettingProvider.select((state) => state.iconMap));
    return MapInputPage(
      title: appLocalizations.iconConfiguration,
      map: iconMap,
      keyLabel: appLocalizations.regExp,
      valueLabel: appLocalizations.icon,
      titleBuilder: (item) => Text(item.key),
      leadingBuilder: (item) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: CommonTargetIcon(
          src: item.value,
          size: 42,
        ),
      ),
      subtitleBuilder: (item) => Text(
        item.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onChange: (value) {
        ref.read(proxiesStyleSettingProvider.notifier).updateState(
              (state) => state.copyWith(
                iconMap: value,
              ),
            );
      },
    );
  }
}
