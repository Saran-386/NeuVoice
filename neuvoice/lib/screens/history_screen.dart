import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../widgets/transcription_display.dart';
import '../utils/responsive_utils.dart';
import '../utils/constants.dart';
import '../models/transcription.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transcription History',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          Consumer<HistoryService>(
            builder: (context, historyService, child) {
              if (historyService.transcriptions.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize:
                                ResponsiveUtils.getFontSize(context, base: 14),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: ResponsiveUtils.getScreenPadding(context),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transcriptions...',
                hintStyle: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, base: 14),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, base: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // History list
          Expanded(
            child: Consumer<HistoryService>(
              builder: (context, historyService, child) {
                if (historyService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredTranscriptions = _getFilteredTranscriptions(
                  historyService.transcriptions,
                );

                if (filteredTranscriptions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getPadding(context),
                    vertical: 8,
                  ),
                  itemCount: filteredTranscriptions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final transcription = filteredTranscriptions[index];
                    return _buildTranscriptionCard(transcription);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.history,
              size: ResponsiveUtils.isPhone(context) ? 64 : 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: ResponsiveUtils.getPadding(context)),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No transcriptions found'
                  : 'No transcriptions yet',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, base: 18),
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.getPadding(context) * 0.5),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Start recording to see your transcription history',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, base: 14),
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.getPadding(context)),
              ElevatedButton(
                onPressed: _clearSearch,
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionCard(Transcription transcription) {
    return Card(
      elevation: 2,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: ResponsiveUtils.isPhone(context) ? 160 : 200,
        ),
        padding: EdgeInsets.all(ResponsiveUtils.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.transcribe,
                  size: 16,
                  color: const Color(AppConstants.successColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTimestamp(transcription.timestamp),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, base: 12),
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (transcription.confidence > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(transcription.confidence),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(transcription.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, base: 9),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  onSelected: (value) => _handleTranscriptionAction(
                    value,
                    transcription,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context,
                                  base: 12),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Transcription text
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  transcription.text,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, base: 14),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Transcription> _getFilteredTranscriptions(
      List<Transcription> transcriptions) {
    if (_searchQuery.isEmpty) return transcriptions;

    return transcriptions.where((transcription) {
      return transcription.text.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(AppConstants.successColor);
    if (confidence >= 0.6) return const Color(AppConstants.processingColor);
    return const Color(AppConstants.errorColor);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _handleAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _handleTranscriptionAction(String action, Transcription transcription) {
    switch (action) {
      case 'delete':
        _showDeleteDialog(transcription);
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'This will delete all transcriptions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<HistoryService>(
            builder: (context, historyService, child) {
              return TextButton(
                onPressed: historyService.isLoading
                    ? null
                    : () async {
                        try {
                          await historyService.clearAll();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ History cleared'),
                                backgroundColor:
                                    Color(AppConstants.successColor),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Failed to clear history: $e'),
                                backgroundColor:
                                    const Color(AppConstants.errorColor),
                              ),
                            );
                          }
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: historyService.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Clear All'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Transcription transcription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transcription'),
        content: Text(
          'Delete "${transcription.text.length > 50 ? '${transcription.text.substring(0, 50)}...' : transcription.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context
                  .read<HistoryService>()
                  .deleteTranscription(transcription.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Transcription deleted'),
                    backgroundColor: Color(AppConstants.successColor),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
