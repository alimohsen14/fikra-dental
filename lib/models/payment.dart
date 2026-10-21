import 'package:hive_ce/hive.dart';

part 'payment.g.dart';

/// Payment methods supported by the clinic.
@HiveType(typeId: 12)
enum PaymentMethod {
  @HiveField(0)
  cash,

  @HiveField(1)
  card,

  @HiveField(2)
  bankTransfer,

  @HiveField(3)
  other,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدي (كاش)';
      case PaymentMethod.card:
        return 'بطاقة بنكية (شبكة)';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.other:
        return 'أخرى / شيك';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
      case 'visa':
      case 'mada':
        return PaymentMethod.card;
      case 'banktransfer':
      case 'transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.other;
    }
  }
}

/// A financial payment made towards a [Treatment] plan or specific session.
@HiveType(typeId: 13)
class Payment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String patientId;

  @HiveField(2)
  String treatmentId;

  /// Optional ID linking this payment to a specific [TreatmentSession].
  @HiveField(3)
  String? sessionId;

  /// The monetary amount paid.
  @HiveField(4)
  double amount;

  @HiveField(5)
  PaymentMethod paymentMethod;

  /// Date and time when the payment was transacted.
  @HiveField(6)
  DateTime paymentDate;

  /// Optional receipt or invoice reference number (e.g. "REC-1049").
  @HiveField(7)
  String? receiptNumber;

  /// Additional notes or remarks regarding the payment.
  @HiveField(8)
  String? notes;

  @HiveField(9)
  DateTime createdAt;

  Payment({
    required this.id,
    required this.patientId,
    required this.treatmentId,
    this.sessionId,
    required this.amount,
    this.paymentMethod = PaymentMethod.cash,
    required this.paymentDate,
    this.receiptNumber,
    this.notes,
    required this.createdAt,
  });

  Payment copyWith({
    String? id,
    String? patientId,
    String? treatmentId,
    String? sessionId,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? paymentDate,
    String? receiptNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      treatmentId: treatmentId ?? this.treatmentId,
      sessionId: sessionId ?? this.sessionId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, patientId: $patientId, treatmentId: $treatmentId, '
      'amount: $amount, method: ${paymentMethod.label}, date: $paymentDate)';
}
