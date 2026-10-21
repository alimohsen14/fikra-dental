// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreatmentAdapter extends TypeAdapter<Treatment> {
  @override
  final typeId = 9;

  @override
  Treatment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Treatment(
      id: fields[0] as String,
      patientId: fields[1] as String,
      doctorId: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String?,
      totalAmount: fields[5] == null ? 0.0 : (fields[5] as num).toDouble(),
      status: fields[6] == null
          ? TreatmentStatus.planned
          : fields[6] as TreatmentStatus,
      createdAt: fields[7] as DateTime,
      completedAt: fields[8] as DateTime?,
      sessions: (fields[9] as List?)?.cast<TreatmentSession>(),
      toothNumber: (fields[10] as num?)?.toInt(),
      plannedSessionCount: fields[11] == null ? 1 : (fields[11] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Treatment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.doctorId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.sessions)
      ..writeByte(10)
      ..write(obj.toothNumber)
      ..writeByte(11)
      ..write(obj.plannedSessionCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TreatmentStatusAdapter extends TypeAdapter<TreatmentStatus> {
  @override
  final typeId = 8;

  @override
  TreatmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TreatmentStatus.planned;
      case 1:
        return TreatmentStatus.inProgress;
      case 2:
        return TreatmentStatus.completed;
      case 3:
        return TreatmentStatus.cancelled;
      default:
        return TreatmentStatus.planned;
    }
  }

  @override
  void write(BinaryWriter writer, TreatmentStatus obj) {
    switch (obj) {
      case TreatmentStatus.planned:
        writer.writeByte(0);
      case TreatmentStatus.inProgress:
        writer.writeByte(1);
      case TreatmentStatus.completed:
        writer.writeByte(2);
      case TreatmentStatus.cancelled:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
