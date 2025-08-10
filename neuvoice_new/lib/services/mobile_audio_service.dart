import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_service_interface.dart';
import '../utils/constants.dart';

class MobileAudioService extends AudioServiceInterface {
  final Record _recorder = Record();
  bool _isInitialized = false;
  bool _isRecording = false;
  double _currentVolume = 0.0;
  String? _currentRecordingPath;
  Timer? _volumeTimer;
  StreamController<List<double>>? _audioStreamController;

  @override
  bool get isInitialized => _isInitialized;
  @override
  bool get isRecording => _isRecording;
  @override
  double get currentVolume => _currentVolume;
  @override
  Stream<List<double>>? get audioStream => _audioStreamController?.stream;

  @override
  Future<bool> initialize() async {
    try {
      debugPrint('🎙️ Initializing mobile audio service...');

      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        debugPrint('❌ Microphone permission denied');
        return false;
      }

      final isAvailable = await _recorder.hasPermission();
      if (!isAvailable) {
        debugPrint('❌ Audio recorder not available');
        return false;
      }

      _isInitialized = true;
      debugPrint('✅ Mobile audio service initialized');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize mobile audio service: $e');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> startRecording() async {
    if (!_isInitialized || _isRecording) return false;

    try {
      debugPrint('🎵 Starting mobile recording...');

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';

      // ✅ New API: use camelCase params for record 5.x
      await _recorder.start(
        path: _currentRecordingPath!,
        encoder: AudioEncoder.wav,
        bitRate: AppConstants.bitRate, // Optional for wav/pcm
        samplingRate: AppConstants.sampleRate,
        numChannels: AppConstants.channelCount,
      );

      _isRecording = true;
      debugPrint('✅ Mobile recording started: $_currentRecordingPath');

      _startVolumeMonitoring();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start mobile recording: $e');
      _isRecording = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<List<double>?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      debugPrint('🛑 Stopping mobile recording...');

      _volumeTimer?.cancel();
      _volumeTimer = null;
      _currentVolume = 0.0;

      await _audioStreamController?.close();
      _audioStreamController = null;

      await _recorder.stop();
      _isRecording = false;
      notifyListeners();

      if (_currentRecordingPath == null) return null;

      final audioData =
          await _convertAudioFileToDoubleArray(_currentRecordingPath!);

      try {
        await File(_currentRecordingPath!).delete();
        debugPrint('🗑️ Temporary file deleted');
      } catch (e) {
        debugPrint('⚠️ Failed to delete temp file: $e');
      }

      _currentRecordingPath = null;
      debugPrint('✅ Mobile recording stopped');
      return audioData;
    } catch (e) {
      debugPrint('❌ Failed to stop mobile recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<double>?> _convertAudioFileToDoubleArray(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      const headerSize = 44;
      if (bytes.length <= headerSize) return null;

      final audioBytes = bytes.sublist(headerSize);
      final audioSamples = <double>[];

      for (int i = 0; i < audioBytes.length - 1; i += 2) {
        final sample = (audioBytes[i + 1] << 8) | audioBytes[i];
        final signedSample = sample > 32767 ? sample - 65536 : sample;
        audioSamples.add(signedSample / 32768.0);
      }

      debugPrint('🎵 Converted ${audioSamples.length} samples');
      return audioSamples;
    } catch (e) {
      debugPrint('❌ Audio conversion failed: $e');
      return null;
    }
  }

  void _startVolumeMonitoring() {
    _volumeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        _currentVolume = amplitude.current.clamp(0.0, 1.0);
        notifyListeners();
      } catch (e) {
        // Ignore amplitude errors
      }
    });
  }

  void _startAudioStream() {
    _audioStreamController = StreamController<List<double>>.broadcast();
    // Note: Real streaming would require different approach with platform channels
  }

  @override
  Future<void> cleanup() async {
    debugPrint('🧹 Cleaning up mobile audio service...');

    try {
      _volumeTimer?.cancel();
      await _audioStreamController?.close();

      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }

      if (_currentRecordingPath != null) {
        try {
          await File(_currentRecordingPath!).delete();
        } catch (e) {
          debugPrint('⚠️ Cleanup error: $e');
        }
        _currentRecordingPath = null;
      }

      _isInitialized = false;
      _currentVolume = 0.0;

      debugPrint('✅ Mobile audio service cleaned up');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Cleanup error: $e');
    }
  }

  @override
  void dispose() {
    cleanup();
    _recorder.dispose();
    super.dispose();
  }
}
