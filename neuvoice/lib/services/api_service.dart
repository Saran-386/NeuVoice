import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ApiService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isConnected = false;
  bool _isLoading = false;
  String? _lastError;

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  ApiService() {
    _configureDio();
    _checkConnection();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.piServerUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ));
    }
  }

  Future<void> _checkConnection() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _dio.get('/health');
      _isConnected = response.statusCode == 200;
      debugPrint(_isConnected ? '✅ Pi connected' : '❌ Pi not responding');
    } catch (e) {
      _isConnected = false;
      _lastError = 'Connection failed: $e';
      debugPrint('❌ Pi connection failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> transcribeAudio(List<List<double>> melSpectrogram) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _dio.post(
        AppConstants.transcribeEndpoint,
        data: {'mel_spectrogram': melSpectrogram},
      );

      if (response.statusCode == 200) {
        final result = response.data;
        debugPrint('✅ Transcription received: ${result['text']}');
        return result['text'] as String?;
      }

      _lastError = 'HTTP ${response.statusCode}';
      debugPrint('❌ Transcription failed: ${response.statusCode}');
      return null;
    } catch (e) {
      _lastError = 'Transcription error: $e';
      debugPrint('❌ Transcription error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Send training data to the Pi backend for continuous learning
  Future<bool> sendTrainingData(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _dio.post('/training_data', data: data);

      if (response.statusCode == 200) {
        debugPrint('✅ Training data sent successfully');
        return true;
      }

      _lastError = 'Failed to send training data: HTTP ${response.statusCode}';
      return false;
    } catch (e) {
      _lastError = 'Training data error: $e';
      debugPrint('❌ Training data error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get server status and model information from backend
  Future<Map<String, dynamic>?> getServerStatus() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _dio.get('/status');

      if (response.statusCode == 200) {
        debugPrint('✅ Server status retrieved');
        return response.data as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      _lastError = 'Status check error: $e';
      debugPrint('❌ Status check error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Manually recheck Pi connection (e.g. user triggers refresh)
  Future<void> recheckConnection() async {
    debugPrint('🔄 Rechecking Pi connection...');
    await _checkConnection();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  /// Force disconnection (for testing)
  void forceDisconnect() {
    _isConnected = false;
    _lastError = 'Manually disconnected';
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing ApiService...');
    _dio.close();
    super.dispose();
  }
}
