import 'package:hive/hive.dart';

part 'transcription.g.dart'; // This line is essential to connect with generated code

@HiveType(typeId: 0)
class Transcription extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String text;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late double confidence;

  @HiveField(4)
  late int duration;

  Transcription({
    required this.id,
    required this.text,
    required this.timestamp,
    this.confidence = 0,
    this.duration = 0,
  });
}
