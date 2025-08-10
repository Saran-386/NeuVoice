// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptionAdapter extends TypeAdapter<Transcription> {
  @override
  final int typeId = 0;

  @override
  Transcription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transcription(
      id: fields[0] as String,
      text: fields[1] as String,
      timestamp: fields[2] as DateTime,
      confidence: fields[3] as double,
      duration: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Transcription obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
