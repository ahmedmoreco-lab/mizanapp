import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/monitoring_provider.dart';
import '../utils/theme.dart';

/// Background Safety Monitor toggle. Hidden on iOS / web.
class MonitoringToggleWidget extends StatelessWidget {
  const MonitoringToggleWidget({super.key});

  Future<void> _onToggle(BuildContext context, bool desired) async {
    final provider = context.read<MonitoringProvider>();
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (desired) {
      final ok = await provider.enableMonitoring(
        persistentTitle: l.monitorNotifTitle,
        persistentBody: l.monitorNotifBody,
        channelName: l.monitorChannelName,
        channelDescription: l.monitorChannelDesc,
      );
      if (!ok) {
        final reason = provider.errorMessage == 'notification_denied'
            ? l.monitorNotifPermissionRequired
            : l.monitorCouldNotStart;
        messenger.showSnackBar(SnackBar(
          content: Text(reason),
          backgroundColor: AppTheme.statusAlert,
        ));
      }
    } else {
      await provider.disableMonitoring();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final provider = context.watch<MonitoringProvider>();

    if (!provider.isPlatformSupported) {
      return const SizedBox.shrink();
    }

    final enabled = provider.isEnabled;
    final accent = enabled ? AppTheme.statusSafe : AppTheme.statusNeutral;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_rounded, size: 26, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.monitorTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? l.monitorOnSub : l.monitorOffSub,
                      style: TextStyle(fontSize: 13, color: accent),
                    ),
                  ],
                ),
              ),
              if (provider.isStarting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Switch.adaptive(
                  value: enabled,
                  activeColor: AppTheme.statusSafe,
                  onChanged: (v) => _onToggle(context, v),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.monitorExplain,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _PermissionRow(
              ok: provider.notificationGranted,
              label: provider.notificationGranted
                  ? l.monitorPermNotifOk
                  : l.monitorPermNotifMissing,
              onTap: provider.notificationGranted
                  ? null
                  : provider.refreshPermissionStatus,
            ),
            const SizedBox(height: 6),
            _PermissionRow(
              ok: provider.ignoreBatteryOptimizations,
              label: provider.ignoreBatteryOptimizations
                  ? l.monitorPermBatteryOk
                  : l.monitorPermBatteryMissing,
              onTap: provider.ignoreBatteryOptimizations
                  ? null
                  : provider.requestIgnoreBatteryOptimizations,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final bool ok;
  final String label;
  final VoidCallback? onTap;

  const _PermissionRow({
    required this.ok,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTheme.statusSafe : AppTheme.statusAlert;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: color),
              ),
            ),
            if (!ok && onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
