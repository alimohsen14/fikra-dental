import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/hive_service.dart';

/// Provider for managing [Account] settings with Hive CE.
///
/// Uses [HiveService.accountBox] as the single source of truth.
/// No Repository layer – direct Box access as per spec.
class AccountProvider extends ChangeNotifier {
  static const String _accountKey = 'current_account';

  Account? _account;

  /// Current account instance.
  Account? get account => _account;

  /// Current username.
  String get username => _account?.username ?? '';

  /// Load account from [HiveService.accountBox].
  /// If no account exists yet, initializes a default account.
  Future<void> loadAccount() async {
    final box = HiveService.accountBox;
    _account = box.get(_accountKey);
    if (_account == null) {
      if (box.isNotEmpty) {
        _account = box.values.first;
      } else {
        _account = Account(
          username: 'admin',
          password: 'password',
        );
        await box.put(_accountKey, _account!);
      }
    }
    notifyListeners();
  }

  /// Change account username and persist to Hive.
  Future<void> changeUsername(String newUsername) async {
    if (_account != null) {
      _account!.username = newUsername;
    } else {
      _account = Account(username: newUsername, password: '');
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
      _account = Account(username: '', password: newPassword);
    }
    await HiveService.accountBox.put(_accountKey, _account!);
    notifyListeners();
  }
}
