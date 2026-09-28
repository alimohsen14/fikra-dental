import 'package:hive_ce_flutter/hive_flutter.dart';

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

  static late Box _settingsBox;
  static late Box<Patient> _patientsBox;

  /// Direct access to the opened settings box.
  static Box get settingsBox => _settingsBox;

  /// Direct access to the opened patients box.
  static Box<Patient> get patientsBox => _patientsBox;

  /// Whether Hive has been initialized and required boxes are open.
  static bool get isInitialized =>
      Hive.isBoxOpen(settingsBoxName) && Hive.isBoxOpen(patientsBoxName);

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

    _settingsBox = await Hive.openBox(settingsBoxName);
    _patientsBox = await Hive.openBox<Patient>(patientsBoxName);
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
