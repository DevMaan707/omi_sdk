import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Permissions Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Platform.isAndroid
                ? 'This app needs the following permissions to function properly:'
                : 'This app needs Bluetooth permission to function properly:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (Platform.isAndroid) ...[
            _buildPermissionItem(
                Icons.bluetooth, 'Bluetooth', 'To scan and connect to devices'),
            _buildPermissionItem(Icons.location_on, 'Location',
                'Required for Bluetooth scanning'),
          ] else ...[
            _buildPermissionItem(
                Icons.bluetooth, 'Bluetooth', 'To scan and connect to devices'),
          ],
          const SizedBox(height: 12),
          Text(
            'Please grant these permissions in your device settings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
