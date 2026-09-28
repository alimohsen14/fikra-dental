import 'package:hive_ce/hive.dart';

part 'doctor.g.dart';

@HiveType(typeId: 5)
enum WeekDay {
  @HiveField(0)
  saturday,

  @HiveField(1)
  sunday,

  @HiveField(2)
  monday,

  @HiveField(3)
  tuesday,

  @HiveField(4)
  wednesday,

  @HiveField(5)
  thursday,

  @HiveField(6)
  friday,
}

@HiveType(typeId: 3)
class DoctorSchedule extends HiveObject {
  @HiveField(0)
  WeekDay day;

  @HiveField(1)
  String startTime;

  @HiveField(2)
  String endTime;

  @HiveField(3)
  bool isWorking;

  DoctorSchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.isWorking = true,
  });

  DoctorSchedule copyWith({
    WeekDay? day,
    String? startTime,
    String? endTime,
    bool? isWorking,
  }) {
    return DoctorSchedule(
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isWorking: isWorking ?? this.isWorking,
    );
  }

  static List<DoctorSchedule> defaultWeeklySchedule({
    String defaultStartTime = '09:00',
    String defaultEndTime = '17:00',
  }) {
    return WeekDay.values
        .map((d) => DoctorSchedule(
              day: d,
              startTime: defaultStartTime,
              endTime: defaultEndTime,
            ))
        .toList();
  }

  @override
  String toString() =>
      'DoctorSchedule(day: $day, startTime: $startTime, endTime: $endTime, isWorking: $isWorking)';
}

@HiveType(typeId: 2)
class Doctor extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fullName;

  @HiveField(2)
  String specialty;

  @HiveField(3)
  String phone;

  @HiveField(4)
  List<DoctorSchedule> schedules;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime createdAt;

  Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.phone,
    List<DoctorSchedule>? schedules,
    this.isActive = true,
    required this.createdAt,
  }) : schedules = schedules ?? [];

  Doctor copyWith({
    String? id,
    String? fullName,
    String? specialty,
    String? phone,
    List<DoctorSchedule>? schedules,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      schedules: schedules ?? this.schedules.map((s) => s.copyWith()).toList(),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Doctor(id: $id, fullName: $fullName, specialty: $specialty, isActive: $isActive)';
}
