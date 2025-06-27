import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PermissionOverlay extends StatelessWidget {
  final VoidCallback onRequestPermissions;

  const PermissionOverlay({
    super.key,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.warningColor.withOpacity(0.1) != null
                      ? LinearGradient(
                          colors: [
                            AppTheme.warningColor.withOpacity(0.2),
                            AppTheme.warningColor.withOpacity(0.1),
                          ],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  size: 64,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Permissions Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Omi Studio needs Bluetooth and location permissions to discover and connect to your devices.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRequestPermissions,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.security, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Grant Permissions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
