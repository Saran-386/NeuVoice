import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../widgets/recording_button.dart';
import '../widgets/transcription_display.dart';

class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  String _selectedLanguage = 'English';
  String _selectedModel = 'Whisper Base';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiService>().recheckConnection();
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
        child: Column(
          children: [
            // Server Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Consumer<ApiService>(
                builder: (context, apiService, child) {
                  return Card(
                    color: apiService.isConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            apiService.isConnected
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            color: apiService.isConnected
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            apiService.isConnected
                                ? 'Server Connected'
                                : 'Server Disconnected',
                            style: TextStyle(
                              color: apiService.isConnected
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content area - CRITICAL: Expanded wrapper
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Recording Button
                            const RecordingButton(),

                            const SizedBox(height: 32),

                            // Settings Section
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
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildPickerButton(
          'Language',
          'Select speech recognition language',
          _selectedLanguage,
          [
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
          Icons.language,
          (value) => setState(() => _selectedLanguage = value),
        ),
        const SizedBox(height: 12),
        _buildPickerButton(
          'AI Model',
          'Select speech recognition model',
          _selectedModel,
          [
            'Whisper Tiny',
            'Whisper Base',
            'Whisper Small',
            'Whisper Medium',
            'Custom Model',
          ],
          Icons.psychology,
          (value) => setState(() => _selectedModel = value),
        ),
      ],
    );
  }

  Widget _buildPickerButton(String title, String subtitle, String selectedValue,
      List<String> options, IconData icon, Function(String) onChanged) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: selectedValue,
          underline: const SizedBox(),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
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
                const Text(
                  'Transcription History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<HistoryService>(
                    builder: (context, historyService, child) {
                      if (historyService.transcriptions.isEmpty) {
                        return const Center(
                            child: Text('No transcriptions yet'));
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
                                  _formatTimestamp(transcription.timestamp)),
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
