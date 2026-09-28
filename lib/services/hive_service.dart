import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/doctor.dart';
import '../models/patient.dart';

/// Central service for Hive initialization and box access.
///
/// Keeps architecture clean and simple (similar to Fikra POS):
/// - Single responsibility: init Hive + expose boxes.
/// - Static access so it can be used anywhere without DI complexity.
/// - Must be initialized before `runApp()`.
///
/// Usage in `main.dart`:
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// await HiveService.init();
/// ```
class HiveService {
  HiveService._();

  static const String settingsBoxName = 'settings';
  static const String patientsBoxName = 'patients';
  static const String doctorsBoxName = 'doctors';
  static const String accountBoxName = 'account';

  static late Box _settingsBox;
  static late Box<Patient> _patientsBox;
  static late Box<Doctor> _doctorsBox;
  static late Box<Account> _accountBox;

  /// Direct access to the opened settings box.
  static Box get settingsBox => _settingsBox;

  /// Direct access to the opened patients box.
  static Box<Patient> get patientsBox => _patientsBox;

  /// Direct access to the opened doctors box.
  static Box<Doctor> get doctorsBox => _doctorsBox;

  /// Direct access to the opened account box.
  static Box<Account> get accountBox => _accountBox;

  /// Whether Hive has been initialized and required boxes are open.
  static bool get isInitialized =>
      Hive.isBoxOpen(settingsBoxName) &&
      Hive.isBoxOpen(patientsBoxName) &&
      Hive.isBoxOpen(doctorsBoxName) &&
      Hive.isBoxOpen(accountBoxName);

  /// Initialize Hive with `Hive.initFlutter()` and open all boxes.
  /// Call once in `main()` before `runApp()`.
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters once (safe to call multiple times check)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PatientAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GenderAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DoctorAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DoctorScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(WeekDayAdapter());
    }

    _settingsBox = await Hive.openBox(settingsBoxName);
    _patientsBox = await Hive.openBox<Patient>(patientsBoxName);
    _doctorsBox = await Hive.openBox<Doctor>(doctorsBoxName);
    _accountBox = await Hive.openBox<Account>(accountBoxName);
  }

  // ---------------------------------------------------------------------------
  // Convenience helpers for settings - keeps call sites clean without extra layers.
  // ---------------------------------------------------------------------------

  static T? get<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> put(String key, dynamic value) {
    return _settingsBox.put(key, value);
  }

  static Future<void> delete(String key) {
    return _settingsBox.delete(key);
  }

  static Future<void> clear() {
    return _settingsBox.clear();
  }
}
