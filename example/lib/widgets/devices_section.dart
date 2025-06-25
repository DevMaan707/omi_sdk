import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../models/app_state.dart';
import 'device_card.dart';

class DevicesSection extends StatefulWidget {
  final AppState appState;
  final Function(OmiDevice) onConnectToDevice;

  const DevicesSection({
    super.key,
    required this.appState,
    required this.onConnectToDevice,
  });

  @override
  State<DevicesSection> createState() => _DevicesSectionState();
}

class _DevicesSectionState extends State<DevicesSection>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Icon(
                  Icons.devices,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Discovered Devices',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.appState.allDevices.length}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bluetooth, size: 16),
                      const SizedBox(width: 6),
                      Text('All (${widget.appState.allDevices.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headset_mic, size: 16),
                      const SizedBox(width: 6),
                      Text('Omi (${widget.appState.omiDevices.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            height: _calculateTabViewHeight(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDevicesList(widget.appState.allDevices, false),
                _buildDevicesList(widget.appState.omiDevices, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTabViewHeight() {
    final maxDevices = math.max(
        widget.appState.allDevices.length, widget.appState.omiDevices.length);

    if (maxDevices == 0) {
      return 150;
    }
    final deviceHeight = maxDevices * 92.0;
    final padding = 48.0;
    return math.min(deviceHeight + padding, 400);
  }

  Widget _buildDevicesList(List<OmiDevice> devices, bool isOmiOnly) {
    if (devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOmiOnly ? Icons.headset_mic_outlined : Icons.bluetooth_disabled,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isOmiOnly ? 'No Omi devices found' : 'No devices discovered yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOmiOnly
                  ? 'Make sure your Omi device is nearby and in pairing mode'
                  : 'Tap "Discover Devices" to start scanning',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: devices.asMap().entries.map((entry) {
          final index = entry.key;
          final device = entry.value;
          return Padding(
            padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
            child: DeviceCard(
              device: device,
              isConnected: widget.appState.connectedDevice?.id == device.id &&
                  widget.appState.isConnected,
              isOmiDevice: widget.appState.omiDevices.contains(device),
              onConnect: () => widget.onConnectToDevice(device),
            ),
          );
        }).toList(),
      ),
    );
  }
}
