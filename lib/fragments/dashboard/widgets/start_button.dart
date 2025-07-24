import 'package:errorx/common/common.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/services/api_service.dart';
import 'package:errorx/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StartButton extends StatefulWidget {
  const StartButton({super.key});

  @override
  State<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isStart = false;
  final ApiService _apiService = ApiService();
  bool _isListenerRegistered = false;

  @override
  void initState() {
    super.initState();
    isStart = globalState.appState.runTime != null;
    _controller = AnimationController(
      vsync: this,
      value: isStart ? 1 : 0,
      duration: const Duration(milliseconds: 200),
    );
    
    // Register logout callback to turn off start button when logout happens
    _registerLogoutListener();
    
    // Check connection status immediately
    _checkConnectionStatus();
  }
  
  void _registerLogoutListener() {
    if (!_isListenerRegistered) {
      _apiService.addLogoutListener(
        _handleLogout,
        id: 'start_button_logout',
        priority: 10, // High priority to turn off start button quickly
      );
      _isListenerRegistered = true;
      commonPrint.log('StartButton: Registered enhanced logout listener');
    }
  }
  
  // Periodically check connection status
  void _checkConnectionStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // If we have lost WebSocket connection but StartButton is still active,
      // force logout to trigger the turn-off
      if (isStart && !_apiService.isWebSocketConnected()) {
        commonPrint.log('StartButton: WebSocket disconnected, turning off');
        _handleLogout('WebSocket connection lost');
      }
      
      // Schedule next check
      Future.delayed(const Duration(seconds: 5), _checkConnectionStatus);
    });
  }
  
  // Handler for logout or WebSocket disconnection events
  void _handleLogout(String reason) {
    commonPrint.log('StartButton: Got logout event: $reason');
    
    // Force stop regardless of current state to ensure it always turns off
    commonPrint.log('StartButton: Forcing stop');
    
    // First update global state directly
    globalState.startTime = null;
    globalState.handleStop();
    
    // Then update button state
    if (mounted) {
      setState(() {
        isStart = false;
      });
      updateController();
    }
    
    // Finally call controller method to ensure everything is stopped
    globalState.appController.updateStatus(false);
    
    commonPrint.log('StartButton: Turned off successfully');
  }

  @override
  void dispose() {
    // Remove the logout listener by ID
    if (_isListenerRegistered) {
      _apiService.removeLogoutListener('start_button_logout');
      _isListenerRegistered = false;
    }
    _controller.dispose();
    super.dispose();
  }

  handleSwitchStart() {
    if (isStart == globalState.appState.isStart) {
      // First check if WebSocket is connected before allowing start
      if (!isStart && !_apiService.isWebSocketConnected()) {
        commonPrint.log('StartButton: Cannot start, WebSocket disconnected');
        globalState.showMessage(
          title: "Connection Error",
          message: TextSpan(text: "Cannot start: connection to server lost. Please log in again."),
        );
        return;
      }
      
      isStart = !isStart;
      updateController();
      globalState.appController.updateStatus(isStart);
    }
  }

  updateController() {
    if (isStart) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, child) {
        final state = ref.watch(startButtonSelectorStateProvider);
        if (!state.isInit || !state.hasProfile) {
          return Container();
        }
        ref.listenManual(
          runTimeProvider.select((state) => state != null),
          (prev, next) {
            if (next != isStart) {
              isStart = next;
              updateController();
            }
          },
          fireImmediately: true,
        );
        final textWidth = globalState.measure
                .computeTextSize(
                  Text(
                    other.getTimeDifference(
                      DateTime.now(),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.toSoftBold,
                  ),
                )
                .width +
            16;
        return AnimatedBuilder(
          animation: _controller.view,
          builder: (_, child) {
            return Container(
              width: 56 + textWidth * _controller.value,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isStart
                      ? [
                          context.colorScheme.error,
                          context.colorScheme.error.darken(0.1),
                        ]
                      : [
                          context.colorScheme.primary,
                          context.colorScheme.primary.darken(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isStart ? context.colorScheme.error : context.colorScheme.primary)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: (isStart ? context.colorScheme.error : context.colorScheme.primary)
                        .withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    handleSwitchStart();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _controller,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      if (_controller.value > 0)
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: _controller.value,
                                child: child!,
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
          child: child,
        );
      },
      child: Consumer(
        builder: (_, ref, __) {
          final runTime = ref.watch(runTimeProvider);
          final text = other.getTimeText(runTime);
          return Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
