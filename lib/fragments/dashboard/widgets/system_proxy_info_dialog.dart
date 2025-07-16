import 'package:errorx/common/common.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';

class SystemProxyInfoDialog extends StatelessWidget {
  const SystemProxyInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.systemProxy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemProxyInfo(context),
        ],
      ),
    );
  }

  Widget _buildSystemProxyInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shuffle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                appLocalizations.systemProxy,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizations.systemProxyModeDesc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
