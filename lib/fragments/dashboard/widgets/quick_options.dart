import 'package:errorx/common/common.dart';
import 'package:errorx/fragments/config/network.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tun_info_dialog.dart';
import 'system_proxy_info_dialog.dart';

class PremiumToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final IconData? icon;

  const PremiumToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.icon,
  });

  @override
  State<PremiumToggleSwitch> createState() => _PremiumToggleSwitchState();
}

class _PremiumToggleSwitchState extends State<PremiumToggleSwitch>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<Color?> _backgroundAnimation;
  late Animation<Color?> _borderAnimation;
  late Animation<double> _thumbScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );


    _thumbScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PremiumToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTap() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    _backgroundAnimation = ColorTween(
      begin: colorScheme.surfaceVariant.withOpacity(0.3),
      end: colorScheme.primary.withOpacity(0.15),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderAnimation = ColorTween(
      begin: colorScheme.outline.withOpacity(0.4),
      end: colorScheme.primary.withOpacity(0.6),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _scaleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0,
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _backgroundAnimation.value!,
                    _backgroundAnimation.value!.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderAnimation.value!,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.value 
                        ? colorScheme.primary.withOpacity(0.3)
                        : colorScheme.outline.withOpacity(0.15),
                    blurRadius: widget.value ? 6 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  if (widget.value)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              colorScheme.primary.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Toggle thumb with premium styling
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    left: widget.value ? 20.0 : 2.0,
                    top: 2.0,
                    child: Transform.scale(
                      scale: _thumbScaleAnimation.value,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.value
                                ? [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.9),
                                  ]
                                : [
                                    colorScheme.surface,
                                    colorScheme.surfaceVariant,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: widget.value
                                  ? colorScheme.primary.withOpacity(0.5)
                                  : colorScheme.outline.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                            if (widget.value)
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            widget.value ? Icons.check_rounded : Icons.close_rounded,
                            key: ValueKey(widget.value),
                            size: 8,
                            color: widget.value
                                ? Colors.white
                                : colorScheme.outline.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TUNButton extends StatelessWidget {
  const TUNButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: generateListView(
                  generateSection(
                    items: [
                      if (system.isDesktop) const TUNItem(),
                      const TunStackItem(),
                    ],
                  ),
                ),
                title: appLocalizations.tun,
              );
            },
          );
        },
        info: Info(
          label: appLocalizations.tun,
          iconData: Icons.stacked_line_chart,
        ),
        actions: [
          IconButton(
            onPressed: () {
              globalState.showCommonDialog(
                child: const TunInfoDialog(),
              );
            },
            icon: const Icon(Icons.info_outline),
            iconSize: 14,
            tooltip: "TUN Information",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              minimumSize: const Size(20, 20),
              maximumSize: const Size(20, 20),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: Text(
                  appLocalizations.options,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                        fontSize: 12,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Consumer(
                builder: (_, ref, __) {
                  final enable = ref.watch(patchClashConfigProvider
                      .select((state) => state.tun.enable));
                  return PremiumToggleSwitch(
                    value: enable,
                    onChanged: (value) {
                      ref.read(patchClashConfigProvider.notifier).updateState(
                            (state) => state.copyWith.tun(
                              enable: value,
                            ),
                          );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SystemProxyButton extends StatelessWidget {
  const SystemProxyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: generateListView(
                  generateSection(
                    items: [
                      SystemProxyItem(),
                      BypassDomainItem(),
                    ],
                  ),
                ),
                title: appLocalizations.systemProxy,
              );
            },
          );
        },
        info: Info(
          label: appLocalizations.systemProxy,
          iconData: Icons.shuffle,
        ),
        actions: [
          IconButton(
            onPressed: () {
              globalState.showCommonDialog(
                child: const SystemProxyInfoDialog(),
              );
            },
            icon: const Icon(Icons.info_outline),
            iconSize: 14,
            tooltip: "System Proxy Information",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              minimumSize: const Size(20, 20),
              maximumSize: const Size(20, 20),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: Text(
                  appLocalizations.options,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                        fontSize: 12,
                      ),
                ),
              ),
              Consumer(
                builder: (_, ref, __) {
                  final systemProxy = ref.watch(networkSettingProvider
                      .select((state) => state.systemProxy));
                  return PremiumToggleSwitch(
                    value: systemProxy,
                    onChanged: (value) {
                      ref.read(networkSettingProvider.notifier).updateState(
                            (state) => state.copyWith(
                              systemProxy: value,
                            ),
                          );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
