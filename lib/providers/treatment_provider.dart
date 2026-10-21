import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/treatment.dart';
import '../models/treatment_session.dart';
import '../providers/appointment_provider.dart';
import '../services/hive_service.dart';

/// Provider for managing [Treatment] plans and their [TreatmentSession]s.
///
/// Architecture: UI → Provider → Hive. No Repository layer.
/// Uses [HiveService.treatmentsBox] as the single source of truth.
///
/// ### Planned session count
/// [updatePlannedSessionCount] is the ONLY method that modifies
/// [Treatment.plannedSessionCount]. It must only be called from the
/// Treatments & Teeth screen — never from the Payment screen.
///
/// ### Session creation
/// [addSessionWithAppointment] is the primary entry point for adding a future
/// session. It:
/// 1. Guards against exceeding [plannedSessionCount].
/// 2. Creates a real [Appointment] via [AppointmentProvider].
/// 3. Embeds the [TreatmentSession] (with linked appointmentId) into the Treatment.
class TreatmentProvider extends ChangeNotifier {
  List<Treatment> _treatments = [];

  // ---------------------------------------------------------------------------
  // Read-only views
  // ---------------------------------------------------------------------------

  /// All treatments loaded from Hive, sorted by [Treatment.createdAt] descending.
  List<Treatment> get treatments => List.unmodifiable(_treatments);

  /// Treatments currently active (planned or in-progress).
  List<Treatment> get activeTreatments =>
      _treatments.where((t) => t.status.isActive).toList();

  /// Treatments fully completed.
  List<Treatment> get completedTreatments =>
      _treatments.where((t) => t.status.isCompleted).toList();

  /// Total count of treatments.
  int get treatmentCount => _treatments.length;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Load all treatments from [HiveService.treatmentsBox] into memory.
  Future<void> loadTreatments() async {
    final box = HiveService.treatmentsBox;
    _treatments = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Persist a new treatment plan. Uses [Treatment.id] as the Hive key.
  Future<void> addTreatment(Treatment treatment) async {
    await HiveService.treatmentsBox.put(treatment.id, treatment);
    await loadTreatments();
  }

  /// Update an existing treatment. Uses [Treatment.id] as the Hive key.
  Future<void> updateTreatment(Treatment treatment) async {
    await HiveService.treatmentsBox.put(treatment.id, treatment);
    await loadTreatments();
  }

  /// Delete a treatment plan by id.
  Future<void> deleteTreatment(String id) async {
    await HiveService.treatmentsBox.delete(id);
    await loadTreatments();
  }

  // ---------------------------------------------------------------------------
  // Planned session count (Treatments & Teeth screen ONLY)
  // ---------------------------------------------------------------------------

  /// Change the planned number of sessions for a treatment.
  ///
  /// - [newCount] must be ≥ 1.
  /// - Must not be less than the current [Treatment.completedSessionsCount]
  ///   (you cannot plan fewer sessions than already completed).
  /// - This must ONLY be called from the Treatments & Teeth screen.
  ///
  /// Returns `true` when the update was applied; `false` when validation fails.
  Future<bool> updatePlannedSessionCount(String id, int newCount) async {
    if (newCount < 1) return false;

    final treatment = getTreatmentById(id);
    if (treatment == null) return false;
    if (newCount < treatment.completedSessionsCount) return false;

    await updateTreatment(treatment.copyWith(plannedSessionCount: newCount));
    return true;
  }

  // ---------------------------------------------------------------------------
  // Status transitions
  // ---------------------------------------------------------------------------

  /// Move a planned treatment to [TreatmentStatus.inProgress].
  Future<void> startTreatment(String id) async {
    final treatment = getTreatmentById(id);
    if (treatment == null) return;
    await updateTreatment(
      treatment.copyWith(status: TreatmentStatus.inProgress),
    );
  }

  /// Mark the entire treatment plan as [TreatmentStatus.completed].
  Future<void> completeTreatment(String id) async {
    final treatment = getTreatmentById(id);
    if (treatment == null) return;
    await updateTreatment(
      treatment.copyWith(
        status: TreatmentStatus.completed,
        completedAt: DateTime.now(),
      ),
    );
  }

  /// Mark the treatment plan as [TreatmentStatus.cancelled].
  Future<void> cancelTreatment(String id) async {
    final treatment = getTreatmentById(id);
    if (treatment == null) return;
    await updateTreatment(
      treatment.copyWith(status: TreatmentStatus.cancelled),
    );
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Add a new session to an existing treatment plan, creating a real
  /// [Appointment] via [appointmentProvider].
  ///
  /// Guards:
  /// - Treatment must exist and be active.
  /// - [Treatment.canAddSession] must be true (completed < planned).
  /// - The chosen slot must not be already booked (checked inside
  ///   [AppointmentProvider.isSlotBooked]).
  ///
  /// Returns the newly created [Appointment] ID on success, or `null` if the
  /// session could not be added (e.g. slot conflict or quota exceeded).
  Future<String?> addSessionWithAppointment({
    required String treatmentId,
    required TreatmentSession session,
    required Doctor doctor,
    required AppointmentProvider appointmentProvider,
    /// Duration for the linked appointment in minutes.
    int appointmentDurationMinutes = 30,
  }) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return null;

    // Guard: quota check
    if (!treatment.canAddSession) return null;

    // Guard: slot availability
    final slotBooked = appointmentProvider.isSlotBooked(
      doctorId: doctor.id,
      slot: session.date,
      slotDuration: appointmentDurationMinutes,
    );
    if (slotBooked) return null;

    // Create the real Appointment
    final appointmentId =
        DateTime.now().microsecondsSinceEpoch.toString();
    final appointment = Appointment(
      id: appointmentId,
      patientId: treatment.patientId,
      doctorId: treatment.doctorId,
      dateTime: session.date,
      duration: appointmentDurationMinutes,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
    );
    await appointmentProvider.addAppointment(appointment);

    // Embed the session with the appointmentId linked
    final linkedSession = session.copyWith(
      treatmentId: treatmentId,
      appointmentId: appointmentId,
    );

    final updatedSessions =
        List<TreatmentSession>.from(treatment.sessions)..add(linkedSession);

    // Advance status to inProgress when first session is added
    TreatmentStatus newStatus = treatment.status;
    if (newStatus == TreatmentStatus.planned) {
      newStatus = TreatmentStatus.inProgress;
    }

    await updateTreatment(
      treatment.copyWith(
        sessions: updatedSessions,
        status: newStatus,
      ),
    );

    return appointmentId;
  }

  /// Add a session without linking it to a new Appointment.
  ///
  /// Use this for walk-in / same-day sessions where the patient arrives without
  /// a prior appointment, or when the appointment was created separately.
  ///
  /// Guards:
  /// - Treatment must exist and be active.
  /// - [Treatment.canAddSession] must be true.
  Future<void> addSession(String treatmentId, TreatmentSession session) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;
    if (!treatment.canAddSession) return;

    final updatedSessions = List<TreatmentSession>.from(treatment.sessions)
      ..add(session);

    TreatmentStatus newStatus = treatment.status;
    if (newStatus == TreatmentStatus.planned) {
      newStatus = TreatmentStatus.inProgress;
    }

    await updateTreatment(
      treatment.copyWith(
        sessions: updatedSessions,
        status: newStatus,
      ),
    );
  }

