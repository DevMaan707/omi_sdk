// omi_sdk/example/lib/widgets/professional/activity_section.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ActivitySection extends StatelessWidget {
  final List<String> messages;

  const ActivitySection({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade600, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Activity Log',
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${messages.length} entries',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceColor,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: messages.isEmpty ? _buildEmptyState() : _buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.message_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No activity yet',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'System events and messages will appear here',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isError = message.toLowerCase().contains('error') ||
            message.toLowerCase().contains('failed');
        final isSuccess = message.toLowerCase().contains('success') ||
            message.toLowerCase().contains('connected') ||
            message.toLowerCase().contains('started');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError
                ? AppTheme.errorColor.withOpacity(0.1)
                : isSuccess
                    ? AppTheme.successColor.withOpacity(0.1)
                    : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? AppTheme.errorColor.withOpacity(0.2)
                  : isSuccess
                      ? AppTheme.successColor.withOpacity(0.2)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isError
                      ? AppTheme.errorColor.withOpacity(0.2)
                      : isSuccess
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline
                      : isSuccess
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                  size: 14,
                  color: isError
                      ? AppTheme.errorColor
                      : isSuccess
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isError
                        ? AppTheme.errorColor
                        : isSuccess
                            ? AppTheme.successColor
                            : const Color(0xFF6B7280),
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
