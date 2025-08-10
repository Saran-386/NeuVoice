import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_utils.dart';
import '../utils/constants.dart';

class TranscriptionDisplay extends StatelessWidget {
  final String transcription;
  final double confidence;
  final bool isError;
  final DateTime? timestamp;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const TranscriptionDisplay({
    super.key,
    required this.transcription,
    this.confidence = 0.0,
    this.isError = false,
    this.timestamp,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (transcription.isEmpty) return const SizedBox.shrink();

    final isPhone = ResponsiveUtils.isPhone(context);

    return Card(
      elevation: 3,
      margin: EdgeInsets.all(ResponsiveUtils.getPadding(context)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: isPhone ? 200 : 300,
          minHeight: 100, // Fixed: Add minimum height
        ),
        padding: EdgeInsets.all(ResponsiveUtils.getPadding(context)),
        child: IntrinsicHeight(
          // Fixed: Proper height calculation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Fixed: Minimize column size
            children: [
              // Header - Fixed with proper constraints
              SizedBox(
                height: 28, // Fixed: Explicit height for header
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isError ? Icons.error : Icons.check_circle,
                      color: isError
                          ? const Color(AppConstants.errorColor)
                          : const Color(AppConstants.successColor),
                      size: ResponsiveUtils.isPhone(context) ? 20 : 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isError ? 'Error' : 'Transcription',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isError
                              ? const Color(AppConstants.errorColor)
                              : const Color(AppConstants.successColor),
                          fontSize:
                              ResponsiveUtils.getFontSize(context, base: 16),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Fixed: Explicit max lines
                      ),
                    ),
                    if (!isError && confidence > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(confidence),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize:
                                ResponsiveUtils.getFontSize(context, base: 10),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Timestamp - Fixed with proper spacing
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                SizedBox(
                  // Fixed: Bounded timestamp
                  height: 16,
                  child: Text(
                    _formatTimestamp(timestamp!),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, base: 10),
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Transcription text - Fixed with Flexible instead of Expanded
              Flexible(
                // Fixed: Use Flexible for better constraint handling
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: 40, // Fixed: Minimum content height
                    maxHeight: isPhone ? 120 : 180, // Fixed: Bounded height
                  ),
                  child: SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(), // Fixed: Better scrolling
                    child: SelectableText(
                      transcription,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getFontSize(context, base: 16),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              // Actions - Fixed with proper spacing and constraints
              if (!isError) ...[
                const SizedBox(height: 12),
                SizedBox(
                  // Fixed: Bounded action buttons
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        // Fixed: Bounded button width
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.copy,
                          label: 'Copy',
                          onPressed: onCopy ?? () => _copyToClipboard(context),
                        ),
                      ),
                      if (onShare != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          // Fixed: Bounded button width
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.share,
                            label: 'Share',
                            onPressed: onShare,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      // Fixed: Consistent button sizing
      height: 36,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: ResponsiveUtils.isPhone(context) ? 16 : 18),
        label: Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, base: 12),
          ),
          maxLines: 1, // Fixed: Prevent text overflow
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getPadding(context) * 0.75,
            vertical: 8,
          ),
          minimumSize: Size.zero, // Fixed: Remove default minimum size
          tapTargetSize:
              MaterialTapTargetSize.shrinkWrap, // Fixed: Compact tap target
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(AppConstants.successColor);
    if (confidence >= 0.6) return const Color(AppConstants.processingColor);
    return const Color(AppConstants.errorColor);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transcription));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcription copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