  /// Update an existing session within a treatment.
  Future<void> updateSession(
    String treatmentId,
    TreatmentSession updatedSession,
  ) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;

    final updatedSessions = treatment.sessions.map((s) {
      return s.id == updatedSession.id ? updatedSession : s;
    }).toList();

    await updateTreatment(treatment.copyWith(sessions: updatedSessions));
  }

  /// Remove a session from a treatment plan.
  Future<void> deleteSession(String treatmentId, String sessionId) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;

    final updatedSessions =
        treatment.sessions.where((s) => s.id != sessionId).toList();

    await updateTreatment(treatment.copyWith(sessions: updatedSessions));
  }

  /// Mark a specific session as [SessionStatus.completed].
  ///
  /// Automatically advances the treatment to [TreatmentStatus.completed] when:
  /// - All *planned* sessions have been completed (completed ≥ planned).
  ///
  /// Payment is optional — completing a session does NOT require full payment.
  /// Any unpaid balance remains visible via [PaymentProvider] and can
  /// optionally become a Debt entry later.
  Future<void> completeSession(String treatmentId, String sessionId) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;

    final updatedSessions = treatment.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(
          status: SessionStatus.completed,
          completedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();

    final completedCount = updatedSessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final allPlanComplete = treatment.plannedSessionCount > 0 &&
        completedCount >= treatment.plannedSessionCount;

    await updateTreatment(
      treatment.copyWith(
        sessions: updatedSessions,
        status:
            allPlanComplete ? TreatmentStatus.completed : treatment.status,
        completedAt: allPlanComplete ? DateTime.now() : treatment.completedAt,
      ),
    );
  }

  /// Mark a specific session as [SessionStatus.cancelled].
  Future<void> cancelSession(String treatmentId, String sessionId) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;

    final updatedSessions = treatment.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(status: SessionStatus.cancelled);
      }
      return s;
    }).toList();

    await updateTreatment(
      treatment.copyWith(sessions: updatedSessions),
    );
  }

  /// Link an existing session to a calendar [Appointment].
  Future<void> linkSessionToAppointment({
    required String treatmentId,
    required String sessionId,
    required String appointmentId,
  }) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;

    final updatedSessions = treatment.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(appointmentId: appointmentId);
      }
      return s;
    }).toList();

    await updateTreatment(treatment.copyWith(sessions: updatedSessions));
  }

  /// Unlink an appointment from a session (clears [TreatmentSession.appointmentId]).
  Future<void> unlinkSessionFromAppointment({
    required String treatmentId,
    required String sessionId,
  }) async {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return;

    // Use a patched copyWith that explicitly sets appointmentId to null
    final updatedSessions = treatment.sessions.map((s) {
      if (s.id == sessionId) {
        return TreatmentSession(
          id: s.id,
          treatmentId: s.treatmentId,
          appointmentId: null, // explicitly cleared
          sessionNumber: s.sessionNumber,
          title: s.title,
          date: s.date,
          status: s.status,
          notes: s.notes,
          cost: s.cost,
          createdAt: s.createdAt,
          completedAt: s.completedAt,
        );
      }
      return s;
    }).toList();

    await updateTreatment(treatment.copyWith(sessions: updatedSessions));
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Find a treatment by its ID. Falls back to direct box lookup when not in
  /// the in-memory list (e.g. before [loadTreatments] is called).
  Treatment? getTreatmentById(String id) {
    try {
      return _treatments.firstWhere((t) => t.id == id);
    } catch (_) {
      return HiveService.treatmentsBox.get(id);
    }
  }

  /// Find a specific session by treatmentId + sessionId.
  TreatmentSession? getSessionById({
    required String treatmentId,
    required String sessionId,
  }) {
    final treatment = getTreatmentById(treatmentId);
    if (treatment == null) return null;
    try {
      return treatment.sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  /// Find a session and its parent treatment by session ID alone.
  ({Treatment treatment, TreatmentSession session})? findSessionWithTreatment(
    String sessionId,
  ) {
    for (final treatment in _treatments) {
      for (final session in treatment.sessions) {
        if (session.id == sessionId) {
          return (treatment: treatment, session: session);
        }
      }
    }
    return null;
  }

  /// Find the session (and its parent treatment) linked to a specific
  /// [appointmentId]. Returns null when no session references that appointment.
  ({Treatment treatment, TreatmentSession session})? findSessionByAppointmentId(
    String appointmentId,
  ) {
    for (final treatment in _treatments) {
      for (final session in treatment.sessions) {
        if (session.appointmentId == appointmentId) {
          return (treatment: treatment, session: session);
        }
      }
    }
    return null;
  }

  /// All treatments belonging to a specific patient, sorted newest first.
  List<Treatment> getTreatmentsByPatient(String patientId) {
    return _treatments
        .where((t) => t.patientId == patientId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// All treatments managed by a specific doctor.
  List<Treatment> getTreatmentsByDoctor(String doctorId) {
    return _treatments
        .where((t) => t.doctorId == doctorId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// All treatments for a given [toothNumber] (FDI), optionally filtered by
  /// [patientId].
  ///
  /// Returns treatments where [Treatment.toothNumber] == [toothNumber].
  List<Treatment> getTreatmentsByTooth(
    int toothNumber, {
    String? patientId,
  }) {
    return _treatments.where((t) {
      if (t.toothNumber != toothNumber) return false;
      if (patientId != null && t.patientId != patientId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Full treatment history for a patient and a specific tooth.
  List<Treatment> getToothHistory({
    required String patientId,
    required int toothNumber,
  }) {
    return _treatments
        .where(
          (t) => t.patientId == patientId && t.toothNumber == toothNumber,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Find sessions across all treatments linked to a specific appointment.
  List<TreatmentSession> getSessionsForAppointment(String appointmentId) {
    final List<TreatmentSession> results = [];
    for (final treatment in _treatments) {
      for (final session in treatment.sessions) {
        if (session.appointmentId == appointmentId) {
          results.add(session);
        }
      }
    }
    return results;
  }

  /// All scheduled (upcoming) sessions across active treatments, sorted by date.
  List<({Treatment treatment, TreatmentSession session})> getUpcomingSessions({
    String? patientId,
    String? doctorId,
  }) {
    final List<({Treatment treatment, TreatmentSession session})> results = [];
    for (final treatment in activeTreatments) {
      if (patientId != null && treatment.patientId != patientId) continue;
      if (doctorId != null && treatment.doctorId != doctorId) continue;

      for (final session in treatment.sessions) {
        if (session.status == SessionStatus.scheduled) {
          results.add((treatment: treatment, session: session));
        }
      }
    }
    results.sort((a, b) => a.session.date.compareTo(b.session.date));
    return results;
  }

  /// Total agreed cost across all non-cancelled treatments for a patient.
  double getTotalTreatmentAmountForPatient(String patientId) {
    return getTreatmentsByPatient(patientId)
        .where((t) => t.status != TreatmentStatus.cancelled)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }
}
