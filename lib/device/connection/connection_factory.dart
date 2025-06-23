import '../../../core/config/sdk_config.dart';
import '../../../core/logger/sdk_logger.dart';
import '../models/device_models.dart';
import '../models/device_types.dart';
import 'device_connection.dart';
import '../adapters/omi_adapter.dart';
import '../adapters/frame_adapter.dart';

class DeviceConnectionFactory {
  final SDKConfig _config;
  final SDKLogger _logger;

  DeviceConnectionFactory({
    required SDKConfig config,
    required SDKLogger logger,
  }) : _config = config,
       _logger = logger;

  Future<DeviceConnection> createConnection(OmiDevice device) async {
    _logger.info(
      'Creating connection for device: ${device.id} (${device.type})',
    );

    switch (device.type) {
      case DeviceType.omi:
      case DeviceType.openglass:
        return OmiDeviceConnectionAdapter(
          device as OmiHardwareDevice,
          config: _config,
          logger: _logger,
        );

      case DeviceType.frame:
        return FrameDeviceConnectionAdapter(
          device as FrameDevice,
          config: _config,
          logger: _logger,
        );

      default:
        throw DeviceNotSupportedException(device.id);
    }
  }

  bool isDeviceSupported(DeviceType type) {
    return [
      DeviceType.omi,
      DeviceType.frame,
      DeviceType.openglass,
    ].contains(type);
  }

  List<DeviceType> getSupportedDeviceTypes() {
    return [DeviceType.omi, DeviceType.frame, DeviceType.openglass];
  }
}
