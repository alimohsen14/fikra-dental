import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../models/treatment.dart';
import '../models/treatment_session.dart';
import '../services/hive_service.dart';

/// Provider for managing [Payment] transactions and financial records.
///
/// Architecture: UI → Provider → Hive. No Repository layer.
/// Uses [HiveService.paymentsBox] as the single source of truth.
///
/// ### Payment rules
/// - Payment is **optional**: a session can be completed without any payment.
/// - A payment is always linked to a [Treatment] (`treatmentId`).
/// - A payment may optionally be linked to a specific [TreatmentSession]
///   (`sessionId`), but this is not mandatory.
/// - The Payment screen must **never** change [Treatment.plannedSessionCount].
///
/// ### Debt readiness
/// [getUnpaidBalanceForTreatment] returns the remaining balance after all
/// payments. When a treatment is completed with a non-zero balance, the
/// remaining amount is the "debt" that can later be surfaced in a Debt module.
class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];

  // ---------------------------------------------------------------------------
  // Read-only views
  // ---------------------------------------------------------------------------

  /// All payments loaded from Hive, sorted by [Payment.paymentDate] descending.
  List<Payment> get payments => List.unmodifiable(_payments);

  /// Total count of all payment transactions.
  int get paymentCount => _payments.length;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Load all payments from [HiveService.paymentsBox] into memory.
  Future<void> loadPayments() async {
    final box = HiveService.paymentsBox;
    _payments = box.values.toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Record a new payment. Uses [Payment.id] as the Hive key.
  Future<void> addPayment(Payment payment) async {
    await HiveService.paymentsBox.put(payment.id, payment);
    await loadPayments();
  }

  /// Update an existing payment.
  Future<void> updatePayment(Payment payment) async {
    await HiveService.paymentsBox.put(payment.id, payment);
    await loadPayments();
  }

  /// Delete a payment record by id.
  Future<void> deletePayment(String id) async {
    await HiveService.paymentsBox.delete(id);
    await loadPayments();
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Find a payment by its id.
  Payment? getPaymentById(String id) {
    try {
      return _payments.firstWhere((p) => p.id == id);
    } catch (_) {
      return HiveService.paymentsBox.get(id);
    }
  }

  /// All payments made for a specific treatment plan, sorted newest first.
  List<Payment> getPaymentsByTreatment(String treatmentId) {
    return _payments
        .where((p) => p.treatmentId == treatmentId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  /// All payments made by a specific patient, sorted newest first.
  List<Payment> getPaymentsByPatient(String patientId) {
    return _payments
        .where((p) => p.patientId == patientId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  /// Payments made specifically towards a given session.
  List<Payment> getPaymentsBySession(String sessionId) {
    return _payments
        .where((p) => p.sessionId == sessionId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  // ---------------------------------------------------------------------------
  // Financial calculations
  // ---------------------------------------------------------------------------

  /// Total sum paid so far for a specific treatment.
  double getTotalPaidForTreatment(String treatmentId) {
    return getPaymentsByTreatment(treatmentId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Remaining unpaid balance for a given [treatment].
  ///
  /// Returns 0.0 when fully paid or overpaid.
  double getRemainingForTreatment(Treatment treatment) {
    final paid = getTotalPaidForTreatment(treatment.id);
    final remaining = treatment.totalAmount - paid;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Remaining unpaid balance given a treatmentId and agreed total cost.
  ///
  /// Convenience overload when you have the ID + amount but not the object.
  double getRemainingAmount(String treatmentId, double totalAmount) {
    final paid = getTotalPaidForTreatment(treatmentId);
    final remaining = totalAmount - paid;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Whether a treatment has been completely paid for.
  bool isTreatmentFullyPaid(Treatment treatment) {
    return getRemainingForTreatment(treatment) <= 0;
  }

  /// Total paid directly towards a specific session.
  double getTotalPaidForSession(String sessionId) {
    return getPaymentsBySession(sessionId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Remaining unpaid amount for a specific session.
  ///
  /// Returns 0.0 when [TreatmentSession.cost] is not set or when fully paid.
  double getRemainingForSession(TreatmentSession session) {
    if (session.cost <= 0) return 0.0;
    final paid = getTotalPaidForSession(session.id);
    final remaining = session.cost - paid;
    return remaining > 0 ? remaining : 0.0;
  }

  /// The **unpaid balance** for a treatment — the amount still owed by the
  /// patient after all recorded payments.
  ///
  /// This is the canonical value to surface when a treatment ends with an
  /// outstanding balance. It can later be linked to a Debt record without
  /// any model changes — just pass [treatmentId] and this value to the Debt
  /// constructor.
  ///
  /// Equivalent to [getRemainingForTreatment] but accepts IDs directly so
  /// callers don't need to load the full [Treatment] object.
  double getUnpaidBalanceForTreatment({
    required String treatmentId,
    required double totalAmount,
  }) {
    return getRemainingAmount(treatmentId, totalAmount);
  }

  /// Total amount paid across all treatments by a patient.
  double getTotalPaidByPatient(String patientId) {
    return getPaymentsByPatient(patientId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Remaining balance for a patient across all their treatment costs.
  double getRemainingBalanceForPatient(
    String patientId,
    double totalTreatmentsCost,
  ) {
    final totalPaid = getTotalPaidByPatient(patientId);
    final remaining = totalTreatmentsCost - totalPaid;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Whether a specific session has any payment recorded against it.
  bool sessionHasPayment(String sessionId) {
    return _payments.any((p) => p.sessionId == sessionId);
  }

  /// Total clinic revenue, optionally filtered within [startDate] and [endDate].
  double getTotalRevenue({DateTime? startDate, DateTime? endDate}) {
    var list = _payments;
    if (startDate != null) {
      list = list
          .where((p) => !p.paymentDate.isBefore(startDate))
          .toList();
    }
    if (endDate != null) {
      list = list
          .where((p) => !p.paymentDate.isAfter(endDate))
          .toList();
    }
    return list.fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Total revenue collected today.
  double getTodayRevenue() {
    final now = DateTime.now();
    return _payments.where((p) {
      final d = p.paymentDate.toLocal();
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Summary map for a treatment: `{totalAmount, totalPaid, remaining}`.
  ///
  /// Useful for building balance cards in the UI without multiple provider calls.
  ({double totalAmount, double totalPaid, double remaining}) getTreatmentSummary(
    Treatment treatment,
  ) {
    final paid = getTotalPaidForTreatment(treatment.id);
    final remaining = (treatment.totalAmount - paid).clamp(0.0, double.infinity);
    return (
      totalAmount: treatment.totalAmount,
      totalPaid: paid,
      remaining: remaining,
    );
  }
}
