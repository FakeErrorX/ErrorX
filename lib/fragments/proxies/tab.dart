import 'dart:math';

import 'package:errorx/common/common.dart';
import 'package:errorx/models/common.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';
import 'common.dart';

List<Proxy> currentTabProxies = [];
String? currentTabTestUrl;

typedef GroupNameKeyMap = Map<String, GlobalObjectKey<ProxyGroupViewState>>;

class ProxiesTabFragment extends ConsumerStatefulWidget {
  const ProxiesTabFragment({super.key});

  @override
  ConsumerState<ProxiesTabFragment> createState() => ProxiesTabFragmentState();
}

class ProxiesTabFragmentState extends ConsumerState<ProxiesTabFragment>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final _hasMoreButtonNotifier = ValueNotifier<bool>(false);
  GroupNameKeyMap _keyMap = {};

  @override
  void initState() {
    super.initState();
    _handleTabListen();
  }

  @override
  void dispose() {
    _destroyTabController();
    super.dispose();
  }

  scrollToGroupSelected() {
    final currentGroupName = globalState.appController.getCurrentGroupName();
    _keyMap[currentGroupName]?.currentState?.scrollToSelected();
  }

  _buildMoreButton() {
    return Consumer(
      builder: (_, ref, ___) {
        final isMobileView = ref.watch(isMobileViewProvider);
        return Container(
          width: 40,
          height: 40,
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
              onTap: _showMoreMenu,
              borderRadius: BorderRadius.circular(12),
              splashColor: context.colorScheme.primary.withOpacity(0.1),
              child: Center(
                child: Icon(
                  isMobileView ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                  color: context.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _showMoreMenu() {
    showSheet(
      context: context,
      props: SheetProps(
        isScrollControlled: false,
      ),
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colorScheme.surface.withOpacity(0.9),
                  context.colorScheme.surfaceVariant.withOpacity(0.3),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(proxiesSelectorStateProvider);
                  return Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    context.colorScheme.primary.withOpacity(0.8),
                                    context.colorScheme.tertiary.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.hub_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appLocalizations.proxyGroup,
                                    style: context.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Select a proxy group",
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      color: context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Group selection grid
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runSpacing: 12,
                          spacing: 12,
                          children: [                          for (final groupName in state.groupNames)
                            _buildGroupChip(context, groupName, state.currentGroupName),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          title: appLocalizations.proxyGroup,
        );
      },
    );
  }

  Widget _buildGroupChip(BuildContext context, String groupName, String? currentGroupName) {
    final isSelected = groupName == currentGroupName;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  final index = ref.read(proxiesSelectorStateProvider).groupNames.indexWhere(
                    (item) => item == groupName,
                  );
                  if (index == -1) return;
                  _tabController?.animateTo(index);
                  globalState.appController.updateCurrentGroupName(groupName);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(16),
                splashColor: context.colorScheme.primary.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colorScheme.primary.withOpacity(0.8),
                        context.colorScheme.tertiary.withOpacity(0.6),
                      ],
                    ) : null,
                    color: isSelected ? null : context.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? context.colorScheme.primary.withOpacity(0.3)
                          : context.colorScheme.outline.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: context.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        groupName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : context.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _tabControllerListener([int? index]) {
    int? groupIndex = index;
    if (groupIndex == -1) {
      return;
    }
    final appController = globalState.appController;
    if (groupIndex == null) {
      final currentIndex = _tabController?.index;
      groupIndex = currentIndex;
    }
    final currentGroups = appController.getCurrentGroups();
    if (groupIndex == null || groupIndex > currentGroups.length) {
      return;
    }
    final currentGroup = currentGroups[groupIndex];
    currentTabProxies = currentGroup.all;
    currentTabTestUrl = currentGroup.testUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalState.appController.updateCurrentGroupName(
        currentGroup.name,
      );
    });
  }

  _destroyTabController() {
    _tabController?.removeListener(_tabControllerListener);
    _tabController?.dispose();
    _tabController = null;
  }

  _updateTabController(int length, int index) {
    if (length == 0) {
      _destroyTabController();
      return;
    }
    final realIndex = index == -1 ? 0 : index;
    _tabController ??= TabController(
      length: length,
      initialIndex: realIndex,
      vsync: this,
    );
    _tabControllerListener(realIndex);
    _tabController?.addListener(_tabControllerListener);
  }

  _handleTabListen() {
    ref.listenManual(
      proxiesSelectorStateProvider,
      (prev, next) {
        if (prev == next) {
          return;
        }
        if (prev?.groupNames.length != next.groupNames.length) {
          _destroyTabController();
          final index = next.groupNames.indexWhere(
            (item) => item == next.currentGroupName,
          );
          _updateTabController(next.groupNames.length, index);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupNamesStateProvider);
    final groupNames = state.groupNames;
    if (groupNames.isEmpty) {
      return NullStatus(
        label: appLocalizations.nullProxies,
      );
    }
    final GroupNameKeyMap keyMap = {};
    final children = groupNames.map((groupName) {
      keyMap[groupName] = GlobalObjectKey(groupName);
      return KeepScope(
        child: ProxyGroupView(
          key: keyMap[groupName],
          groupName: groupName,
        ),
      );
    }).toList();
    _keyMap = keyMap;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern tab bar with glassmorphism
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colorScheme.surface.withOpacity(0.9),
                context.colorScheme.surface.withOpacity(0.7),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (scrollNotification) {
              _hasMoreButtonNotifier.value =
                  scrollNotification.metrics.maxScrollExtent > 0;
              return true;
            },
            child: ValueListenableBuilder(
              valueListenable: _hasMoreButtonNotifier,
              builder: (_, value, child) {
                return Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    TabBar(
                      controller: _tabController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16 + (value ? 56 : 0),
                        top: 8,
                        bottom: 8,
                      ),
                      dividerColor: Colors.transparent,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colorScheme.primary.withOpacity(0.8),
                            context.colorScheme.tertiary.withOpacity(0.6),
                          ],
                        ),
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
                      labelStyle: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelStyle: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: context.colorScheme.onSurfaceVariant,
                      tabs: [
                        for (final groupName in groupNames)
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(groupName),
                            ),
                          ),
                      ],
                    ),
                    if (value)
                      Positioned(
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                context.colorScheme.surface.withOpacity(0.0),
                                context.colorScheme.surface.withOpacity(0.9),
                              ],
                              stops: const [0.0, 0.3],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildMoreButton(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: children,
          ),
        )
      ],
    );
  }
}

