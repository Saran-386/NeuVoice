import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'audio_service_interface.dart';

class WebAudioService extends AudioServiceInterface {
  bool _isInitialized = false;
  bool _isRecording = false;
  double _currentVolume = 0.0;
  Timer? _mockTimer;
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
      debugPrint('🌐 Initializing web audio service...');
      _isInitialized = true;
      debugPrint('✅ Web audio service initialized');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Web audio initialization failed: $e');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> startRecording() async {
    if (!_isInitialized || _isRecording) return false;

    try {
      debugPrint('🎵 Starting web recording...');

      _isRecording = true;
      _startMockVolumeMonitoring();
      _startAudioStream();

      debugPrint('✅ Web recording started');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Web recording failed: $e');
      _isRecording = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<List<double>?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      debugPrint('🛑 Stopping web recording...');

      _mockTimer?.cancel();
      _currentVolume = 0.0;
      await _audioStreamController?.close();

      _isRecording = false;
      notifyListeners();

      // Mock audio data
      final mockData =
          List.generate(8000, (i) => sin(2 * pi * 440 * i / 16000) * 0.1);

      debugPrint('✅ Web recording stopped');
      return mockData;
    } catch (e) {
      debugPrint('❌ Web recording stop failed: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  void _startMockVolumeMonitoring() {
    _mockTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _currentVolume = Random().nextDouble() * 0.8 + 0.1;
      notifyListeners();
    });
  }

  void _startAudioStream() {
    _audioStreamController = StreamController<List<double>>.broadcast();
  }

  @override
  Future<void> cleanup() async {
    debugPrint('🧹 Cleaning up web audio service...');

    _mockTimer?.cancel();
    await _audioStreamController?.close();
    _audioStreamController = null;

    _isRecording = false;
    _isInitialized = false;
    _currentVolume = 0.0;

    debugPrint('✅ Web audio service cleaned up');
    notifyListeners();
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}
