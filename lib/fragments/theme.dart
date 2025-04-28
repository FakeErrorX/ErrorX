import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

class ThemeModeItem {
  final ThemeMode themeMode;
  final IconData iconData;
  final String label;

  const ThemeModeItem({
    required this.themeMode,
    required this.iconData,
    required this.label,
  });
}

class FontFamilyItem {
  final FontFamily fontFamily;
  final String label;

  const FontFamilyItem({
    required this.fontFamily,
    required this.label,
  });
}

class ThemeFragment extends StatefulWidget {
  const ThemeFragment({super.key});

  @override
  State<ThemeFragment> createState() => _ThemeFragmentState();
}

class _ThemeFragmentState extends State<ThemeFragment> with SingleTickerProviderStateMixin {
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
    final headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutQuint),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern animated header with glass effect
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(headerAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(headerAnimation),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Stack(
                    children: [
                      // Background gradient elements
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                context.colorScheme.primary.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -15,
                        left: -15,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                context.colorScheme.tertiary.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Glass container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  context.colorScheme.surface.withOpacity(0.7),
                                  context.colorScheme.surface.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: context.colorScheme.primary.withOpacity(0.1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.colorScheme.shadow.withOpacity(0.08),
                                  blurRadius: 15,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Theme icon with animated background
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        context.colorScheme.primary.withOpacity(0.7),
                                        context.colorScheme.tertiary.withOpacity(0.7),
                                        context.colorScheme.secondary.withOpacity(0.7),
                                        context.colorScheme.primary.withOpacity(0.7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.color_lens_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Title with gradient text
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      context.colorScheme.primary,
                                      context.colorScheme.tertiary,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    appLocalizations.themeMode,
                                    style: context.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                
                                // Subtitle with better typography
                                Text(
                                  "Personalize your app experience",
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.titleMedium?.copyWith(
                                    color: context.colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Quick theme toggles as chips
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final themeMode = ref.watch(themeSettingProvider.select((state) => state.themeMode));
                                        return Wrap(
                                          spacing: 8,
                                          children: [
                                            _buildThemeChip(
                                              context,
                                              Icons.auto_mode_rounded,
                                              "Auto",
                                              themeMode == ThemeMode.system,
                                              () => ref.read(themeSettingProvider.notifier).updateState(
                                                (state) => state.copyWith(themeMode: ThemeMode.system),
                                              ),
                                            ),
                                            _buildThemeChip(
                                              context,
                                              Icons.light_mode_rounded,
                                              "Light",
                                              themeMode == ThemeMode.light,
                                              () => ref.read(themeSettingProvider.notifier).updateState(
                                                (state) => state.copyWith(themeMode: ThemeMode.light),
                                              ),
                                            ),
                                            _buildThemeChip(
                                              context,
                                              Icons.dark_mode_rounded,
                                              "Dark",
                                              themeMode == ThemeMode.dark,
                                              () => ref.read(themeSettingProvider.notifier).updateState(
                                                (state) => state.copyWith(themeMode: ThemeMode.dark),
                                              ),
                                            ),
                                          ],
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
                    ],
                  ),
                ),
              ),
            ),

            // Theme color options and black mode
            const ThemeColorsBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(BuildContext context, IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.colorScheme.primaryContainer 
              : context.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? context.colorScheme.primary 
                : context.colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: context.colorScheme.primary.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? context.colorScheme.primary 
                  : context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? context.colorScheme.primary 
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Widget child;
  final Info info;

  const ItemCard({
    super.key,
    required this.info,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
        children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      info.iconData,
                      size: 22,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    info.label,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
          child,
        ],
          ),
        ),
      ),
    );
  }
}

class ThemeColorsBox extends ConsumerStatefulWidget {
  const ThemeColorsBox({super.key});

  @override
  ConsumerState<ThemeColorsBox> createState() => _ThemeColorsBoxState();
}

