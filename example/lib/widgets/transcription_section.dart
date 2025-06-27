import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class TranscriptionSection extends StatelessWidget {
  final String transcriptionText;
  final String interimText;
  final bool isConnected;

  const TranscriptionSection({
    super.key,
    required this.transcriptionText,
    required this.interimText,
    required this.isConnected,
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
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.transcribe,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Live Transcription',
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
                  gradient: LinearGradient(
                    colors: isConnected
                        ? [AppTheme.successColor, AppTheme.accentColor]
                        : [AppTheme.errorColor, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected
                              ? AppTheme.successColor
                              : AppTheme.errorColor)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Transcription Display
          Container(
            width: double.infinity,
            height: 250,
            padding: const EdgeInsets.all(20),
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
            child: transcriptionText.isEmpty && interimText.isEmpty
                ? _buildEmptyState()
                : _buildTranscriptionContent(),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Copy Text',
                  Icons.copy,
                  AppTheme.primaryColor,
                  transcriptionText.isNotEmpty
                      ? () => _copyToClipboard(context, transcriptionText)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Clear',
                  Icons.clear,
                  AppTheme.errorColor,
                  transcriptionText.isNotEmpty
                      ? () => _clearTranscription()
                      : null,
                  isOutlined: true,
                ),
              ),
            ],
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
            color: AppTheme.accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_none,
            size: 32,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Start speaking to see transcription...',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your speech will appear here in real-time',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTranscriptionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Final transcription text
          if (transcriptionText.isNotEmpty)
            SelectableText(
              transcriptionText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF1F2937),
              ),
            ),

          // Interim text (in italics and lighter color)
          if (interimText.isNotEmpty) ...[
            if (transcriptionText.isNotEmpty) const SizedBox(height: 8),
            SelectableText(
              interimText,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isOutlined = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: isOutlined
            ? null
            : LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        border: isOutlined ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isOutlined ? color : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? color : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Transcription copied to clipboard'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearTranscription() {
    // This would need to be implemented in the parent widget
    // by calling a callback function
  }
}