class ProxyGroupView extends ConsumerStatefulWidget {
  final String groupName;

  const ProxyGroupView({
    super.key,
    required this.groupName,
  });

  @override
  ConsumerState<ProxyGroupView> createState() => ProxyGroupViewState();
}

class ProxyGroupViewState extends ConsumerState<ProxyGroupView> {
  final _controller = ScrollController();

  String get groupName => widget.groupName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  scrollToSelected() {
    if (_controller.position.maxScrollExtent == 0) {
      return;
    }

    final sortedProxies = globalState.appController.getSortProxies(
      currentTabProxies,
      currentTabTestUrl,
    );
    _controller.animateTo(
      min(
        16 +
            getScrollToSelectedOffset(
              groupName: groupName,
              proxies: sortedProxies,
            ),
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proxyGroupSelectorStateProvider(groupName));
    final proxies = state.proxies;
    final columns = state.columns;
    final proxyCardType = state.proxyCardType;
    final sortedProxies = globalState.appController.getSortProxies(
      proxies,
      state.testUrl,
    );
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colorScheme.surface.withOpacity(0.5),
            context.colorScheme.surfaceVariant.withOpacity(0.2),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: CommonAutoHiddenScrollBar(
          controller: _controller,
          child: GridView.builder(
            controller: _controller,
            padding: const EdgeInsets.only(
              top: 24,
              left: 16,
              right: 16,
              bottom: 120,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: getItemHeight(proxyCardType),
            ),
            itemCount: sortedProxies.length,
            itemBuilder: (_, index) {
              final proxy = sortedProxies[index];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 50)),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: ProxyCard(
                        testUrl: state.testUrl,
                        groupType: state.groupType,
                        type: proxyCardType,
                        key: ValueKey('$groupName.${proxy.name}'),
                        proxy: proxy,
                        groupName: groupName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class DelayTestButton extends StatefulWidget {
  final Future Function() onClick;

  const DelayTestButton({
    super.key,
    required this.onClick,
  });

  @override
  State<DelayTestButton> createState() => _DelayTestButtonState();
}

class _DelayTestButtonState extends State<DelayTestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  _healthcheck() async {
    if (_controller.isAnimating) {
      return;
    }
    _controller.forward();
    await widget.onClick();
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 200,
      ),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          1,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (_, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.0, end: _controller.isAnimating ? 0.0 : 1.0),
          curve: Curves.easeOutBack,
          builder: (context, scaleValue, child) {
            return Transform.scale(
              scale: _scale.value + (scaleValue * 0.1),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.primary,
                      context.colorScheme.tertiary,
                    ],
                  ),
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _healthcheck,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.white.withOpacity(0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: _controller.isAnimating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.white, Colors.white.withOpacity(0.8)],
                                ).createShader(bounds),
                                child: Icon(
                                  Icons.speed_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
