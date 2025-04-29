import 'dart:io';
import 'dart:ui';

import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

typedef OnSelected = void Function(int index);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeBackScope(
      child: Consumer(
        builder: (_, ref, child) {
          final state = ref.watch(homeStateProvider);
          final viewMode = state.viewMode;
          final navigationItems = state.navigationItems;
          final pageLabel = state.pageLabel;
          final index = navigationItems.lastIndexWhere(
            (element) => element.label == pageLabel,
          );
          final currentIndex = index == -1 ? 0 : index;
          final navigationBar = CommonNavigationBar(
            viewMode: viewMode,
            navigationItems: navigationItems,
            currentIndex: currentIndex,
          );
          final bottomNavigationBar =
              viewMode == ViewMode.mobile ? navigationBar : null;
          final sideNavigationBar =
              viewMode != ViewMode.mobile ? navigationBar : null;
          return CommonScaffold(
            key: globalState.homeScaffoldKey,
            title: Intl.message(
              pageLabel.name,
            ),
            sideNavigationBar: sideNavigationBar,
            body: SafeArea(
              bottom: viewMode != ViewMode.mobile,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.colorScheme.background,
                      context.colorScheme.background.withOpacity(0.95),
                    ],
                  ),
                ),
                child: child!,
              ),
            ),
            bottomNavigationBar: bottomNavigationBar,
          );
        },
        child: _HomePageView(),
      ),
    );
  }
}

class _HomePageView extends ConsumerStatefulWidget {
  const _HomePageView();

  @override
  ConsumerState createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<_HomePageView> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _pageIndex,
      keepPage: true,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      if (prev != next) {
        _toPage(next);
      }
    });
    ref.listenManual(currentNavigationsStateProvider, (prev, next) {
      if (prev?.value.length != next.value.length) {
        _updatePageController();
      }
    });
  }

  int get _pageIndex {
    final navigationItems = ref.read(currentNavigationsStateProvider).value;
    return navigationItems.indexWhere(
      (item) => item.label == globalState.appState.pageLabel,
    );
  }

  _toPage(PageLabel pageLabel, [bool ignoreAnimateTo = false]) async {
    if (!mounted) {
      return;
    }
    final navigationItems = ref.read(currentNavigationsStateProvider).value;
    final index = navigationItems.indexWhere((item) => item.label == pageLabel);
    if (index == -1) {
      return;
    }
    final isAnimateToPage = ref.read(appSettingProvider).isAnimateToPage;
    final isMobile = ref.read(isMobileViewProvider);
    
    // Reset and run the animation
    _animationController.reset();
    _animationController.forward();
    
    if (isAnimateToPage && isMobile && !ignoreAnimateTo) {
      await _pageController.animateToPage(
        index,
        duration: kTabScrollDuration,
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  _updatePageController() {
    final pageLabel = globalState.appState.pageLabel;
    _toPage(pageLabel, true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = ref.watch(currentNavigationsStateProvider).value;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      ),
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: navigationItems.length,
        itemBuilder: (_, index) {
          final navigationItem = navigationItems[index];
          return KeepScope(
            keep: navigationItem.keep,
            key: Key(navigationItem.label.name),
            child: navigationItem.fragment,
          );
        },
      ),
    );
  }
}

class CommonNavigationBar extends ConsumerWidget {
  final ViewMode viewMode;
  final List<NavigationItem> navigationItems;
  final int currentIndex;

