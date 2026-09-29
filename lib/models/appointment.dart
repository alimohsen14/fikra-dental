import 'package:hive_ce/hive.dart';

part 'appointment.g.dart';

/// Status of an [Appointment].
///
/// Only [pending] and [confirmed] appointments block a time slot.
/// [completed] and [cancelled] appointments do not block any slot.
@HiveType(typeId: 6)
enum AppointmentStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  confirmed,

  @HiveField(2)
  completed,

  @HiveField(3)
  cancelled,
}

extension AppointmentStatusX on AppointmentStatus {
  /// Whether this status occupies / blocks the time slot.
  bool get blocksSlot =>
      this == AppointmentStatus.pending ||
      this == AppointmentStatus.confirmed;

  /// Human-readable label.
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A dental appointment linking a [Patient] to a [Doctor] at a specific time.
///
/// [duration] is stored in minutes.
/// [status] starts as [AppointmentStatus.pending] unless overridden.
@HiveType(typeId: 7)
class Appointment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String patientId;

  @HiveField(2)
  String doctorId;

  /// The exact start date-time of the appointment (stored in UTC).
  @HiveField(3)
  DateTime dateTime;

  /// Duration of the appointment in minutes.
  @HiveField(4)
  int duration;

  @HiveField(5)
  AppointmentStatus status;

  @HiveField(6)
  DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    this.duration = 30,
    this.status = AppointmentStatus.pending,
    required this.createdAt,
  });

  /// The computed end time of this appointment.
  DateTime get endDateTime => dateTime.add(Duration(minutes: duration));

  /// Whether this appointment currently occupies a time slot.
  bool get blocksSlot => status.blocksSlot;

  /// Returns true if [other] overlaps this appointment's time window,
  /// **and** both appointments block a slot (i.e. active appointments).
  bool overlapsWith(Appointment other) {
    if (!blocksSlot || !other.blocksSlot) return false;
    return dateTime.isBefore(other.endDateTime) &&
        endDateTime.isAfter(other.dateTime);
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? dateTime,
    int? duration,
    AppointmentStatus? status,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Appointment(id: $id, patientId: $patientId, doctorId: $doctorId, '
      'dateTime: $dateTime, duration: ${duration}min, status: ${status.label})';
}
