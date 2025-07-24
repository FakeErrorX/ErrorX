import 'package:errorx/common/common.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/app.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkSpeed extends StatefulWidget {
  const NetworkSpeed({super.key});

  @override
  State<NetworkSpeed> createState() => _NetworkSpeedState();
}

class _NetworkSpeedState extends State<NetworkSpeed> {
  List<Point> initPoints = const [Point(0, 0), Point(1, 0)];

  List<Point> _getPoints(List<Traffic> traffics) {
    List<Point> trafficPoints = traffics
        .toList()
        .asMap()
        .map(
          (index, e) => MapEntry(
            index,
            Point(
              (index + initPoints.length).toDouble(),
              e.speed.toDouble(),
            ),
          ),
        )
        .values
        .toList();

    return [...initPoints, ...trafficPoints];
  }

  Traffic _getLastTraffic(List<Traffic> traffics) {
    if (traffics.isEmpty) return Traffic();
    return traffics.last;
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurface.withOpacity(0.8);
    return SizedBox(
      height: getWidgetHeight(2),
      child: CommonCard(
        onPressed: () {},
        info: Info(
          label: appLocalizations.networkSpeed,
          iconData: Icons.speed_sharp,
        ),
        child: Consumer(
          builder: (_, ref, __) {
            final traffics = ref.watch(trafficsProvider).list;
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(16).copyWith(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      top: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LineChart(
                      gradient: true,
                      color: Theme.of(context).colorScheme.primary,
                      points: _getPoints(traffics),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.colorScheme.outline.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 14,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${_getLastTraffic(traffics).up}",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_downward,
                          size: 14,
                          color: context.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${_getLastTraffic(traffics).down}",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