class _ThemeColorsBoxState extends ConsumerState<ThemeColorsBox> with SingleTickerProviderStateMixin {
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
    final themeMode = ref.watch(themeSettingProvider.select((state) => state.themeMode));
    final isDarkMode = themeMode == ThemeMode.dark || 
                       (themeMode == ThemeMode.system && 
                        MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Column(
      children: [
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
              ),
            ),
            child: _PrimaryColorItem(),
          ),
        ),
        if (isDarkMode)
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.5, 0.9, curve: Curves.easeOutBack),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
                ),
              ),
              child: _PrueBlackItem(),
            ),
          ),
        const SizedBox(
          height: 64,
        ),
      ],
    );
  }
}

class _PrimaryColorItem extends ConsumerWidget {
  const _PrimaryColorItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor =
        ref.watch(themeSettingProvider.select((state) => state.primaryColor));
    
    // Color definitions with names
    final List<Map<String, dynamic>> colorOptions = [
      {'color': null, 'name': 'Auto', 'isSystem': true},
      {'color': defaultPrimaryColor, 'name': 'Purple'},
      {'color': Colors.pinkAccent, 'name': 'Pink'},
      {'color': Colors.lightBlue, 'name': 'Blue'},
      {'color': Colors.greenAccent, 'name': 'Green'},
      {'color': Colors.yellowAccent, 'name': 'Yellow'},
      {'color': Colors.purple.shade700, 'name': 'Violet'},
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colorScheme.surface.withOpacity(0.7),
                  context.colorScheme.surface.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.colorScheme.primary.withOpacity(0.1),
                width: 1.5,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with minimal design
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          context.colorScheme.primary,
                          context.colorScheme.tertiary,
                        ],
                      ).createShader(bounds),
                      child: Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      appLocalizations.themeColor,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Color grid with system auto detection indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85, // Adjusted for the labels
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final option = colorOptions[index];
                      final Color? color = option['color'];
                      final bool isSystemAuto = option['isSystem'] ?? false;
                      final String colorName = option['name'];
                      final bool isSelected = color?.toARGB32() == primaryColor;
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                ref.read(themeSettingProvider.notifier).updateState(
                      (state) => state.copyWith(
                        primaryColor: color?.toARGB32(),
                      ),
                    );
              },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSystemAuto 
                                    ? null 
                                    : color,
                                gradient: isSystemAuto ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade300,
                                    Colors.purple.shade300,
                                    Colors.orange.shade300,
                                  ],
                                ) : null,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSystemAuto 
                                        ? context.colorScheme.primary 
                                        : (color ?? context.colorScheme.surface))
                                        .withOpacity(isSelected ? 0.4 : 0.1),
                                    blurRadius: isSelected ? 8 : 2,
                                    spreadRadius: isSelected ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isSystemAuto 
                                    ? Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : isSelected 
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              colorName,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: isSelected 
                                    ? context.colorScheme.primary 
                                    : context.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
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

class _PrueBlackItem extends ConsumerWidget {
  const _PrueBlackItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pureBlack =
        ref.watch(themeSettingProvider.select((state) => state.pureBlack));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colorScheme.surface.withOpacity(0.7),
                  context.colorScheme.surface.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.colorScheme.primary.withOpacity(0.1),
                width: 1.5,
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
            child: Row(
              children: [
                // Moon icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        pureBlack ? Colors.black.withOpacity(0.9) : Colors.indigo.withOpacity(0.7),
                        pureBlack ? Colors.grey.shade900.withOpacity(0.9) : Colors.deepPurple.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pureBlack ? Colors.black.withOpacity(0.3) : context.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.dark_mode_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations.pureBlackMode,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Perfect for OLED displays",
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Custom Switch
                GestureDetector(
                  onTap: () {
                    ref.read(themeSettingProvider.notifier).updateState(
                      (state) => state.copyWith(pureBlack: !pureBlack),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: pureBlack
                            ? [Colors.black, Colors.grey.shade900]
                            : [
                                context.colorScheme.surfaceVariant.withOpacity(0.7),
                                context.colorScheme.surfaceVariant.withOpacity(0.5),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          alignment: pureBlack ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pureBlack
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: context.colorScheme.shadow.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                pureBlack ? Icons.dark_mode : Icons.light_mode,
                                size: 16,
                                color: pureBlack
                                    ? Colors.grey.shade400
                                    : Colors.amber.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
