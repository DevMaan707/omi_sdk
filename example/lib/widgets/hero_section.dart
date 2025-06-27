import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final AppState appState;
  final VoidCallback onRequestPermissions;

  const HeroSection({
    super.key,
    required this.appState,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (!appState.hasBluetoothPermissions) {
      return _buildPermissionRequired(context);
    }

    if (!appState.isInitialized) {
      return _buildInitializing(context);
    }

    if (appState.isConnected) {
      return _buildConnectedState(context);
    }

    return _buildReadyState(context);
  }

  Widget _buildPermissionRequired(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withOpacity(0.1),
            AppTheme.warningColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security,
              size: 48,
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Permissions Required',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Grant Bluetooth and location permissions to discover and connect to your Omi devices',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRequestPermissions,
              icon: const Icon(Icons.security, size: 20),
              label: const Text('Grant Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializing(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Initializing Omi Studio',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Setting up your audio workspace...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildConnectedState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.successColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connected to ${appState.connectedDevice?.name ?? 'Device'}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your Omi device is ready for audio streaming and recording',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(
                  'Audio Ready',
                  Icons.graphic_eq,
                  AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusChip(
                  'Recording Ready',
                  Icons.fiber_manual_record,
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient.scale(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.radar,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Discover',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the discover button to find nearby Omi devices and start your audio journey',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

extension LinearGradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      begin: begin,
      end: end,
    );
  }
}
