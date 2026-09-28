import 'package:hive_ce/hive.dart';

part 'patient.g.dart';

/// Gender values for [Patient.gender].
/// Stored as String in Patient for simplicity and spec compliance,
/// but this enum provides type-safe helpers when needed.
@HiveType(typeId: 1)
enum Gender {
  @HiveField(0)
  male,

  @HiveField(1)
  female,

  @HiveField(2)
  other,
}

extension GenderX on Gender {
  String get value => name;
  static Gender fromString(String v) {
    switch (v.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }
}

@HiveType(typeId: 0)
class Patient extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fullName;

  @HiveField(2)
  String nationalId;

  @HiveField(3)
  DateTime dateOfBirth;

  @HiveField(4)
  String gender;

  @HiveField(5)
  String phone;

  @HiveField(6)
  String? address;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  Patient({
    required this.id,
    required this.fullName,
    required this.nationalId,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    this.address,
    this.notes,
    required this.createdAt,
  });

  /// Age is calculated from [dateOfBirth], never stored.
  int get age {
    final today = DateTime.now();
    int years = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      years--;
    }
    return years;
  }

  /// Typed helper for gender.
  Gender get genderEnum => GenderX.fromString(gender);

  set genderEnum(Gender g) => gender = g.value;

  Patient copyWith({
    String? id,
    String? fullName,
    String? nationalId,
    DateTime? dateOfBirth,
    String? gender,
    Gender? genderEnum,
    String? phone,
    String? address,
    String? notes,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: genderEnum?.value ?? gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Patient(id: $id, fullName: $fullName, nationalId: $nationalId, age: $age)';
}
