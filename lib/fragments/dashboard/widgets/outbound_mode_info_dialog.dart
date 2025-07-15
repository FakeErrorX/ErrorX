import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';

class OutboundModeInfoDialog extends StatelessWidget {
  const OutboundModeInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: "${appLocalizations.outboundMode} Info",
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeInfo(
              context,
              icon: Icons.rule_rounded,
              iconColor: Colors.blue.shade600,
              title: appLocalizations.rule,
              description: appLocalizations.ruleModeDesc,
            ),
            const SizedBox(height: 16),
            _buildModeInfo(
              context,
              icon: Icons.public_rounded,
              iconColor: Colors.green.shade600,
              title: appLocalizations.global,
              description: appLocalizations.globalModeDesc,
            ),
            const SizedBox(height: 16),
            _buildModeInfo(
              context,
              icon: Icons.trending_up_rounded,
              iconColor: Colors.orange.shade600,
              title: appLocalizations.direct,
              description: appLocalizations.directModeDesc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeInfo(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
