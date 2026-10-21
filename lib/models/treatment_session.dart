import 'package:hive_ce/hive.dart';

part 'treatment_session.g.dart';

/// Status of a [TreatmentSession].
@HiveType(typeId: 10)
enum SessionStatus {
  @HiveField(0)
  scheduled,

  @HiveField(1)
  completed,

  @HiveField(2)
  cancelled,
}

extension SessionStatusX on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.scheduled:
        return 'مجدولة';
      case SessionStatus.completed:
        return 'مكتملة';
      case SessionStatus.cancelled:
        return 'ملغاة';
    }
  }

  bool get isCompleted => this == SessionStatus.completed;
  bool get isScheduled => this == SessionStatus.scheduled;
  bool get isCancelled => this == SessionStatus.cancelled;
}

/// A specific session within an overall [Treatment] plan.
///
/// Can optionally link to an existing [Appointment] via [appointmentId].
@HiveType(typeId: 11)
class TreatmentSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String treatmentId;

  /// Optional ID linking this session to a calendar [Appointment].
  @HiveField(2)
  String? appointmentId;

  /// 1-based sequential session number (e.g. 1, 2, 3...).
  @HiveField(3)
  int sessionNumber;

  /// Title or procedure name for this session (e.g. "حشو عصب - الجلسة الأولى").
  @HiveField(4)
  String title;

  /// Date and time scheduled for this session.
  @HiveField(5)
  DateTime date;

  @HiveField(6)
  SessionStatus status;

  /// Clinical notes, observations, or materials used.
  @HiveField(7)
  String? notes;

  /// Specific charge or fee allocated for this session (if any).
  @HiveField(8)
  double cost;

  @HiveField(9)
  DateTime createdAt;

  /// Timestamp when this session was marked as completed.
  @HiveField(10)
  DateTime? completedAt;

  TreatmentSession({
    required this.id,
    required this.treatmentId,
    this.appointmentId,
    this.sessionNumber = 1,
    required this.title,
    required this.date,
    this.status = SessionStatus.scheduled,
    this.notes,
    this.cost = 0.0,
    required this.createdAt,
    this.completedAt,
  });

  TreatmentSession copyWith({
    String? id,
    String? treatmentId,
    String? appointmentId,
    int? sessionNumber,
    String? title,
    DateTime? date,
    SessionStatus? status,
    String? notes,
    double? cost,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TreatmentSession(
      id: id ?? this.id,
      treatmentId: treatmentId ?? this.treatmentId,
      appointmentId: appointmentId ?? this.appointmentId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() =>
      'TreatmentSession(id: $id, sessionNumber: $sessionNumber, title: $title, '
      'status: ${status.label}, date: $date, cost: $cost)';
}
