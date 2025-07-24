import 'dart:async';
import 'dart:io';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/models/common.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';

final _memoryInfoStateNotifier = ValueNotifier<TrafficValue>(
  TrafficValue(value: 0),
);

class MemoryInfo extends StatefulWidget {
  const MemoryInfo({super.key});

  @override
  State<MemoryInfo> createState() => _MemoryInfoState();
}

class _MemoryInfoState extends State<MemoryInfo> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _updateMemory();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  _updateMemory() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final rss = ProcessInfo.currentRss;
      _memoryInfoStateNotifier.value = TrafficValue(
        value: clashLib != null ? rss : await clashCore.getMemory() + rss,
      );
      timer = Timer(Duration(seconds: 2), () async {
        _updateMemory();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          iconData: Icons.memory,
          label: appLocalizations.memoryInfo,
        ),
        onPressed: () {
          clashCore.requestGc();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ValueListenableBuilder(
            valueListenable: _memoryInfoStateNotifier,
            builder: (_, trafficValue, __) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.primary.withOpacity(0.1),
                      context.colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storage,
                      size: 12,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trafficValue.showValue,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trafficValue.showUnit,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// class AnimatedCounter extends StatefulWidget {
//   final double value;
//   final TextStyle? style;
//
//   const AnimatedCounter({
//     super.key,
//     required this.value,
//     this.style,
//   });
//
//   @override
//   State<AnimatedCounter> createState() => _AnimatedCounterState();
// }
//
// class _AnimatedCounterState extends State<AnimatedCounter> {
//   late double _previousValue;
//   late double _currentValue;
//
//   @override
//   void initState() {
//     super.initState();
//     _previousValue = widget.value;
//     _currentValue = widget.value;
//   }
//
//   @override
//   void didUpdateWidget(AnimatedCounter oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.value != widget.value) {
//       // if (_previousValue == _currentValue) {
//       //   _previousValue = widget.value;
//       //   _currentValue = widget.value;
//       //   return;
//       // }
//       _currentValue = widget.value;
//     }
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       _currentValue.fixed(decimals: 1),
//       style: widget.style,
//     );
//     return TweenAnimationBuilder(
//       tween: Tween(
//         begin: _previousValue,
//         end: _currentValue,
//       ),
//       onEnd: () {
//         _previousValue = _currentValue;
//       },
//       duration: Duration(seconds: 6),
//       curve: Curves.easeOut,
//       builder: (_, value, ___) {
//         return Text(
//           value.fixed(decimals: 1),
//           style: widget.style,
//         );
//       },
//     );
//   }
// }
