import 'package:hive_ce/hive.dart';

import 'treatment_session.dart';

part 'treatment.g.dart';

/// Overall status of a [Treatment] plan.
@HiveType(typeId: 8)
enum TreatmentStatus {
  @HiveField(0)
  planned,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,

  @HiveField(3)
  cancelled,
}

extension TreatmentStatusX on TreatmentStatus {
  String get label {
    switch (this) {
      case TreatmentStatus.planned:
        return 'مخطط';
      case TreatmentStatus.inProgress:
        return 'قيد العلاج';
      case TreatmentStatus.completed:
        return 'مكتمل';
      case TreatmentStatus.cancelled:
        return 'ملغى';
    }
  }

  bool get isActive =>
      this == TreatmentStatus.planned || this == TreatmentStatus.inProgress;
  bool get isCompleted => this == TreatmentStatus.completed;
  bool get isCancelled => this == TreatmentStatus.cancelled;

  /// Whether the treatment record can still be edited (title, cost, etc.).
  bool get isEditable => isActive;
}

/// A comprehensive dental treatment plan linked to a [Patient] and a [Doctor].
///
/// Supports multiple [TreatmentSession]s, tracks financial totals, and maintains
/// full clinical history per tooth (using FDI tooth numbering system).
///
/// ### Planned session count
/// [plannedSessionCount] is the authoritative number of sessions the doctor
/// expects for this treatment. It is managed exclusively from the
/// Treatments & Teeth screen — the Payment screen must never change it.
///
/// ### Walk-in vs scheduled
/// [toothNumber] is nullable; walk-in same-day treatments may not have a
/// specific tooth selected yet.
@HiveType(typeId: 9)
class Treatment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String patientId;

  @HiveField(2)
  String doctorId;

  /// Free-text name / diagnosis (e.g. "علاج جذور وسحب عصب", "تقويم الأسنان").
  @HiveField(3)
  String title;

  /// Clinical notes, procedure details, or additional remarks.
  @HiveField(4)
  String? description;

  /// Total agreed cost / amount for the full treatment plan.
  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  TreatmentStatus status;

  @HiveField(7)
  DateTime createdAt;

  /// Timestamp when the entire treatment plan was finalised.
  @HiveField(8)
  DateTime? completedAt;

  /// All sessions belonging to this treatment plan (embedded in the Treatment).
  @HiveField(9)
  List<TreatmentSession> sessions;

  /// FDI tooth number (11–48). Null for multi-tooth or walk-in treatments
  /// where a specific tooth has not yet been assigned.
  @HiveField(10)
  int? toothNumber;

  /// The number of sessions the doctor planned for this treatment.
  ///
  /// - Set when the treatment is created.
  /// - Can be increased or decreased ONLY from the Treatments & Teeth screen.
  /// - The Payment screen must **never** change this value.
  /// - Adding a session is only allowed when [completedSessionsCount] < [plannedSessionCount].
  @HiveField(11)
  int plannedSessionCount;

  Treatment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.title,
    this.description,
    this.totalAmount = 0.0,
    this.status = TreatmentStatus.planned,
    required this.createdAt,
    this.completedAt,
    List<TreatmentSession>? sessions,
    this.toothNumber,
    this.plannedSessionCount = 1,
  }) : sessions = sessions ?? [];

  // ---------------------------------------------------------------------------
  // Session counts
  // ---------------------------------------------------------------------------

  /// Total sessions that have actually been added (scheduled + completed + cancelled).
  int get totalSessionsCount => sessions.length;

  /// Number of sessions marked [SessionStatus.completed].
  int get completedSessionsCount =>
      sessions.where((s) => s.status == SessionStatus.completed).length;

  /// Number of sessions in [SessionStatus.scheduled] state.
  int get scheduledSessionsCount =>
      sessions.where((s) => s.status == SessionStatus.scheduled).length;

  /// How many more sessions can still be added before reaching [plannedSessionCount].
  ///
  /// Only counts completed sessions against the plan; scheduled sessions that
  /// haven't been completed yet do not "use up" the quota.
  int get remainingSessionsCount =>
      (plannedSessionCount - completedSessionsCount).clamp(0, plannedSessionCount);

  /// The first scheduled (upcoming) session, sorted by date ascending.
  /// Returns null when there are no scheduled sessions.
  TreatmentSession? get currentSession {
    final scheduled = sessions
        .where((s) => s.status == SessionStatus.scheduled)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return scheduled.isEmpty ? null : scheduled.first;
  }

  /// Whether another session can be added to this treatment.
  ///
  /// Rules:
  /// - Treatment must not be completed or cancelled.
  /// - Completed sessions must be fewer than [plannedSessionCount].
  bool get canAddSession =>
      status.isActive && completedSessionsCount < plannedSessionCount;

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  /// Progress as a fraction (0.0–1.0) based on completed vs planned sessions.
  double get progressPercentage {
    if (plannedSessionCount <= 0) {
      return status == TreatmentStatus.completed ? 1.0 : 0.0;
    }
    return (completedSessionsCount / plannedSessionCount).clamp(0.0, 1.0);
  }

  /// Whether all planned sessions have been completed.
  bool get allSessionsCompleted =>
      plannedSessionCount > 0 &&
      completedSessionsCount >= plannedSessionCount;

  // ---------------------------------------------------------------------------
  // Editability
  // ---------------------------------------------------------------------------

  /// Whether the treatment record can still be edited (title, cost, tooth, etc.).
  /// Returns false once the treatment is completed or cancelled.
  bool get isEditable => status.isEditable;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  Treatment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? title,
    String? description,
    double? totalAmount,
    TreatmentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    List<TreatmentSession>? sessions,
    Object? toothNumber = _sentinel,
    int? plannedSessionCount,
  }) {
    return Treatment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      sessions: sessions ?? this.sessions.map((s) => s.copyWith()).toList(),
      toothNumber: toothNumber == _sentinel
          ? this.toothNumber
          : toothNumber as int?,
      plannedSessionCount: plannedSessionCount ?? this.plannedSessionCount,
    );
  }

  @override
  String toString() =>
      'Treatment(id: $id, patientId: $patientId, doctorId: $doctorId, '
      'title: $title, tooth: $toothNumber, totalAmount: $totalAmount, '
      'status: ${status.label}, planned: $plannedSessionCount, '
      'completed: $completedSessionsCount, sessions: ${sessions.length})';
}

/// Sentinel object used in [Treatment.copyWith] to distinguish between an
/// explicit `null` and "not provided" for [Treatment.toothNumber].
const Object _sentinel = Object();
