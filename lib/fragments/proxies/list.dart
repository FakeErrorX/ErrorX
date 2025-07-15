import 'dart:math';

import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/app.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/providers/state.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';
import 'common.dart';

typedef GroupNameProxiesMap = Map<String, List<Proxy>>;

class ProxiesListFragment extends StatefulWidget {
  const ProxiesListFragment({super.key});

  @override
  State<ProxiesListFragment> createState() => _ProxiesListFragmentState();
}

class _ProxiesListFragmentState extends State<ProxiesListFragment> {
  final _controller = ScrollController();
  final _headerStateNotifier = ValueNotifier<ProxiesListHeaderSelectorState>(
    const ProxiesListHeaderSelectorState(
      offset: 0,
      currentIndex: 0,
    ),
  );
  List<double> _headerOffset = [];
  GroupNameProxiesMap _lastGroupNameProxiesMap = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_adjustHeader);
  }

  _adjustHeader() {
    final offset = _controller.offset;
    final index = _headerOffset.findInterval(offset);
    final currentIndex = index;
    double headerOffset = 0.0;
    if (index + 1 <= _headerOffset.length - 1) {
      final endOffset = _headerOffset[index + 1];
      final startOffset = endOffset - listHeaderHeight - 8;
      if (offset > startOffset && offset < endOffset) {
        headerOffset = offset - startOffset;
      }
    }
    _headerStateNotifier.value = _headerStateNotifier.value.copyWith(
      currentIndex: currentIndex,
      offset: max(headerOffset, 0),
    );
  }

  double _getListItemHeight(Type type, ProxyCardType proxyCardType) {
    return switch (type) {
      const (SizedBox) => 8,
      const (ListHeader) => listHeaderHeight,
      Type() => getItemHeight(proxyCardType),
    };
  }

  @override
  void dispose() {
    _headerStateNotifier.dispose();
    _controller.removeListener(_adjustHeader);
    _controller.dispose();
    super.dispose();
  }

  _handleChange(Set<String> currentUnfoldSet, String groupName) {
    final tempUnfoldSet = Set<String>.from(currentUnfoldSet);
    if (tempUnfoldSet.contains(groupName)) {
      tempUnfoldSet.remove(groupName);
    } else {
      tempUnfoldSet.add(groupName);
    }
    globalState.appController.updateCurrentUnfoldSet(
      tempUnfoldSet,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjustHeader();
    });
  }

  List<double> _getItemHeightList(
    List<Widget> items,
    ProxyCardType proxyCardType,
  ) {
    final itemHeightList = <double>[];
    List<double> headerOffset = [];
    double currentHeight = 0;
    for (final item in items) {
      if (item.runtimeType == ListHeader) {
        headerOffset.add(currentHeight);
      }
      final itemHeight = _getListItemHeight(item.runtimeType, proxyCardType);
      itemHeightList.add(itemHeight);
      currentHeight = currentHeight + itemHeight;
    }
    _headerOffset = headerOffset;
    return itemHeightList;
  }

  List<Widget> _buildItems(
    WidgetRef ref, {
    required List<String> groupNames,
    required int columns,
    required Set<String> currentUnfoldSet,
    required ProxyCardType type,
  }) {
    final items = <Widget>[];
    final GroupNameProxiesMap groupNameProxiesMap = {};
    for (final groupName in groupNames) {
      final group =
          ref.read(groupsProvider.select((state) => state.getGroup(groupName)));
      if (group == null) {
        continue;
      }
      final isExpand = currentUnfoldSet.contains(groupName);
      items.addAll([
        ListHeader(
          onScrollToSelected: _scrollToGroupSelected,
          key: Key(groupName),
          isExpand: isExpand,
          group: group,
          onChange: (String groupName) {
            _handleChange(currentUnfoldSet, groupName);
          },
        ),
        const SizedBox(
          height: 8,
        ),
      ]);
      if (isExpand) {
        final sortedProxies = globalState.appController.getSortProxies(
          group.all,
          group.testUrl,
        );
        groupNameProxiesMap[groupName] = sortedProxies;
        final chunks = sortedProxies.chunks(columns);
        final rows = chunks.map<Widget>((proxies) {
          final children = proxies
              .map<Widget>(
                (proxy) => Flexible(
                  child: ProxyCard(
                    testUrl: group.testUrl,
                    type: type,
                    groupType: group.type,
                    key: ValueKey('$groupName.${proxy.name}'),
                    proxy: proxy,
                    groupName: groupName,
                  ),
                ),
              )
              .fill(
                columns,
                filler: (_) => const Flexible(
                  child: SizedBox(),
                ),
              )
              .separated(
                const SizedBox(
                  width: 8,
                ),
              );

          return Row(
            children: children.toList(),
          );
        }).separated(
          const SizedBox(
            height: 8,
          ),
        );
        items.addAll(
          [
            ...rows,
            const SizedBox(
              height: 8,
            ),
          ],
        );
      }
    }
    _lastGroupNameProxiesMap = groupNameProxiesMap;
    return items;
  }

  _buildHeader(
    WidgetRef ref, {
    required String groupName,
    required Set<String> currentUnfoldSet,
  }) {
    final group =
        ref.read(groupsProvider.select((state) => state.getGroup(groupName)));
    if (group == null) {
      return SizedBox();
    }
    final isExpand = currentUnfoldSet.contains(groupName);
    return SizedBox(
      height: listHeaderHeight,
      child: ListHeader(
        enterAnimated: false,
        onScrollToSelected: _scrollToGroupSelected,
        key: Key(groupName),
        isExpand: isExpand,
        group: group,
        onChange: (String groupName) {
          _handleChange(currentUnfoldSet, groupName);
        },
      ),
    );
  }

  _scrollToGroupSelected(String groupName) {
    if (_controller.position.maxScrollExtent == 0) {
      return;
    }
    final appController = globalState.appController;
    final currentGroups = appController.getCurrentGroups();
    final groupNames = currentGroups.map((e) => e.name).toList();
    final findIndex = groupNames.indexWhere((item) => item == groupName);
    final index = findIndex != -1 ? findIndex : 0;
    final currentInitOffset = _headerOffset[index];
    final proxies = _lastGroupNameProxiesMap[groupName];
    _controller.animateTo(
      min(
        currentInitOffset +
            8 +
            getScrollToSelectedOffset(
              groupName: groupName,
              proxies: proxies ?? [],
            ),
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        final state = ref.watch(proxiesListSelectorStateProvider);
        if (state.groupNames.isEmpty) {
          return NullStatus(
            label: appLocalizations.nullProxies,
          );
        }
        final items = _buildItems(
          ref,
          groupNames: state.groupNames,
          currentUnfoldSet: state.currentUnfoldSet,
          columns: state.columns,
          type: state.proxyCardType,
        );
        final itemsOffset = _getItemHeightList(items, state.proxyCardType);
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
          child: CommonScrollBar(
            controller: _controller,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ScrollConfiguration(
                    behavior: HiddenBarScrollBehavior(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      controller: _controller,
                      itemExtentBuilder: (index, __) {
                        return itemsOffset[index];
                      },
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        return items[index];
                      },
                    ),
                  ),
                ),
                LayoutBuilder(builder: (_, container) {
                  return ValueListenableBuilder(
                    valueListenable: _headerStateNotifier,
                    builder: (_, headerState, ___) {
                      final index =
                          headerState.currentIndex > state.groupNames.length - 1
                              ? 0
                              : headerState.currentIndex;
                      if (index < 0 || state.groupNames.isEmpty) {
                        return Container();
                      }
                      return Stack(
                        children: [
                          Positioned(
                            top: -headerState.offset,
                            child: Container(
                              width: container.maxWidth,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    context.colorScheme.surface.withOpacity(0.95),
                                    context.colorScheme.surface.withOpacity(0.8),
                                  ],
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.colorScheme.outline.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 20,
                                right: 20,
                                bottom: 12,
                              ),
                              child: _buildHeader(
                                ref,
                                groupName: state.groupNames[index],
                                currentUnfoldSet: state.currentUnfoldSet,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ListHeader extends StatefulWidget {
  final Group group;

  final Function(String groupName) onChange;
  final Function(String groupName) onScrollToSelected;
  final bool isExpand;

  final bool enterAnimated;

  const ListHeader({
    super.key,
    this.enterAnimated = true,
    required this.group,
    required this.onChange,
    required this.onScrollToSelected,
    required this.isExpand,
  });

  @override
  State<ListHeader> createState() => _ListHeaderState();
}

class _ListHeaderState extends State<ListHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconTurns;
  var isLock = false;

  String get icon => widget.group.icon;

  String get groupName => widget.group.name;

  String get groupType => widget.group.type.name;

  bool get isExpand => widget.isExpand;

  _delayTest() async {
    if (isLock) return;
    isLock = true;
    await delayTest(
      widget.group.all,
      widget.group.testUrl,
    );
    isLock = false;
  }

  _handleChange(String groupName) {
    widget.onChange(groupName);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = _animationController.drive(
      Tween<double>(begin: 0.0, end: 0.5),
    );
    if (isExpand) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ListHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpand != widget.isExpand) {
      if (isExpand) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.surface.withOpacity(0.9),
                    context.colorScheme.surfaceVariant.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => _handleChange(groupName),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: context.colorScheme.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Modern icon container
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
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: context.colorScheme.primary.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildModernIcon(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Group info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                groupName,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        groupType,
                                        style: context.textTheme.labelSmall?.copyWith(
                                          color: context.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    Consumer(
                                      builder: (_, ref, __) {
                                        final proxyName = ref
                                            .watch(getSelectedProxyNameProvider(groupName))
                                            .getSafeValue("");
                                        if (proxyName.isEmpty) return const SizedBox();
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: context.colorScheme.onSurfaceVariant,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                proxyName,
                                                style: context.textTheme.labelSmall?.copyWith(
                                                  color: context.colorScheme.onSurfaceVariant,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 10,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isExpand) ...[
                              _buildActionButton(
                                Icons.my_location_rounded,
                                "Locate",
                                () => widget.onScrollToSelected(groupName),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                Icons.speed_rounded,
                                "Test",
                                _delayTest,
                              ),
                              const SizedBox(width: 12),
                            ],
                            // Expand/collapse button
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (_, __) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.primaryContainer.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.colorScheme.primary.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => _handleChange(groupName),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: RotationTransition(
                                          turns: _iconTurns,
                                          child: Icon(
                                            Icons.expand_more_rounded,
                                            color: context.colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
      },
    );
  }

  Widget _buildModernIcon() {
    return Consumer(
      builder: (_, ref, __) {
        final iconStyle = ref.watch(
            proxiesStyleSettingProvider.select((state) => state.iconStyle));
        final icon = ref.watch(proxiesStyleSettingProvider.select((state) {
          final iconMapEntryList = state.iconMap.entries.toList();
          final index = iconMapEntryList.indexWhere((item) {
            try {
              return RegExp(item.key).hasMatch(groupName);
            } catch (_) {
              return false;
            }
          });
          if (index != -1) {
            return iconMapEntryList[index].value;
          }
          return this.icon;
        }));
        
        return switch (iconStyle) {
          ProxiesIconStyle.standard => CommonTargetIcon(
              src: icon,
              size: 24,
            ),
          ProxiesIconStyle.icon => CommonTargetIcon(
              src: icon,
              size: 24,
            ),
          ProxiesIconStyle.none => Icon(
              Icons.hub_rounded,
              color: Colors.white,
              size: 24,
            ),
        };
      },
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
