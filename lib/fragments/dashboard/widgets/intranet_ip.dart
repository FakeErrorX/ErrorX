import 'package:errorx/common/common.dart';
import 'package:errorx/providers/app.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntranetIP extends StatelessWidget {
  const IntranetIP({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          label: appLocalizations.intranetIP,
          iconData: Icons.devices,
        ),
        onPressed: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Consumer(
            builder: (_, ref, __) {
              final localIp = ref.watch(localIpProvider);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.secondaryContainer.withOpacity(0.6),
                      context.colorScheme.secondaryContainer.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colorScheme.secondary.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: FadeThroughBox(
                  child: localIp != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi,
                              size: 12,
                              color: context.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                localIp.isNotEmpty
                                    ? localIp
                                    : appLocalizations.noNetwork,
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
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Getting IP...",
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
