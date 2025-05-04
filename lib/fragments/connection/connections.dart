import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item.dart';

class ConnectionsFragment extends ConsumerStatefulWidget {
  const ConnectionsFragment({super.key});

  @override
  ConsumerState<ConnectionsFragment> createState() =>
      _ConnectionsFragmentState();
}

class _ConnectionsFragmentState extends ConsumerState<ConnectionsFragment>
    with PageMixin, SingleTickerProviderStateMixin {
  final _connectionsStateNotifier = ValueNotifier<ConnectionsState>(
    const ConnectionsState(),
  );
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  
  late AnimationController _animationController;
  Timer? timer;

  @override
  List<Widget> get actions => [
        Consumer(
          builder: (context, ref, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.5, curve: Curves.easeOutCubic),
                  )),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      context.colorScheme.errorContainer.withOpacity(0.7),
                      context.colorScheme.errorContainer.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    splashColor: context.colorScheme.onErrorContainer.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      clashCore.closeConnections();
                      _connectionsStateNotifier.value =
                          _connectionsStateNotifier.value.copyWith(
                        connections: await clashCore.getConnections(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            color: context.colorScheme.onErrorContainer,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Clear All",
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
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
        ),
      ];

  @override
  get onSearch => (value) {
        _connectionsStateNotifier.value =
            _connectionsStateNotifier.value.copyWith(
          query: value,
        );
      };

  @override
  get onKeywordsUpdate => (keywords) {
        _connectionsStateNotifier.value =
            _connectionsStateNotifier.value.copyWith(keywords: keywords);
      };

  _updateConnections() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _connectionsStateNotifier.value =
          _connectionsStateNotifier.value.copyWith(
        connections: await clashCore.getConnections(),
      );
      timer = Timer(const Duration(seconds: 1), () async {
        _updateConnections();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    
    ref.listenManual(
      isCurrentPageProvider(
        PageLabel.connections,
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
    _updateConnections();
  }

  _handleBlockConnection(String id) async {
    clashCore.closeConnection(id);
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      connections: await clashCore.getConnections(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _connectionsStateNotifier.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    timer = null;
    super.dispose();
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
            ),
          ),
        ),
        
        // Content
        ValueListenableBuilder<ConnectionsState>(
          valueListenable: _connectionsStateNotifier,
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
                          Icons.lan_outlined,
                          size: 40,
                          color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        appLocalizations.nullConnectionsDesc,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Active network connections will appear here",
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
            
            return FadeTransition(
              opacity: _animationController,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: CommonScrollBar(
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (_, index) {
                        final connection = connections[index];
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                min(0.2 + min(index * 0.05, 0.5), 0.7),
                                min(0.6 + min(index * 0.05, 0.4), 1.0),
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
                                trailing: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: IconButton(
                                    icon: const Icon(Icons.block),
                                    color: context.colorScheme.error,
                                    onPressed: () {
                                      _handleBlockConnection(connection.id);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: connections.length,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
