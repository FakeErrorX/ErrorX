import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:errorx/services/api_service.dart';
import 'package:errorx/common/common.dart';
import 'package:flutter/material.dart';

class ConnectivityManager extends StatefulWidget {
  final VoidCallback? onConnectivityChanged;
  final Widget child;

  const ConnectivityManager({
    super.key,
    this.onConnectivityChanged,
    required this.child,
  });

  @override
  State<ConnectivityManager> createState() => _ConnectivityManagerState();
}

class _ConnectivityManagerState extends State<ConnectivityManager> {
  late StreamSubscription subscription;
  ConnectivityResult? _lastConnectivityResult;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.isNotEmpty) {
        _handleConnectivityChange(results.first);
      }
    });
  }
  
  void _handleConnectivityChange(ConnectivityResult result) {
    commonPrint.log('Connectivity changed: $_lastConnectivityResult -> $result');
    
    // Debounce rapid connectivity changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      final bool isSignificantChange = _lastConnectivityResult != null && 
          _lastConnectivityResult != result;
      
      if (isSignificantChange) {
        commonPrint.log('Significant connectivity change detected, handling WebSocket reconnection');
        
        // Handle WebSocket reconnection for connectivity changes
        final apiService = ApiService();
        apiService.handleNetworkChange({
          'type': 'connectivity_changed',
          'previous': _lastConnectivityResult?.name ?? 'unknown',
          'current': result.name,
        });
      }
      
      _lastConnectivityResult = result;
      
      if (widget.onConnectivityChanged != null) {
        widget.onConnectivityChanged!();
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
