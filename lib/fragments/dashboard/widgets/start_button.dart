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
      _apiService.addLogoutListener(_handleLogout);
      _isListenerRegistered = true;
      commonPrint.log('StartButton: Registered logout listener');
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
    // Remove the logout listener
    if (_isListenerRegistered) {
      _apiService.removeLogoutListener(_handleLogout);
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
            return SizedBox(
              width: 56 + textWidth * _controller.value,
              height: 56,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  handleSwitchStart();
                },
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      child: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: _controller,
                      ),
                    ),
                    Expanded(
                      child: ClipRect(
                        child: OverflowBox(
                          maxWidth: textWidth,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: child!,
                          ),
                        ),
                      ),
                    ),
                  ],
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
            style: Theme.of(context).textTheme.titleMedium?.toSoftBold,
          );
        },
      ),
    );
  }
}
