import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/fragments/proxies/common.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProxyCard extends StatelessWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
  });

  Measure get measure => globalState.measure;

  _handleTestCurrentDelay() {
    proxyDelayTest(
      proxy,
      testUrl,
    );
  }

  Widget _buildDelayText() {
    return Consumer(
      builder: (context, ref, __) {
        final delay = ref.watch(getDelayProvider(
          proxyName: proxy.name,
          testUrl: testUrl,
        ));
        
        if (delay == 0) {
          return Container(
            padding: type == ProxyCardType.min 
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: type == ProxyCardType.min ? 8 : 10,
                  height: type == ProxyCardType.min ? 8 : 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Testing...",
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: type == ProxyCardType.min ? 9 : 10,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (delay == null) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _handleTestCurrentDelay,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: type == ProxyCardType.min 
                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                    : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: type == ProxyCardType.min ? 10 : 12,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "Test",
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: type == ProxyCardType.min ? 9 : 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Show delay result
        final isTimeout = delay < 0;
        final Color delayColor = isTimeout 
            ? context.colorScheme.error 
            : other.getDelayColor(delay) ?? context.colorScheme.onSurfaceVariant;
        
        return GestureDetector(
          onTap: _handleTestCurrentDelay,
          child: Container(
            padding: type == ProxyCardType.min 
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: delayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: delayColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: type == ProxyCardType.min ? 4 : 5,
                  height: type == ProxyCardType.min ? 4 : 5,
                  decoration: BoxDecoration(
                    color: delayColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isTimeout ? "Timeout" : "${delay}ms",
                  style: context.textTheme.labelSmall?.copyWith(
                    color: delayColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    fontSize: type == ProxyCardType.min ? 9 : 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProxyNameText(BuildContext context) {
    if (type == ProxyCardType.min) {
      return EmojiText(
        proxy.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyMedium,
      );
    } else {
      return EmojiText(
        proxy.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyMedium,
      );
    }
  }

  _changeProxy(WidgetRef ref) async {
    final isComputedSelected = groupType.isComputedSelected;
    final isSelector = groupType == GroupType.Selector;
    if (isComputedSelected || isSelector) {
      final currentProxyName = ref.read(getProxyNameProvider(groupName));
      final nextProxyName = switch (isComputedSelected) {
        true => currentProxyName == proxy.name ? "" : proxy.name,
        false => proxy.name,
      };
      final appController = globalState.appController;
      appController.updateCurrentSelectedMap(
        groupName,
        nextProxyName,
      );
      await appController.changeProxyDebounce(groupName, nextProxyName);
      return;
    }
    globalState.showNotifier(
      appLocalizations.notSelectedTip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final measure = globalState.measure;
    final delayText = _buildDelayText();
    final proxyNameText = _buildProxyNameText(context);
    
    return Consumer(
      builder: (_, ref, child) {
        final selectedProxyName =
            ref.watch(getSelectedProxyNameProvider(groupName));
        final isSelected = selectedProxyName == proxy.name;
        
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
          curve: Curves.easeOutCubic,
          builder: (context, animationValue, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected ? [
                    context.colorScheme.primaryContainer.withOpacity(0.8),
                    context.colorScheme.secondaryContainer.withOpacity(0.6),
                  ] : [
                    context.colorScheme.surface.withOpacity(0.7),
                    context.colorScheme.surfaceVariant.withOpacity(0.3),
                  ],
                ),
                border: Border.all(
                  color: isSelected 
                      ? context.colorScheme.primary.withOpacity(0.3)
                      : context.colorScheme.outline.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? context.colorScheme.primary.withOpacity(0.15)
                        : context.colorScheme.shadow.withOpacity(0.08),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: 0,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _changeProxy(ref),
                  splashColor: context.colorScheme.primary.withOpacity(0.1),
                  highlightColor: context.colorScheme.primary.withOpacity(0.05),
                  child: Stack(
                    children: [
                      // Background pattern for selected state
                      if (isSelected)
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  context.colorScheme.primary.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Main content
                      Container(
                        padding: type == ProxyCardType.min 
                            ? const EdgeInsets.all(6) 
                            : const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Proxy name with icon
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: type == ProxyCardType.min 
                                      ? const EdgeInsets.all(4)
                                      : const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.colorScheme.primary.withOpacity(0.1)
                                        : context.colorScheme.surfaceVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getProxyTypeIcon(proxy.type),
                                    size: type == ProxyCardType.min ? 14 : 16,
                                    color: isSelected
                                        ? context.colorScheme.primary
                                        : context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: type == ProxyCardType.min ? 8 : 12),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: proxyNameText,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: type == ProxyCardType.min ? 2 : 8),
                            
                            // Type and delay info
                            if (type == ProxyCardType.expand) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: _buildProxyTypeChip(context, isSelected),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerRight,
                                    child: delayText,
                                  ),
                                ],
                              ),
                            ] else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: _buildProxyTypeChip(context, isSelected),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerRight,
                                    child: delayText,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      // Selection indicator
                      if (groupType.isComputedSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _ProxyComputedMark(
                            groupName: groupName,
                            proxy: proxy,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getProxyTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'shadowsocks':
      case 'ss':
        return Icons.security_rounded;
      case 'vmess':
        return Icons.vpn_lock_rounded;
      case 'trojan':
        return Icons.shield_rounded;
      case 'hysteria':
      case 'hysteria2':
        return Icons.speed_rounded;
      case 'wireguard':
      case 'wg':
        return Icons.hub_rounded;
      case 'vless':
        return Icons.lock_outline_rounded;
      case 'tuic':
        return Icons.fiber_smart_record_rounded;
      case 'http':
      case 'https':
        return Icons.http_rounded;
      case 'socks5':
        return Icons.dns_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  Widget _buildProxyTypeChip(BuildContext context, bool isSelected) {
    return Container(
      padding: type == ProxyCardType.min 
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? context.colorScheme.primary.withOpacity(0.1)
            : context.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? context.colorScheme.primary.withOpacity(0.3)
              : context.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        proxy.type,
        style: context.textTheme.labelSmall?.copyWith(
          color: isSelected
              ? context.colorScheme.primary
              : context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          fontSize: type == ProxyCardType.min ? 9 : 10,
        ),
      ),
    );
  }
}

class _ProxyDesc extends ConsumerWidget {
  final Proxy proxy;

  const _ProxyDesc({
    required this.proxy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desc = ref.watch(
      getProxyDescProvider(proxy),
    );
    return EmojiText(
      desc,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textTheme.bodySmall?.color?.withOpacity(0.8),
      ),
    );
  }
}

class _ProxyComputedMark extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;

  const _ProxyComputedMark({
    required this.groupName,
    required this.proxy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref.watch(
      getProxyNameProvider(groupName),
    );
    if (proxyName != proxy.name) {
      return const SizedBox();
    }
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colorScheme.primary,
                  context.colorScheme.tertiary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
