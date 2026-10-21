// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreatmentSessionAdapter extends TypeAdapter<TreatmentSession> {
  @override
  final typeId = 11;

  @override
  TreatmentSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreatmentSession(
      id: fields[0] as String,
      treatmentId: fields[1] as String,
      appointmentId: fields[2] as String?,
      sessionNumber: fields[3] == null ? 1 : (fields[3] as num).toInt(),
      title: fields[4] as String,
      date: fields[5] as DateTime,
      status: fields[6] == null
          ? SessionStatus.scheduled
          : fields[6] as SessionStatus,
      notes: fields[7] as String?,
      cost: fields[8] == null ? 0.0 : (fields[8] as num).toDouble(),
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TreatmentSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.treatmentId)
      ..writeByte(2)
      ..write(obj.appointmentId)
      ..writeByte(3)
      ..write(obj.sessionNumber)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.cost)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionStatusAdapter extends TypeAdapter<SessionStatus> {
  @override
  final typeId = 10;

  @override
  SessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionStatus.scheduled;
      case 1:
        return SessionStatus.completed;
      case 2:
        return SessionStatus.cancelled;
      default:
        return SessionStatus.scheduled;
    }
  }

  @override
  void write(BinaryWriter writer, SessionStatus obj) {
    switch (obj) {
      case SessionStatus.scheduled:
        writer.writeByte(0);
      case SessionStatus.completed:
        writer.writeByte(1);
      case SessionStatus.cancelled:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