  const CommonNavigationBar({
    super.key,
    required this.viewMode,
    required this.navigationItems,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, ref) {
    if (viewMode == ViewMode.mobile) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            margin: EdgeInsets.only(bottom: Platform.isAndroid ? MediaQuery.of(context).padding.bottom : 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colorScheme.surfaceContainer.withOpacity(0.92),
                  context.colorScheme.surface.withOpacity(0.96),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.shadow.withOpacity(0.18),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -3),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.outlineVariant.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                navigationItems.length,
                (index) {
                  final item = navigationItems[index];
                  final isSelected = index == currentIndex;
                  
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0, 
                      end: isSelected ? 1.0 : 0.0
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      // Interpolate colors for smooth transitions
                      final bgColor = Color.lerp(
                        Colors.transparent,
                        context.colorScheme.secondaryContainer,
                        value
                      )!;
                      
                      final iconColor = Color.lerp(
                        context.colorScheme.onSurfaceVariant,
                        context.colorScheme.primary,
                        value
                      )!;
                      
                      final textColor = Color.lerp(
                        context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        context.colorScheme.primary,
                        value
                      )!;
                      
                      return SizedBox(
                        height: 54,
                        width: 48,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Premium button with subtle effects
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: context.colorScheme.primary.withOpacity(0.16 * value),
                                    blurRadius: 8 * value,
                                    spreadRadius: 0,
                                  ),
                                ] : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    globalState.appController.toPage(navigationItems[index].label);
                                  },
                                  splashColor: context.colorScheme.primary.withOpacity(0.12),
                                  highlightColor: Colors.transparent,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: context.colorScheme.primary.withOpacity(0.05 + 0.15 * value),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        (item.icon as Icon).icon,
                                        color: iconColor,
                                        size: 20 + (2 * value),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Label with animated color
                            Text(
                              Intl.message(item.label.name),
                              style: context.textTheme.labelSmall!.copyWith(
                                fontSize: 9,
                                height: 1.0,
                                letterSpacing: 0.2,
                                color: textColor,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
    
    final showLabel = ref.watch(appSettingProvider).showLabel;
    return Container(
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colorScheme.surface.withOpacity(0.98),
            context.colorScheme.surfaceContainer.withOpacity(0.94),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.12),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Premium navigation items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          navigationItems.length,
                          (index) {
                            final item = navigationItems[index];
                            final isSelected = index == currentIndex;
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0.0, 
                                end: isSelected ? 1.0 : 0.0
                              ),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                final selectedColor = Color.lerp(
                                  context.colorScheme.surface, 
                                  context.colorScheme.secondaryContainer,
                                  value
                                )!;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Premium item with subtle glow
                                      Container(
                                        decoration: BoxDecoration(
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: context.colorScheme.primary.withOpacity(0.16 * value),
                                              blurRadius: 8 * value,
                                              spreadRadius: 0,
                                            ),
                                          ] : null,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(14),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () {
                                              globalState.appController
                                                  .toPage(navigationItems[index].label);
                                            },
                                            splashColor: context.colorScheme.primary.withOpacity(0.12),
                                            highlightColor: context.colorScheme.primary.withOpacity(0.08),
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                color: selectedColor,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: context.colorScheme.primary.withOpacity(0.05 + 0.15 * value),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  (item.icon as Icon).icon,
                                                  color: Color.lerp(
                                                    context.colorScheme.onSurfaceVariant,
                                                    context.colorScheme.primary,
                                                    value,
                                                  ),
                                                  size: 22 + (2 * value),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Text with consistent height
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        height: showLabel ? 16 : 8,
                                        width: 56,
                                        margin: const EdgeInsets.only(top: 4),
                                        child: showLabel 
                                          ? Text(
                                              Intl.message(item.label.name),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: context.textTheme.labelSmall!.copyWith(
                                                fontSize: 9.0,
                                                color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                                fontWeight: FontWeight.normal,
                                                height: 1.2,
                                                letterSpacing: 0.2,
                                              ),
                                            )
                                          : null,
                                      ),
                                    ],
                                  ),
                                );
                              }
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 1, 
                  indent: 16, 
                  endIndent: 16,
                  color: Colors.white10,
                ),
                // Enhanced toggle button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ref.read(appSettingProvider.notifier).updateState(
                              (state) => state.copyWith(
                                showLabel: !state.showLabel,
                              ),
                            );
                      },
                      splashColor: context.colorScheme.primary.withOpacity(0.15),
                      highlightColor: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: showLabel 
                                ? [
                                    context.colorScheme.primaryContainer.withOpacity(0.5),
                                    context.colorScheme.tertiaryContainer.withOpacity(0.3),
                                  ]
                                : [
                                    context.colorScheme.surfaceVariant.withOpacity(0.4),
                                    context.colorScheme.surfaceVariant.withOpacity(0.2),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: showLabel
                                ? context.colorScheme.primary.withOpacity(0.1)
                                : context.colorScheme.outlineVariant.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            showLabel 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                            color: showLabel
                                ? context.colorScheme.primary.withOpacity(0.9)
                                : context.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBarDefaultsM3 extends NavigationBarThemeData {
  _NavigationBarDefaultsM3(this.context)
      : super(
          height: 80.0,
          elevation: 0.0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get backgroundColor => Colors.transparent;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  WidgetStateProperty<IconThemeData?>? get iconTheme {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      return IconThemeData(
        size: 24.0,
        color: states.contains(WidgetState.disabled)
            ? _colors.onSurfaceVariant.opacity38
            : states.contains(WidgetState.selected)
                ? _colors.onSecondaryContainer
                : _colors.onSurfaceVariant,
      );
    });
  }

  @override
  Color? get indicatorColor => Colors.transparent;

  @override
  ShapeBorder? get indicatorShape => const StadiumBorder();

  @override
  WidgetStateProperty<TextStyle?>? get labelTextStyle {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      final TextStyle style = _textTheme.labelMedium!;
      return style.apply(
          overflow: TextOverflow.ellipsis,
          color: states.contains(WidgetState.disabled)
              ? _colors.onSurfaceVariant.opacity38
              : states.contains(WidgetState.selected)
                  ? _colors.onSurface
                  : _colors.onSurfaceVariant);
    });
  }
}

class HomeBackScope extends StatelessWidget {
  final Widget child;

  const HomeBackScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return CommonPopScope(
        onPop: () async {
          final canPop = Navigator.canPop(context);
          if (canPop) {
            Navigator.pop(context);
          } else {
            await globalState.appController.handleBackOrExit();
          }
          return false;
        },
        child: child,
      );
    }
    return child;
  }
}
