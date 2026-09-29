import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../services/hive_service.dart';

/// Provider for managing [Appointment] records with Hive CE.
///
/// Uses [HiveService.appointmentsBox] as the single source of truth.
/// No Repository layer – direct Box access, matching the existing pattern.
///
/// Slot-blocking rule: only [AppointmentStatus.pending] and
/// [AppointmentStatus.confirmed] appointments occupy a time slot.
class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];

  // ---------------------------------------------------------------------------
  // Read-only views
  // ---------------------------------------------------------------------------

  /// All appointments loaded from Hive, sorted by [Appointment.dateTime] descending.
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  /// All appointments that are currently blocking a time slot.
  List<Appointment> get activeAppointments =>
      _appointments.where((a) => a.blocksSlot).toList();

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Load all appointments from [HiveService.appointmentsBox] into memory.
  Future<void> loadAppointments() async {
    final box = HiveService.appointmentsBox;
    _appointments = box.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mutate
  // ---------------------------------------------------------------------------

  /// Persist a new appointment. Uses [Appointment.id] as the Hive key.
  Future<void> addAppointment(Appointment appointment) async {
    await HiveService.appointmentsBox.put(appointment.id, appointment);
    await loadAppointments();
  }

  /// Update an existing appointment (identified by [Appointment.id]).
  Future<void> updateAppointment(Appointment appointment) async {
    await HiveService.appointmentsBox.put(appointment.id, appointment);
    await loadAppointments();
  }

  // ---------------------------------------------------------------------------
  // Status transitions
  // ---------------------------------------------------------------------------

  /// Transition a [pending] appointment to [confirmed].
  Future<void> confirmAppointment(String id) async {
    final appt = getAppointmentById(id);
    if (appt == null) return;
    await updateAppointment(
      appt.copyWith(status: AppointmentStatus.confirmed),
    );
  }

  /// Transition an appointment to [cancelled].
  Future<void> cancelAppointment(String id) async {
    final appt = getAppointmentById(id);
    if (appt == null) return;
    await updateAppointment(
      appt.copyWith(status: AppointmentStatus.cancelled),
    );
  }

  /// Transition an appointment to [completed].
  Future<void> completeAppointment(String id) async {
    final appt = getAppointmentById(id);
    if (appt == null) return;
    await updateAppointment(
      appt.copyWith(status: AppointmentStatus.completed),
    );
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Find an appointment by its id. Returns null when not found.
  Appointment? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return HiveService.appointmentsBox.get(id);
    }
  }

  /// All appointments whose date portion matches [date] (ignores time).
  List<Appointment> getByDate(DateTime date) {
    return _appointments.where((a) {
      final d = a.dateTime.toLocal();
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// All appointments assigned to [doctorId], optionally filtered to a single [date].
  List<Appointment> getByDoctor(String doctorId, {DateTime? date}) {
    var result = _appointments.where((a) => a.doctorId == doctorId).toList();
    if (date != null) {
      result = result.where((a) {
        final d = a.dateTime.toLocal();
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      }).toList();
    }
    return result..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// All appointments belonging to [patientId], sorted newest first.
  List<Appointment> getByPatient(String patientId) {
    return _appointments
        .where((a) => a.patientId == patientId)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  // ---------------------------------------------------------------------------
  // Slot availability
  // ---------------------------------------------------------------------------

  /// Returns true when [slot] overlaps an existing active appointment for [doctorId].
  ///
  /// [slot] is the proposed start time.
  /// [slotDuration] is the proposed duration in minutes (default 30).
  /// [excludeId] – pass an existing appointment id to exclude it from the check
  ///   (useful when re-scheduling an appointment against itself).
  bool isSlotBooked({
    required String doctorId,
    required DateTime slot,
    int slotDuration = 30,
    String? excludeId,
  }) {
    final proposed = Appointment(
      id: '__check__',
      patientId: '',
      doctorId: doctorId,
      dateTime: slot,
      duration: slotDuration,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
    );

    return _appointments.any((a) {
      if (a.doctorId != doctorId) return false;
      if (excludeId != null && a.id == excludeId) return false;
      return proposed.overlapsWith(a);
    });
  }

  /// Returns a list of available start times for [doctor] on [date].
  ///
  /// Works by iterating the doctor's working schedule for that weekday and
  /// generating [slotDuration]-minute slots, skipping any that overlap an
  /// existing active appointment.
  ///
  /// Returns an empty list when the doctor has no schedule for that weekday
  /// or is not working that day.
  List<DateTime> getAvailableSlots({
    required Doctor doctor,
    required DateTime date,
    int slotDuration = 30,
    String? excludeAppointmentId,
  }) {
    // Map DateTime weekday (Mon=1..Sun=7) to the app's WeekDay enum index
    // by converting the DateTime.weekday to [WeekDay] using a local helper.
    final weekDayIndex = _dartWeekdayToWeekDayIndex(date.weekday);
    final schedule = doctor.schedules.cast<dynamic>().firstWhere(
          (s) => (s.day as dynamic).index == weekDayIndex,
          orElse: () => null,
        );

    if (schedule == null || !(schedule.isWorking as bool)) return [];

    final startParts = (schedule.startTime as String).split(':');
    final endParts = (schedule.endTime as String).split(':');

    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final slots = <DateTime>[];
    for (var m = startMinutes; m + slotDuration <= endMinutes;
        m += slotDuration) {
      final slotTime = DateTime(
        date.year,
        date.month,
        date.day,
        m ~/ 60,
        m % 60,
      );
      if (!isSlotBooked(
        doctorId: doctor.id,
        slot: slotTime,
        slotDuration: slotDuration,
        excludeId: excludeAppointmentId,
      )) {
        slots.add(slotTime);
      }
    }
    return slots;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Maps [DateTime.weekday] (Mon=1 … Sun=7) to the [WeekDay] enum index
  /// defined in doctor.dart (Sat=0, Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6).
  int _dartWeekdayToWeekDayIndex(int dartWeekday) {
    // DateTime.weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    // WeekDay enum    : Sat=0, Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
    const map = {
      6: 0, // Saturday
      7: 1, // Sunday
      1: 2, // Monday
      2: 3, // Tuesday
      3: 4, // Wednesday
      4: 5, // Thursday
      5: 6, // Friday
    };
    return map[dartWeekday] ?? 0;
  }
}
