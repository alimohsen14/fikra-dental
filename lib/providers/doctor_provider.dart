import 'package:flutter/foundation.dart';

import '../models/doctor.dart';
import '../services/hive_service.dart';

/// Provider for managing [Doctor] records with Hive CE.
///
/// Uses [HiveService.doctorsBox] as the single source of truth.
/// No Repository layer – direct Box access as per spec.
class DoctorProvider extends ChangeNotifier {
  List<Doctor> _doctors = [];

  /// All doctors loaded from Hive, sorted by [Doctor.createdAt] descending.
  List<Doctor> get doctors => List.unmodifiable(_doctors);

  /// All active doctors.
  List<Doctor> get activeDoctors =>
      _doctors.where((d) => d.isActive).toList();

  /// All inactive doctors.
  List<Doctor> get inactiveDoctors =>
      _doctors.where((d) => !d.isActive).toList();

  /// Total count of doctors.
  int get doctorCount => _doctors.length;

  /// Count of active doctors.
  int get activeDoctorCount => activeDoctors.length;

  /// Load all doctors from [HiveService.doctorsBox] into memory.
  Future<void> loadDoctors() async {
    final box = HiveService.doctorsBox;
    _doctors = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Add a new doctor. Uses [Doctor.id] as Hive key.
  Future<void> addDoctor(Doctor doctor) async {
    await HiveService.doctorsBox.put(doctor.id, doctor);
    await loadDoctors();
  }

  /// Update an existing doctor.
  Future<void> updateDoctor(Doctor doctor) async {
    await HiveService.doctorsBox.put(doctor.id, doctor);
    await loadDoctors();
  }

  /// Permanently delete a doctor by id.
  Future<void> deleteDoctor(String id) async {
    await HiveService.doctorsBox.delete(id);
    await loadDoctors();
  }

  /// Toggle doctor active/inactive status.
  Future<void> toggleDoctorStatus(String id) async {
    final doctor = getDoctorById(id);
    if (doctor != null) {
      doctor.isActive = !doctor.isActive;
      await HiveService.doctorsBox.put(doctor.id, doctor);
      await loadDoctors();
    }
  }

  /// Get doctor by id from memory or Hive.
  Doctor? getDoctorById(String id) {
    try {
      return _doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return HiveService.doctorsBox.get(id);
    }
  }
}
