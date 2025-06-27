import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

class DeviceDiscoverySection extends StatefulWidget {
  final AppState appState;
  final Function(OmiDevice) onConnectToDevice;

  const DeviceDiscoverySection({
    super.key,
    required this.appState,
    required this.onConnectToDevice,
  });

  @override
  State<DeviceDiscoverySection> createState() => _DeviceDiscoverySectionState();
}

class _DeviceDiscoverySectionState extends State<DeviceDiscoverySection>
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.devices,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Discovered Devices',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.appState.allDevices.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
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
    final maxDevices =
        widget.appState.allDevices.length > widget.appState.omiDevices.length
            ? widget.appState.allDevices.length
            : widget.appState.omiDevices.length;

    if (maxDevices == 0) {
      return 200;
    }
    return (maxDevices * 100.0 + 48).clamp(200.0, 400.0);
  }

  Widget _buildDevicesList(List<OmiDevice> devices, bool isOmiOnly) {
    if (devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOmiOnly
                    ? Icons.headset_mic_outlined
                    : Icons.bluetooth_disabled,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOmiOnly ? 'No Omi devices found' : 'No devices discovered yet',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w600,
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < devices.length - 1 ? 12 : 0),
          child: _buildDeviceCard(device),
        );
      },
    );
  }

  Widget _buildDeviceCard(OmiDevice device) {
    final isConnected = widget.appState.connectedDevice?.id == device.id &&
        widget.appState.isConnected;
    final isOmiDevice = widget.appState.omiDevices.contains(device);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isConnected
            ? LinearGradient(
                colors: [
                  AppTheme.successColor.withOpacity(0.1),
                  AppTheme.accentColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isConnected ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: isConnected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? AppTheme.successColor.withOpacity(0.1)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isOmiDevice
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade200],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isOmiDevice
                      ? AppTheme.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isOmiDevice ? Icons.headset_mic : Icons.bluetooth,
              color: Colors.white,
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
                        device.name.isNotEmpty ? device.name : 'Unknown Device',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (isOmiDevice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OMI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.type.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      _getSignalIcon(device.rssi ?? 0),
                      size: 14,
                      color: _getSignalColor(device.rssi ?? 0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.rssi} dBm',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSignalColor(device.rssi ?? 0),
                        fontWeight: FontWeight.w500,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.successColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: isOmiDevice
                    ? AppTheme.primaryGradient
                    : AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isOmiDevice
                            ? AppTheme.primaryColor
                            : AppTheme.accentColor)
                        .withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onConnectToDevice(device),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Connect',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi >= -50) return Icons.signal_wifi_4_bar;
    if (rssi >= -70) return Icons.signal_wifi_4_bar;
    if (rssi >= -80) return Icons.signal_wifi_4_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return AppTheme.successColor;
    if (rssi >= -70) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
