import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import '../models/transcription.dart';

class HistoryService extends ChangeNotifier {
  late Box<Transcription> _box;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Transcription> get transcriptions =>
      _box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  HistoryService() {
    _init();
  }

  void _init() {
    _box = Hive.box<Transcription>('transcriptions');
    debugPrint('📚 History service initialized with ${_box.length} items');
  }

  Future<void> addTranscription({
    required String text,
    double confidence = 0.0,
    int durationMs = 0,
  }) async {
    try {
      final transcription = Transcription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        timestamp: DateTime.now(),
        confidence: confidence,
        duration: durationMs,
      );

      await _box.add(transcription);
      debugPrint(
          '💾 Saved transcription: ${text.substring(0, min(50, text.length))}...');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to save transcription: $e');
    }
  }

  Future<void> deleteTranscription(String id) async {
    try {
      final key = _box.keys.firstWhere(
        (k) => _box.get(k)?.id == id,
        orElse: () => null,
      );

      if (key != null) {
        await _box.delete(key);
        debugPrint('🗑️ Deleted transcription: $id');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to delete transcription: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      _setLoading(true);
      await _box.clear();
      debugPrint('🧹 Cleared all transcriptions');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to clear transcriptions: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
