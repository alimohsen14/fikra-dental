import 'package:hive_ce/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 4)
class Account extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  Account({
    required this.username,
    required this.password,
  });

  Account copyWith({
    String? username,
    String? password,
  }) {
    return Account(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  String toString() => 'Account(username: $username)';
}
