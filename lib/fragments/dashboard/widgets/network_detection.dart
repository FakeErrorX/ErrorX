import 'dart:async';

import 'package:dio/dio.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/app.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _networkDetectionState = ValueNotifier<NetworkDetectionState>(
  const NetworkDetectionState(
    isTesting: false,
    isLoading: true,
    ipInfo: null,
  ),
);

class NetworkDetection extends ConsumerStatefulWidget {
  const NetworkDetection({super.key});

  @override
  ConsumerState<NetworkDetection> createState() => _NetworkDetectionState();
}

class _NetworkDetectionState extends ConsumerState<NetworkDetection> {
  bool? _preIsStart;
  Timer? _setTimeoutTimer;
  CancelToken? cancelToken;
  bool _showIP = false; // Track whether to show the real IP or masked version

  @override
  void initState() {
    ref.listenManual(checkIpNumProvider, (prev, next) {
      if (prev != next) {
        _startCheck();
      }
    });
    if (!_networkDetectionState.value.isTesting &&
        _networkDetectionState.value.isLoading) {
      _startCheck();
    }
    super.initState();
  }

  _startCheck() async {
    if (cancelToken != null) {
      cancelToken!.cancel();
      cancelToken = null;
    }
    debouncer.call(
      DebounceTag.checkIp,
      _checkIp,
    );
  }

  _checkIp() async {
    final appState = globalState.appState;
    final isInit = appState.isInit;
    if (!isInit) return;
    final isStart = appState.runTime != null;
    if (_preIsStart == false &&
        _preIsStart == isStart &&
        _networkDetectionState.value.ipInfo != null) {
      return;
    }
    _clearSetTimeoutTimer();
    _networkDetectionState.value = _networkDetectionState.value.copyWith(
      isLoading: true,
      ipInfo: null,
    );
    _preIsStart = isStart;
    if (cancelToken != null) {
      cancelToken!.cancel();
      cancelToken = null;
    }
    cancelToken = CancelToken();
    try {
      _networkDetectionState.value = _networkDetectionState.value.copyWith(
        isTesting: true,
      );
      final ipInfo = await request.checkIp(cancelToken: cancelToken);
      _networkDetectionState.value = _networkDetectionState.value.copyWith(
        isTesting: false,
      );
      if (ipInfo != null) {
        _networkDetectionState.value = _networkDetectionState.value.copyWith(
          isLoading: false,
          ipInfo: ipInfo,
        );
        return;
      }
      _clearSetTimeoutTimer();
      _setTimeoutTimer = Timer(const Duration(milliseconds: 300), () {
        _networkDetectionState.value = _networkDetectionState.value.copyWith(
          isLoading: false,
          ipInfo: null,
        );
      });
    } catch (e) {
      if (e.toString() == "cancelled") {
        _networkDetectionState.value = _networkDetectionState.value.copyWith(
          isLoading: true,
          ipInfo: null,
        );
      }
    }
  }

  @override
  void dispose() {
    _clearSetTimeoutTimer();
    super.dispose();
  }

  _clearSetTimeoutTimer() {
    if (_setTimeoutTimer != null) {
      _setTimeoutTimer?.cancel();
      _setTimeoutTimer = null;
    }
  }

  _countryCodeToEmoji(String countryCode) {
    final String code = countryCode.toUpperCase();
    if (code.length != 2) {
      return countryCode;
    }
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  // Function to mask the IP address
  String _maskIpAddress(String ip) {
    return ip.replaceAllMapped(RegExp(r'[0-9]'), (match) => '*');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: ValueListenableBuilder<NetworkDetectionState>(
        valueListenable: _networkDetectionState,
        builder: (_, state, __) {
          final ipInfo = state.ipInfo;
          final isLoading = state.isLoading;
          final hasConnection = ipInfo != null;
          
          return Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colorScheme.outline.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _startCheck(),
                child: Column(
                  children: [
                    // Custom Header with Flag
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colorScheme.surface.withOpacity(0.8),
                            context.colorScheme.surface.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon/Flag Container
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  context.colorScheme.primary.withOpacity(0.2),
                                  context.colorScheme.primary.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.colorScheme.primary.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: hasConnection
                                ? Text(
                                    _countryCodeToEmoji(ipInfo.countryCode),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: FontFamily.twEmoji.value,
                                    ),
                                  )
                                : Icon(
                                    Icons.public,
                                    size: 18,
                                    color: context.colorScheme.primary,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Title
                          Expanded(
                            child: Text(
                              appLocalizations.networkDetection,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content Area
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: context.colorScheme.outline.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: FadeThroughBox(
                                  child: ipInfo != null
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 12,
                                              color: context.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _showIP ? ipInfo.ip : _maskIpAddress(ipInfo.ip),
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.w600,
                                                  color: context.colorScheme.onSurface,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (isLoading)
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    context.colorScheme.primary,
                                                  ),
                                                ),
                                              )
                                            else
                                              Icon(
                                                Icons.error_outline,
                                                size: 12,
                                                color: Colors.red,
                                              ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isLoading ? "Detecting..." : "Timeout",
                                              style: context.textTheme.bodySmall?.copyWith(
                                                color: isLoading 
                                                    ? context.colorScheme.onSurfaceVariant
                                                    : Colors.red,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            if (ipInfo != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.surface.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: context.colorScheme.outline.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(2),
                                  onPressed: () {
                                    setState(() {
                                      _showIP = !_showIP;
                                    });
                                  },
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      key: ValueKey(_showIP),
                                      _showIP ? Icons.visibility : Icons.visibility_off,
                                      size: 12,
                                      color: context.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
