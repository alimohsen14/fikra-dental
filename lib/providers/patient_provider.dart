import 'package:flutter/foundation.dart';

import '../models/patient.dart';
import '../services/hive_service.dart';

/// Provider for managing [Patient] records with Hive CE.
///
/// Uses [HiveService.patientsBox] as the single source of truth.
/// No Repository layer – direct Box access as per spec.
///
/// Handles:
/// - load patients
/// - add
/// - update
/// - permanent delete
/// - search by name or nationalId
class PatientProvider extends ChangeNotifier {
  List<Patient> _patients = [];
  String _searchQuery = '';

  /// All patients loaded from Hive, sorted by [Patient.createdAt] descending.
  List<Patient> get patients => List.unmodifiable(_patients);

  /// Current search query (raw, not trimmed/lowered).
  String get searchQuery => _searchQuery;

  /// Filtered view based on [_searchQuery].
  /// Searches case-insensitively in [Patient.fullName] and [Patient.nationalId].
  List<Patient> get filteredPatients {
    if (_searchQuery.trim().isEmpty) return patients;
    return search(_searchQuery);
  }

  /// Load all patients from [HiveService.patientsBox] into memory.
  /// Call after [HiveService.init] or on provider creation.
  Future<void> loadPatients() async {
    final box = HiveService.patientsBox;
    _patients = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Alias for [loadPatients] – kept for API flexibility.
  Future<void> fetchPatients() => loadPatients();

  /// Add a new patient. Uses [Patient.id] as Hive key for stable updates/deletes.
  Future<void> addPatient(Patient patient) async {
    await HiveService.patientsBox.put(patient.id, patient);
    await loadPatients();
  }

  /// Update an existing patient. Same as add (put by id).
  Future<void> updatePatient(Patient patient) async {
    await HiveService.patientsBox.put(patient.id, patient);
    await loadPatients();
  }

  /// Permanently delete a patient by id from Hive.
  Future<void> deletePatient(String id) async {
    await HiveService.patientsBox.delete(id);
    await loadPatients();
  }

  /// Permanent delete alias that accepts a [Patient] instance.
  Future<void> deletePatientByModel(Patient patient) =>
      deletePatient(patient.id);

  /// Search patients by [query] in [Patient.fullName] or [Patient.nationalId].
  /// Case-insensitive, trims input. Returns unmodifiable filtered list.
  /// Does NOT mutate [_searchQuery] – use [setSearchQuery] for reactive filtering.
  List<Patient> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return patients;
    return _patients
        .where((p) =>
            p.fullName.toLowerCase().contains(q) ||
            p.nationalId.toLowerCase().contains(q))
        .toList();
  }

  /// Reactive search: set query and notify listeners.
  /// UI can listen to [filteredPatients] after calling this.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear current search query.
  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  int get count => _patients.length;

  Patient? getById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      // Fallback to box direct lookup if not in memory yet
      return HiveService.patientsBox.get(id);
    }
  }
}
