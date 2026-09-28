import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/hive_service.dart';

/// Provider for managing [Account] authentication and settings with Hive CE.
///
/// Uses [HiveService.accountBox] as the single source of truth.
/// No Repository layer – direct Box access as per spec.
class AccountProvider extends ChangeNotifier {
  static const String _accountKey = 'current_account';
  static const String defaultUsername = 'fikra';
  static const String defaultPassword = 'fikra12345';

  Account? _account;
  bool _isAuthenticated = false;

  /// Current account instance.
  Account? get account => _account;

  /// Current username.
  String get username => _account?.username ?? '';

  /// Whether current session is authenticated.
  bool get isAuthenticated => _isAuthenticated;

  /// Load account from [HiveService.accountBox].
  /// Always resets to the current default credentials, overwriting any stale
  /// previously stored account (e.g. from an old install).
  Future<void> loadAccount() async {
    final box = HiveService.accountBox;
    _account = Account(
      username: defaultUsername,
      password: defaultPassword,
    );
    await box.put(_accountKey, _account!);
    // Do NOT call notifyListeners here – this is called during initState.
    // Callers that need a rebuild should use WidgetsBinding.addPostFrameCallback.
  }

  /// Login with [username] and [password].
  /// Returns true if credentials match the stored account.
  bool login(String inputUsername, String inputPassword) {
    if (_account == null) {
      final box = HiveService.accountBox;
      final stored = box.get(_accountKey) ??
          (box.isNotEmpty ? box.values.first : null);
      if (stored != null) {
        _account = stored;
      } else {
        _account = Account(
          username: defaultUsername,
          password: defaultPassword,
        );
        box.put(_accountKey, _account!);
      }
    }

    final isValid = _account != null &&
        _account!.username.trim() == inputUsername.trim() &&
        _account!.password == inputPassword;

    _isAuthenticated = isValid;
    notifyListeners();
    return isValid;
  }

  /// Change account username and persist to Hive.
  Future<void> changeUsername(String newUsername) async {
    if (_account != null) {
      _account!.username = newUsername;
    } else {
      _account = Account(username: newUsername, password: defaultPassword);
    }
    await HiveService.accountBox.put(_accountKey, _account!);
    notifyListeners();
  }

  /// Change account password and persist to Hive.
  /// Supports both `changePassword(newPassword)` and `changePassword(currentPassword, newPassword)`.
  Future<void> changePassword(String param1, [String? param2]) async {
    final newPassword = param2 ?? param1;
    if (_account != null) {
      _account!.password = newPassword;
    } else {
      _account = Account(username: defaultUsername, password: newPassword);
    }
    await HiveService.accountBox.put(_accountKey, _account!);
    notifyListeners();
  }
}
