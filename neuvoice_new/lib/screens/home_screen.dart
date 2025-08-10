import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../widgets/recording_button.dart';
import '../widgets/server_status.dart';
import '../widgets/transcription_display.dart';
import '../widgets/picker_button.dart';
import '../utils/responsive_utils.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _transcriptionResult = '';
  double _confidence = 0.0;
  bool _isError = false;
  DateTime? _timestamp;
  String _selectedLanguage = 'English';
  String _selectedModel = 'Whisper Base';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiService>().checkConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NeuVoice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              // Server Status - Fixed height
              Padding(
                padding: EdgeInsets.all(ResponsiveUtils.getPadding(context)),
                child: const ServerStatus(),
              ),

              // Main content area - CRITICAL FIX: Expanded wrapper
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          maxWidth: ResponsiveUtils.getMaxWidth(context),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getPadding(context),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Transcription Display
                              Consumer<HistoryService>(
                                builder: (context, historyService, child) {
                                  final latestTranscription =
                                      historyService.transcriptions.isNotEmpty
                                          ? historyService.transcriptions.first
                                          : null;

                                  if (latestTranscription == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return TranscriptionDisplay(
                                    transcription: latestTranscription.text,
                                    confidence: latestTranscription.confidence,
                                    isError: latestTranscription.text
                                        .startsWith('Error:'),
                                    timestamp: latestTranscription.timestamp,
                                    onCopy: () => _copyTranscription(
                                        latestTranscription.text),
                                    onShare: () => _shareTranscription(
                                        latestTranscription.text),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Recording Button - Main widget
                              const RecordingButton(),

                              const SizedBox(height: 32),

                              // Settings section
                              _buildSettingsSection(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Language Picker
        PickerButton(
          title: 'Language',
          subtitle: 'Select speech recognition language',
          selectedValue: _selectedLanguage,
          options: const [
            'English',
            'Spanish',
            'French',
            'German',
            'Italian',
            'Portuguese',
            'Dutch',
            'Russian',
            'Chinese',
            'Japanese',
          ],
          icon: Icons.language,
          onChanged: (value) {
            setState(() => _selectedLanguage = value);
          },
        ),

        const SizedBox(height: 12),

        // Model Picker
        PickerButton(
          title: 'AI Model',
          subtitle: 'Select speech recognition model',
          selectedValue: _selectedModel,
          options: const [
            'Whisper Tiny',
            'Whisper Base',
            'Whisper Small',
            'Whisper Medium',
            'Custom Model',
          ],
          icon: Icons.psychology,
          onChanged: (value) {
            setState(() => _selectedModel = value);
          },
        ),
      ],
    );
  }

  void _copyTranscription(String text) {
    // Copy logic handled in TranscriptionDisplay widget
  }

  void _shareTranscription(String text) {
    // Share logic - implement based on your requirements
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transcription History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<HistoryService>(
                    builder: (context, historyService, child) {
                      if (historyService.transcriptions.isEmpty) {
                        return const Center(
                          child: Text('No transcriptions yet'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: historyService.transcriptions.length,
                        itemBuilder: (context, index) {
                          final transcription =
                              historyService.transcriptions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                transcription.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatTimestamp(transcription.timestamp),
                              ),
                              trailing: Text(
                                '${(transcription.confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: transcription.confidence > 0.8
                                      ? Colors.green
                                      : transcription.confidence > 0.6
                                          ? Colors.orange
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear History'),
              onTap: () {
                context.read<HistoryService>().clearAll();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _showAbout();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'NeuVoice',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.mic, size: 64),
      children: [
        const Text(
            'AI-powered speech recognition app using Raspberry Pi edge computing.'),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
