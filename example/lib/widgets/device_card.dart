import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';

class DeviceCard extends StatelessWidget {
  final OmiDevice device;
  final bool isConnected;
  final bool isOmiDevice;
  final VoidCallback onConnect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.isOmiDevice,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isConnected
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: isConnected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isConnected
            ? colorScheme.primaryContainer.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Device Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOmiDevice
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOmiDevice ? Icons.headset_mic : Icons.bluetooth,
                color: isOmiDevice
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name.isNotEmpty
                              ? device.name
                              : 'Unknown Device',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isOmiDevice)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OMI',
                            style: TextStyle(
                              color: colorScheme.onSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.type.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _getSignalIcon(device.rssi ?? 0),
                        size: 14,
                        color: _getSignalColor(device.rssi ?? 0, colorScheme),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${device.rssi} dBm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getSignalColor(device.rssi ?? 0, colorScheme),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Action Button
            if (isConnected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: onConnect,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isOmiDevice ? colorScheme.primary : colorScheme.secondary,
                  foregroundColor: isOmiDevice
                      ? colorScheme.onPrimary
                      : colorScheme.onSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi >= -50) return Icons.signal_wifi_4_bar;
    if (rssi >= -70) return Icons.signal_wifi_4_bar;
    if (rssi >= -80) return Icons.signal_wifi_4_bar;
    if (rssi >= -90) return Icons.signal_wifi_0_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getSignalColor(int rssi, ColorScheme colorScheme) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}
