// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SOSModelAdapter extends TypeAdapter<SOSModel> {
  @override
  final int typeId = 0;

  @override
  SOSModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SOSModel(
      id: fields[0] as String,
      issue: fields[1] as String,
      lat: fields[2] as double?,
      lng: fields[3] as double?,
      imagePath: fields[4] as String,
      timestamp: fields[5] as String,
      encryptedPayload: fields[7] as String,
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SOSModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.issue)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lng)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.isSynced)
      ..writeByte(7)
      ..write(obj.encryptedPayload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SOSModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
