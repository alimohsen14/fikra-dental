import 'package:hive_ce_flutter/hive_flutter.dart';

/// Central service for Hive initialization and box access.
///
/// Keeps architecture clean and simple (similar to Fikra POS):
/// - Single responsibility: init Hive + expose the `settings` box.
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

  static late Box _settingsBox;

  /// Direct access to the opened settings box.
  static Box get settingsBox => _settingsBox;

  /// Whether Hive has been initialized and the settings box is open.
  static bool get isInitialized => Hive.isBoxOpen(settingsBoxName);

  /// Initialize Hive with `Hive.initFlutter()` and open the `settings` box.
  /// Call once in `main()` before `runApp()`.
  static Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(settingsBoxName);
  }

  // ---------------------------------------------------------------------------
  // Convenience helpers - keeps call sites clean without adding extra layers.
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
