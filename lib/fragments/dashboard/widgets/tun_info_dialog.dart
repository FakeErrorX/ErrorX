import 'package:errorx/common/common.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';

class TunInfoDialog extends StatelessWidget {
  const TunInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.tun,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTunInfo(context),
        ],
      ),
    );
  }

  Widget _buildTunInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stacked_line_chart,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                appLocalizations.tun,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizations.tunModeDesc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
