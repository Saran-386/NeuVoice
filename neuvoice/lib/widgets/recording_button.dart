import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../services/audio_service_interface.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/audio_converter.dart';
import '../utils/constants.dart';
import '../utils/responsive_utils.dart';

class RecordingButton extends StatefulWidget {
  const RecordingButton({super.key});

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcriptionResult = '';
  int _recordingDuration = 0;
  double _currentVolume = 0.0;

  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _recordingTimer;
  Timer? _volumeTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _recordingTimer?.cancel();
    _volumeTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (!_isRecording) {
      await _startRecording();
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    final audioService = context.read<AudioServiceInterface>();

    try {
      if (!audioService.isInitialized) {
        if (!await audioService.initialize()) {
          _showError('Failed to initialize audio');
          return;
        }
      }

      final success = await audioService.startRecording();
      if (!success) {
        _showError('Failed to start recording');
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _transcriptionResult = '';
      });

      _pulseController.repeat(reverse: true);
      _startTimers(audioService);
    } catch (e) {
      _showError('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    final audioService = context.read<AudioServiceInterface>();
    final apiService = context.read<ApiService>();
    final historyService = context.read<HistoryService>();

    try {
      setState(() => _isProcessing = true);

      _pulseController.stop();
      _recordingTimer?.cancel();
      _volumeTimer?.cancel();

      final audioData = await audioService.stopRecording();
      setState(() => _isRecording = false);

      if (audioData == null || audioData.isEmpty) {
        _showError('No audio captured');
        return;
      }

      // Convert to mel spectrogram
      final melSpectrogram =
          await AudioConverter.convertToMelSpectrogram(audioData);

      // Send to Pi for transcription
      final transcription = await apiService.transcribeAudio(melSpectrogram);

      if (transcription != null && transcription.isNotEmpty) {
        setState(() => _transcriptionResult = transcription);

        // Save to history
        await historyService.addTranscription(
          text: transcription,
          durationMs: _recordingDuration * 1000,
          confidence: 0.95, // Mock confidence
        );

        _scaleController.forward().then((_) => _scaleController.reverse());
      } else {
        _showError('Transcription failed');
      }
    } catch (e) {
      _showError('Processing error: $e');
      setState(() => _transcriptionResult = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _startTimers(AudioServiceInterface audioService) {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingDuration++);
    });

    _volumeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _currentVolume = audioService.currentVolume);
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getButtonColor() {
    if (_isProcessing) return Colors.orange;
    if (_isRecording) return Colors.red;
    return Colors.blue;
  }

  IconData _getButtonIcon() {
    if (_isProcessing) return Icons.hourglass_empty;
    if (_isRecording) return Icons.stop;
    return Icons.mic;
  }

  String _formatDuration() {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveUtils.getButtonSize(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final isPhone = ResponsiveUtils.isPhone(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Transcription result
          if (_transcriptionResult.isNotEmpty) ...[
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: isPhone ? 120 : 160,
                minHeight: 80,
              ),
              padding:
                  EdgeInsets.all(ResponsiveUtils.getPadding(context) * 0.75),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: _transcriptionResult.startsWith('Error:')
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _transcriptionResult.startsWith('Error:')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _transcriptionResult.startsWith('Error:')
                            ? Icons.error
                            : Icons.check_circle,
                        color: _transcriptionResult.startsWith('Error:')
                            ? Colors.red
                            : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _transcriptionResult.startsWith('Error:')
                              ? 'Error'
                              : 'Transcription',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                ResponsiveUtils.getFontSize(context, base: 14),
                            color: _transcriptionResult.startsWith('Error:')
                                ? Colors.red
                                : Colors.green,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SelectableText(
                        _transcriptionResult,
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getFontSize(context, base: 16),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Audio level indicator
          if (_isRecording) ...[
            SizedBox(
              height: isPhone ? 40 : 50,
              width: double.infinity,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(isPhone ? 20 : 30, (index) {
                    final isActive =
                        index < (_currentVolume * (isPhone ? 20 : 30)).floor();
                    return Container(
                      width: isPhone ? 3 : 4,
                      height:
                          isActive ? (isPhone ? 30 : 40) : (isPhone ? 15 : 20),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.red : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],

          // Recording duration
          if (_isRecording || _isProcessing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getButtonColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isProcessing ? 'Processing...' : _formatDuration(),
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, base: 16),
                  fontWeight: FontWeight.bold,
                  color: _getButtonColor(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Main recording button
          GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: _toggleRecording,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getButtonColor(),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor().withOpacity(0.3),
                          spreadRadius:
                              _isRecording ? _pulseAnimation.value * 10 : 0,
                          blurRadius:
                              _isRecording ? _pulseAnimation.value * 20 : 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getButtonIcon(),
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Status text
          Text(
            _isProcessing
                ? 'Processing your speech...'
                : _isRecording
                    ? 'Tap to stop recording'
                    : 'Tap to start recording',
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, base: 14),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
