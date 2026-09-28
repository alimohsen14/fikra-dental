// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoctorScheduleAdapter extends TypeAdapter<DoctorSchedule> {
  @override
  final typeId = 3;

  @override
  DoctorSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoctorSchedule(
      day: fields[0] as WeekDay,
      startTime: fields[1] as String,
      endTime: fields[2] as String,
      isWorking: fields[3] == null ? true : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DoctorSchedule obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.isWorking);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DoctorAdapter extends TypeAdapter<Doctor> {
  @override
  final typeId = 2;

  @override
  Doctor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Doctor(
      id: fields[0] as String,
      fullName: fields[1] as String,
      specialty: fields[2] as String,
      phone: fields[3] as String,
      schedules: (fields[4] as List?)?.cast<DoctorSchedule>(),
      isActive: fields[5] == null ? true : fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Doctor obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.specialty)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.schedules)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeekDayAdapter extends TypeAdapter<WeekDay> {
  @override
  final typeId = 5;

  @override
  WeekDay read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WeekDay.saturday;
      case 1:
        return WeekDay.sunday;
      case 2:
        return WeekDay.monday;
      case 3:
        return WeekDay.tuesday;
      case 4:
        return WeekDay.wednesday;
      case 5:
        return WeekDay.thursday;
      case 6:
        return WeekDay.friday;
      default:
        return WeekDay.saturday;
    }
  }

  @override
  void write(BinaryWriter writer, WeekDay obj) {
    switch (obj) {
      case WeekDay.saturday:
        writer.writeByte(0);
      case WeekDay.sunday:
        writer.writeByte(1);
      case WeekDay.monday:
        writer.writeByte(2);
      case WeekDay.tuesday:
        writer.writeByte(3);
      case WeekDay.wednesday:
        writer.writeByte(4);
      case WeekDay.thursday:
        writer.writeByte(5);
      case WeekDay.friday:
        writer.writeByte(6);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
