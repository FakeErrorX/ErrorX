import 'dart:io';
import 'dart:ui';
import 'dart:math';

import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item.dart';

double _preOffset = 0;

class RequestsFragment extends ConsumerStatefulWidget {
  const RequestsFragment({super.key});

  @override
  ConsumerState<RequestsFragment> createState() => _RequestsFragmentState();
}

class _RequestsFragmentState extends ConsumerState<RequestsFragment>
    with PageMixin, SingleTickerProviderStateMixin {
  final GlobalKey<CacheItemExtentListViewState> _key = GlobalKey();
  final _requestsStateNotifier =
      ValueNotifier<ConnectionsState>(const ConnectionsState());
  List<Connection> _requests = [];

  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _preOffset != 0 ? _preOffset : double.maxFinite,
  );

  late AnimationController _animationController;
  double _currentMaxWidth = 0;

  @override
  get onSearch => (value) {
        _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
          query: value,
        );
      };

  @override
  get onKeywordsUpdate => (keywords) {
        _requestsStateNotifier.value =
            _requestsStateNotifier.value.copyWith(keywords: keywords);
      };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      connections: globalState.appState.requests.list,
    );

    ref.listenManual(
      isCurrentPageProvider(
        PageLabel.requests,
        handler: (pageLabel, viewMode) =>
            pageLabel == PageLabel.tools && viewMode == ViewMode.mobile,
      ),
      (prev, next) {
        if (prev != next && next == true) {
          initPageState();
          _animationController.reset();
          _animationController.forward();
        }
      },
      fireImmediately: true,
    );
    ref.listenManual(
      requestsProvider.select((state) => state.list),
      (prev, next) {
        if (!connectionListEquality.equals(prev, next)) {
          _requests = next;
          updateRequestsThrottler();
        }
      },
      fireImmediately: true,
    );
  }

  double _calcCacheHeight(Connection item) {
    final size = globalState.measure.computeTextSize(
      Text(
        item.desc,
        style: context.textTheme.bodyLarge,
      ),
      maxWidth: _currentMaxWidth,
    );
    final chainsText = item.chains.join("");
    final length = item.chains.length;
    final chainSize = globalState.measure.computeTextSize(
      Text(
        chainsText,
        style: context.textTheme.bodyMedium,
      ),
      maxWidth: (_currentMaxWidth - (length - 1) * 6 - length * 24),
    );
    final baseHeight = globalState.measure.bodyMediumHeight;
    final lines = (chainSize.height / baseHeight).round();
    final computerHeight =
        size.height + chainSize.height + 24 + 24 * (lines - 1);
    return computerHeight;
  }

  _handleTryClearCache(double maxWidth) {
    if (_currentMaxWidth != maxWidth) {
      _currentMaxWidth = maxWidth;
      _key.currentState?.clearCache();
    }
  }

  @override
  void dispose() {
    // Cancel any pending throttler calls
    throttler.cancel("request");
    _requestsStateNotifier.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _currentMaxWidth = 0;
    super.dispose();
  }

  updateRequestsThrottler() {
    throttler.call("request", () {
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        return;
      }
      
      final isEquality = connectionListEquality.equals(
        _requests,
        _requestsStateNotifier.value.connections,
      );
      if (isEquality) {
        return;
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double-check if still mounted before updating ValueNotifier
        if (!mounted) {
          return;
        }
        
        try {
          _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
            connections: _requests,
          );
        } catch (e) {
          // Ignore errors if notifier was disposed
          commonPrint.log('Error updating requests: $e');
        }
      });
    }, duration: commonDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colorScheme.surface,
                context.colorScheme.background.withOpacity(0.95),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        
        // Content
        LayoutBuilder(
          builder: (_, constraints) {
            return Consumer(
              builder: (_, ref, child) {
                final value = ref.watch(
                  patchClashConfigProvider.select(
                    (state) =>
                        state.findProcessMode == FindProcessMode.always &&
                        Platform.isAndroid,
                  ),
                );
                _handleTryClearCache(constraints.maxWidth - 40 - (value ? 60 : 0));
                return child!;
              },
              child: ValueListenableBuilder<ConnectionsState>(
                valueListenable: _requestsStateNotifier,
                builder: (_, state, __) {
                  final connections = state.list;
                  
                  if (connections.isEmpty) {
                    return FadeTransition(
                      opacity: _animationController,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.colorScheme.surfaceVariant.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.view_timeline,
                                size: 40,
                                color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              appLocalizations.nullRequestsDesc,
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Network requests will appear here as they occur",
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final items = connections
                      .asMap()
                      .entries
                      .map<Widget>(
                        (entry) {
                          final index = entry.key;
                          final connection = entry.value;
                          
                          final double startInterval = min(0.2 + min(index * 0.03, 0.5), 0.7);
                          final double endInterval = min(startInterval + 0.3, 1.0);
                          
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  startInterval,
                                  endInterval,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.colorScheme.surface.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.colorScheme.shadow.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ConnectionItem(
                                  key: Key(connection.id),
                                  connection: connection,
                                  onClickKeyword: (value) {
                                    context.commonScaffoldState?.addKeyword(value);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      )
                      .separated(
                        const SizedBox(height: 8),
                      )
                      .toList();
                      
                  return FadeTransition(
                    opacity: _animationController,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: NotificationListener<ScrollEndNotification>(
                            onNotification: (details) {
                              _preOffset = details.metrics.pixels;
                              return false;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: CommonScrollBar(
                                controller: _scrollController,
                                child: CacheItemExtentListView(
                                  key: _key,
                                  reverse: true,
                                  shrinkWrap: true,
                                  physics: NextClampingScrollPhysics(),
                                  controller: _scrollController,
                                  itemExtentBuilder: (index) {
                                    final widget = items[index];
                                    if (widget.runtimeType == SizedBox) {
                                      return 8;  // Height of the SizedBox separator
                                    }
                                    final measure = globalState.measure;
                                    final bodyMediumHeight = measure.bodyMediumHeight;
                                    final connection = connections[(index / 2).floor()];
                                    final height = _calcCacheHeight(connection);
                                    return height + bodyMediumHeight + 32 + 8;  // Added padding
                                  },
                                  itemBuilder: (_, index) {
                                    return items[index];
                                  },
                                  itemCount: items.length,
                                  keyBuilder: (int index) {
                                    final widget = items[index];
                                    if (widget.runtimeType == SizedBox) {
                                      return "spacer_$index";
                                    }
                                    final connection = connections[(index / 2).floor()];
                                    return connection.id;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
