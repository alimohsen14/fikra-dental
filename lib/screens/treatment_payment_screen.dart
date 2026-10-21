import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/payment.dart';
import '../models/patient.dart';
import '../models/treatment.dart';
import '../models/treatment_session.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/treatment_provider.dart';
import 'components/sidebar.dart';
import 'debt_screen.dart';

/// How much to pay in the current visit.
enum _PayChoice { full, partial, none }

class TreatmentPaymentScreen extends StatefulWidget {
  final String? initialAppointmentId;
  final String? initialTreatmentId;
  final String? initialSessionId;
  final String? initialPatientId;

  const TreatmentPaymentScreen({
    super.key,
    this.initialAppointmentId,
    this.initialTreatmentId,
    this.initialSessionId,
    this.initialPatientId,
  });

  @override
  State<TreatmentPaymentScreen> createState() =>
      _TreatmentPaymentScreenState();
}

class _TreatmentPaymentScreenState extends State<TreatmentPaymentScreen> {
  Patient? _selectedPatient;
  Doctor? _selectedDoctor;

  /// IDs of the tooth treatments selected to be paid together this visit.
  final Set<String> _selectedTreatmentIds = {};

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  _PayChoice _payChoice = _PayChoice.full;

  final TextEditingController _paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        context.read<PatientProvider>().loadPatients(),
        context.read<DoctorProvider>().loadDoctors(),
        context.read<AppointmentProvider>().loadAppointments(),
        context.read<TreatmentProvider>().loadTreatments(),
        context.read<PaymentProvider>().loadPayments(),
      ]);

      if (!mounted) return;

      if (widget.initialTreatmentId != null) {
        final tr = context
            .read<TreatmentProvider>()
            .getTreatmentById(widget.initialTreatmentId!);
        if (tr != null) {
          final patient =
              context.read<PatientProvider>().getById(tr.patientId);
          final doctor =
              context.read<DoctorProvider>().getDoctorById(tr.doctorId);

          setState(() {
            _selectedPatient = patient;
            _selectedDoctor = doctor;
            _selectedTreatmentIds
              ..clear()
              ..add(tr.id);
            _payChoice = _PayChoice.full;
          });
          _resetAmountToTotalDue();
        }
      } else if (widget.initialPatientId != null) {
        final patient =
            context.read<PatientProvider>().getById(widget.initialPatientId!);
        if (patient != null) {
          _selectPatient(patient);
        }
      }
    });
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  TreatmentProvider get treatmentProvider =>
      context.read<TreatmentProvider>();

  PaymentProvider get paymentProvider => context.read<PaymentProvider>();

  AppointmentProvider get appointmentProvider =>
      context.read<AppointmentProvider>();

  PatientProvider get patientProvider => context.read<PatientProvider>();

  DoctorProvider get doctorProvider => context.read<DoctorProvider>();

  // ---------------------------------------------------------------------------
  // Selection helpers
  // ---------------------------------------------------------------------------

  /// The selected tooth treatments, sorted by tooth number.
  List<Treatment> get _selectedTreatments {
    final list = _selectedTreatmentIds
        .map((id) => treatmentProvider.getTreatmentById(id))
        .whereType<Treatment>()
        .toList();
    list.sort((a, b) => (a.toothNumber ?? 0).compareTo(b.toothNumber ?? 0));
    return list;
  }

  /// The active session (first scheduled) for a treatment, if any.
  TreatmentSession? _currentSessionFor(Treatment treatment) {
    final scheduled = treatment.sessions
        .where((s) => s.status == SessionStatus.scheduled)
        .toList()
      ..sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    return scheduled.isEmpty ? null : scheduled.first;
  }

  /// Whether [session] is backed by an actual scheduled (slot-blocking)
  /// appointment. Used to decide if the session can be finished.
  bool _hasScheduledAppointment(TreatmentSession? session) {
    if (session == null || session.appointmentId == null) return false;
    final appointment =
        appointmentProvider.getAppointmentById(session.appointmentId!);
    return appointment != null && appointment.blocksSlot;
  }

  /// True when every selected tooth's current session can be finished
  /// (i.e. has an actual scheduled appointment).
  bool get _canFinishSelected {
    final treatments = _selectedTreatments;
    if (treatments.isEmpty) return false;
    return treatments
        .every((t) => _hasScheduledAppointment(_currentSessionFor(t)));
  }

  /// Remaining balance for a single tooth treatment.
  double _remainingFor(Treatment treatment) =>
      paymentProvider.getRemainingForTreatment(treatment);

  /// Total due (sum of remaining balances) for all selected teeth.
  double get _totalDue => _selectedTreatments.fold(
        0.0,
        (sum, t) => sum + _remainingFor(t),
      );

  /// The amount to be paid now based on the chosen option.
  double get _paymentAmount {
    switch (_payChoice) {
      case _PayChoice.full:
        return _totalDue;
      case _PayChoice.none:
        return 0;
      case _PayChoice.partial:
        return double.tryParse(_paymentController.text.trim()) ?? 0;
    }
  }

  /// Distribute [amount] across the selected teeth in tooth order, filling each
  /// tooth's remaining balance before moving to the next.
  Map<String, double> _distribute(double amount) {
    final result = <String, double>{};
    var left = amount;
    for (final t in _selectedTreatments) {
      final remaining = _remainingFor(t);
      final alloc = left <= 0 ? 0.0 : (remaining < left ? remaining : left);
      result[t.id] = alloc;
      left -= alloc;
    }
    return result;
  }

  void _resetAmountToTotalDue() {
    _paymentController.text = _totalDue.toStringAsFixed(2);
  }

  // ---------------------------------------------------------------------------
  // Selection actions
  // ---------------------------------------------------------------------------

  void _selectPatient(Patient? patient) {
    setState(() {
      _selectedPatient = patient;
      _selectedTreatmentIds.clear();
      _payChoice = _PayChoice.full;
      _paymentController.clear();
    });
  }

  void _selectDoctor(Doctor? doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedTreatmentIds.clear();
      _payChoice = _PayChoice.full;
      _paymentController.clear();
    });
  }

  void _toggleTreatment(String treatmentId) {
    setState(() {
      if (_selectedTreatmentIds.contains(treatmentId)) {
        _selectedTreatmentIds.remove(treatmentId);
      } else {
        _selectedTreatmentIds.add(treatmentId);
      }
      if (_payChoice == _PayChoice.full) {
        _resetAmountToTotalDue();
      }
    });
  }

  /// Active tooth treatments for the current patient/doctor that still have a
  /// scheduled session available to pay/complete.
  List<Treatment> _selectableTreatments() {
    if (_selectedPatient == null) return [];

    var treatments =
        treatmentProvider.getTreatmentsByPatient(_selectedPatient!.id);

    if (_selectedDoctor != null) {
      treatments =
          treatments.where((t) => t.doctorId == _selectedDoctor!.id).toList();
    }

    final list = treatments
        .where((t) =>
            t.status != TreatmentStatus.cancelled &&
            _currentSessionFor(t) != null)
        .toList();

    list.sort((a, b) => (a.toothNumber ?? 0).compareTo(b.toothNumber ?? 0));
    return list;
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _savePayment() async {
    if (_selectedPatient == null || _selectedTreatmentIds.isEmpty) {
      _showError('اختر سنًا واحدًا على الأقل.');
      return;
    }

    final treatments = _selectedTreatments;

    final missingSession =
        treatments.any((t) => _currentSessionFor(t) == null);
    if (missingSession) {
      _showError('بعض الأسنان المختارة لا تحتوي على جلسة نشطة.');
      return;
    }

    final amount = _paymentAmount;

    if (_payChoice == _PayChoice.partial && amount <= 0) {
      _showError('أدخل مبلغ الدفع.');
      return;
    }

    if (amount > _totalDue + 0.01) {
      _showError('المبلغ المدفوع أكبر من إجمالي المستحق.');
      return;
    }

    final allocations = _distribute(amount);
    final now = DateTime.now();
    var seq = 0;

    // Treatments finishing their final planned session still owing money.
    final debtTreatments = <Treatment>[];
    var debtAmount = 0.0;
    final patient = _selectedPatient!;

    try {
      for (final treatment in treatments) {
        final session = _currentSessionFor(treatment)!;
        final alloc = allocations[treatment.id] ?? 0;
        final isFinalPlanned = treatment.remainingSessionsCount <= 1;
        final remainingAfter = _remainingFor(treatment) - alloc;

        if (alloc > 0) {
          final payment = Payment(
            id: '${now.microsecondsSinceEpoch + seq++}',
            patientId: patient.id,
            treatmentId: treatment.id,
            sessionId: session.id,
            amount: alloc,
            paymentMethod: _paymentMethod,
            paymentDate: now,
            createdAt: now,
          );
          await paymentProvider.addPayment(payment);
        }

        await treatmentProvider.completeSession(treatment.id, session.id);

        if (session.appointmentId != null) {
          await appointmentProvider
              .completeAppointment(session.appointmentId!);
        }

        if (_payChoice == _PayChoice.none &&
            isFinalPlanned &&
            remainingAfter > 0.01) {
          debtTreatments.add(treatment);
          debtAmount += remainingAfter;
        }
      }

      if (!mounted) return;

      _showSuccess(
        amount <= 0
            ? 'تم إنهاء الجلسات دون دفع، والمبلغ المتبقي أصبح ديناً.'
            : amount >= _totalDue - 0.01
                ? 'تم حفظ الدفعة وإنهاء الجلسات بنجاح.'
                : 'تم حفظ الدفعة وإنهاء الجلسات، والمبلغ المتبقي أصبح ديناً.',
      );

      final treatmentIds = debtTreatments.map((t) => t.id).toList();

      setState(() {
        _selectedPatient = null;
        _selectedDoctor = null;
        _selectedTreatmentIds.clear();
        _payChoice = _PayChoice.full;
        _paymentController.clear();
      });

      // Final planned session finished without payment: offer debt transfer.
      if (debtTreatments.isNotEmpty) {
        final transfer = await _confirmDebtTransfer();
        if (transfer == true && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DebtScreen(
                patientId: patient.id,
                treatmentIds: treatmentIds,
                amount: debtAmount,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ أثناء حفظ الدفعة: $e');
    }
  }

  /// Confirmation shown when the final planned session is finished without
  /// payment, asking whether to transfer the balance to the Debt page.
  Future<bool?> _confirmDebtTransfer() {
    return showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('المريض لم يدفع'),
          content: const Text(
            'المريض لم يدفع، هل تريد تحويل المبلغ إلى الديون؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('لا'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0050CB),
                foregroundColor: Colors.white,
              ),
              child: const Text('نعم'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSessionDialog(Treatment treatment) async {
    if (_selectedPatient == null || _selectedDoctor == null) {
      _showError('اختر المريض والطبيب أولاً.');
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddSessionDialog(
        treatment: treatment,
        patient: _selectedPatient!,
        doctor: _selectedDoctor!,
      ),
    );

    if (!mounted || created != true) return;

    setState(() {});
    _showSuccess('تمت إضافة الجلسة وجدولة الموعد بنجاح.');
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _money(double value) => value.toStringAsFixed(2);

  String _toothLabel(Treatment treatment) => treatment.toothNumber != null
      ? 'السن ${treatment.toothNumber}'
      : treatment.title;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        body: Row(
          children: [
            const Sidebar(activeRoute: 'treatment_payment'),
            Expanded(
              child: Consumer4<
                  TreatmentProvider,
                  PaymentProvider,
                  AppointmentProvider,
                  PatientProvider>(
                builder: (
                  context,
                  treatmentProvider,
                  paymentProvider,
                  appointmentProvider,
                  patientProvider,
                  _,
                ) {
                  return Column(
                    children: [
                      _buildTopHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPageHeader(),
                              const SizedBox(height: 24),
                              _buildMainCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF).withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: Color(0xFF00C1FD),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'النظام يعمل محلياً',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'نظام فكرة دنتل',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF727687),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دفع العلاج',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131B2E),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'إدارة دفعات جلسات العلاج لعدة أسنان وإغلاق الجلسات',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF727687),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectionSection(),
            if (_selectedPatient != null) ...[
              const SizedBox(height: 22),
              _buildPaymentHistorySection(),
            ],
            const SizedBox(height: 22),
            _buildTeethSelection(),
            if (_selectedTreatmentIds.isNotEmpty) ...[
              const SizedBox(height: 22),
              _buildSessionsSection(),
              const SizedBox(height: 22),
              _buildPaymentSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          icon: Icons.person_search,
          title: 'بيانات المريض',
        ),
        const SizedBox(height: 14),
        _buildDirectSelection(),
        if (_selectedPatient != null) ...[
          const SizedBox(height: 14),
          _buildPersonContext(),
        ],
      ],
    );
  }

  Widget _buildDirectSelection() {
    final doctors = doctorProvider.activeDoctors;

    return Row(
      children: [
        Expanded(
          child: _buildPatientSearchField(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDoctor?.id,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'الطبيب',
              icon: Icons.medical_services_outlined,
            ),
            hint: const Text('اختر الطبيب'),
            items: doctors.map((doctor) {
              return DropdownMenuItem<String>(
                value: doctor.id,
                child: Text(doctor.fullName),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              _selectDoctor(doctorProvider.getDoctorById(value));
            },
          ),
        ),
      ],
    );
  }

  /// Searchable patient field: filters by full name OR national ID.
  Widget _buildPatientSearchField() {
    return Autocomplete<Patient>(
      displayStringForOption: (p) => '${p.fullName} • ${p.nationalId}',
      initialValue: TextEditingValue(
        text: _selectedPatient == null
            ? ''
            : '${_selectedPatient!.fullName} • ${_selectedPatient!.nationalId}',
      ),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        final patients = patientProvider.patients;
        if (query.isEmpty) return patients;
        return patients.where((p) =>
            p.fullName.toLowerCase().contains(query) ||
            p.nationalId.toLowerCase().contains(query));
      },
      onSelected: _selectPatient,
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _inputDecoration(
            label: 'المريض',
            icon: Icons.person_outline,
          ).copyWith(hintText: 'ابحث بالاسم أو رقم الهوية'),
          onChanged: (text) {
            if (text.trim().isEmpty && _selectedPatient != null) {
              _selectPatient(null);
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 360),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((p) {
                  return ListTile(
                    title: Text(p.fullName),
                    subtitle: Text('رقم الهوية: ${p.nationalId}'),
                    onTap: () => onSelected(p),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Previous payments made by the selected patient.
  Widget _buildPaymentHistorySection() {
    final payments =
        paymentProvider.getPaymentsByPatient(_selectedPatient!.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          icon: Icons.receipt_long_outlined,
          title: 'سجل الدفعات السابقة',
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E8FF)),
            ),
            child: const Text(
              'لا توجد دفعات سابقة لهذا المريض.',
              style: TextStyle(fontSize: 12, color: Color(0xFF727687)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E8FF)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < payments.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: i == payments.length - 1
                              ? Colors.transparent
                              : const Color(0xFFEDEFFA),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_money(payments[i].amount)} ₪',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF131B2E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                payments[i].paymentMethod.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF727687),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_formatDate(payments[i].paymentDate)} '
                          '${_formatTime(payments[i].paymentDate)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF727687),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPersonContext() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE4E8FF),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _contextItem(
              icon: Icons.person_outline,
              title: 'المريض',
              value: _selectedPatient!.fullName,
            ),
          ),
          Expanded(
            child: _contextItem(
              icon: Icons.medical_services_outlined,
              title: 'الطبيب',
              value: _selectedDoctor?.fullName ?? '-',
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0050CB),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF727687),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF131B2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeethSelection() {
    if (_selectedPatient == null) return const SizedBox.shrink();

    final treatments = _selectableTreatments();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          icon: Icons.checklist_rtl,
          title: 'اختيار الأسنان',
        ),
        const SizedBox(height: 12),
        if (treatments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFED7AA),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFC2410C),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لا يوجد علاج نشط بجلسة قابلة للدفع لهذا المريض والطبيب.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: treatments
                .map((treatment) => _buildToothTile(treatment))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildToothTile(Treatment treatment) {
    final selected = _selectedTreatmentIds.contains(treatment.id);
    final session = _currentSessionFor(treatment);
    final paid = paymentProvider.getTotalPaidForTreatment(treatment.id);
    final remaining = _remainingFor(treatment);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _toggleTreatment(treatment.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF0050CB)
                    : const Color(0xFFE4E8FF),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: selected
                      ? const Color(0xFF0050CB)
                      : const Color(0xFF727687),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_toothLabel(treatment)} • ${treatment.title}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session == null
                            ? 'لا توجد جلسة نشطة'
                            : 'الجلسة ${session.sessionNumber} • '
                                '${_formatDate(session.date)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF727687),
                        ),
                      ),
                    ],
                  ),
                ),
                _tileAmount('المدفوع', paid, const Color(0xFF059669)),
                const SizedBox(width: 18),
                _tileAmount('المتبقي', remaining, const Color(0xFF0050CB)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileAmount(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF727687),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_money(value)} ₪',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final allocations = _distribute(_paymentAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          icon: Icons.payments_outlined,
          title: 'الدفع',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _paymentTypeCard(
                title: 'دفع كامل',
                subtitle: '${_money(_totalDue)} ₪',
                icon: Icons.done_all,
                active: _payChoice == _PayChoice.full,
                onTap: () {
                  setState(() {
                    _payChoice = _PayChoice.full;
                    _resetAmountToTotalDue();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _paymentTypeCard(
                title: 'دفع جزئي',
                subtitle: 'توزيع مبلغ جزئي',
                icon: Icons.payments_outlined,
                active: _payChoice == _PayChoice.partial,
                onTap: () {
                  setState(() {
                    _payChoice = _PayChoice.partial;
                    _paymentController.text =
                        _totalDue.toStringAsFixed(2);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _paymentTypeCard(
                title: 'لا أريد الدفع الآن',
                subtitle: 'إنهاء الجلسات كدين',
                icon: Icons.schedule_outlined,
                active: _payChoice == _PayChoice.none,
                onTap: () {
                  setState(() {
                    _payChoice = _PayChoice.none;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _paymentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: _payChoice == _PayChoice.partial,
                decoration: _inputDecoration(
                  label: 'المبلغ المدفوع الآن',
                  icon: Icons.attach_money,
                  suffix: '₪',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<PaymentMethod>(
                initialValue: _paymentMethod,
                decoration: _inputDecoration(
                  label: 'طريقة الدفع',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem<PaymentMethod>(
                    value: method,
                    child: Text(method.label),
                  );
                }).toList(),
                onChanged: _payChoice == _PayChoice.none
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildDistributionPreview(allocations),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المتبقي بعد الدفع',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF727687),
                      ),
                    ),
                    Text(
                      '${_money((_totalDue - _paymentAmount).clamp(0, double.infinity))} ₪',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0050CB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // إنهاء الجلسة: only available once the current session of every
            // selected tooth has an actual scheduled appointment.
            if (_canFinishSelected)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _savePayment,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _payChoice == _PayChoice.none
                        ? 'إنهاء الجلسات'
                        : 'حفظ الدفعة وإنهاء الجلسات',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0050CB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'لا يمكن إنهاء الجلسة قبل جدولة موعد فعلي للجلسة الحالية.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A3412),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionPreview(Map<String, double> allocations) {
    final treatments = _selectedTreatments;
    if (treatments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'توزيع الدفعة على الأسنان',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 10),
          ...treatments.map((treatment) {
            final alloc = allocations[treatment.id] ?? 0;
            final remaining = _remainingFor(treatment);
            final after = (remaining - alloc).clamp(0, double.infinity);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${_toothLabel(treatment)} • ${treatment.title}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'يُدفع: ${_money(alloc)} ₪',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'يتبقى: ${_money(after.toDouble())} ₪',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0050CB),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _paymentTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF7F8FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? const Color(0xFF0050CB)
                  : const Color(0xFFE4E8FF),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF0050CB) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFF727687),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF727687),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsSection() {
    final treatments = _selectedTreatments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          icon: Icons.view_list_outlined,
          title: 'جلسات الأسنان المختارة',
        ),
        const SizedBox(height: 12),
        ...treatments.map(_buildTreatmentSessions),
      ],
    );
  }

  Widget _buildTreatmentSessions(Treatment treatment) {
    // Incomplete (scheduled/current) sessions first, completed ones last.
    final sessions = [...treatment.sessions]..sort((a, b) {
        final aDone = a.status == SessionStatus.completed ? 1 : 0;
        final bDone = b.status == SessionStatus.completed ? 1 : 0;
        if (aDone != bDone) return aDone.compareTo(bDone);
        return a.sessionNumber.compareTo(b.sessionNumber);
      });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_toothLabel(treatment)} • ${treatment.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    if (treatment.plannedSessionCount > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        'الجلسات المخطط لها المتبقية: '
                        '${treatment.remainingSessionsCount} '
                        'من ${treatment.plannedSessionCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF727687),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // إضافة جلسة: only when the plan still has room, i.e. the
              // planned count exceeds completed + scheduled sessions. To add
              // more the doctor must raise the planned count from the
              // Treatments & Teeth screen — never from here.
              if (treatment.status.isActive &&
                  treatment.plannedSessionCount >
                      treatment.completedSessionsCount +
                          treatment.scheduledSessionsCount)
                OutlinedButton.icon(
                  onPressed: () => _openAddSessionDialog(treatment),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة جلسة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0050CB),
                    side: const BorderSide(color: Color(0xFF0050CB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E8FF)),
            ),
            child: sessions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'لا توجد جلسات لهذا السن.',
                        style: TextStyle(color: Color(0xFF727687)),
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF2F3FF),
                        ),
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 64,
                        columnSpacing: 35,
                        columns: const [
                          DataColumn(label: Text('الجلسة')),
                          DataColumn(label: Text('التاريخ')),
                          DataColumn(label: Text('الوقت')),
                          DataColumn(label: Text('العلاج / الإجراء')),
                          DataColumn(label: Text('الحالة')),
                          DataColumn(label: Text('المدفوع')),
                          DataColumn(label: Text('المتبقي')),
                        ],
                        rows: sessions.map((session) {
                          final paid = paymentProvider
                              .getTotalPaidForSession(session.id);
                          final remaining = paymentProvider
                              .getRemainingForSession(session);

                          // Session whose appointment was completed before its
                          // scheduled time is flagged with a green indicator.
                          final completedEarly =
                              session.status == SessionStatus.completed &&
                                  session.completedAt != null &&
                                  session.completedAt!.isBefore(session.date);

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (completedEarly)
                                      Container(
                                        width: 4,
                                        height: 30,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    Text('${session.sessionNumber}'),
                                  ],
                                ),
                              ),
                              DataCell(Text(_formatDate(session.date))),
                              DataCell(Text(_formatTime(session.date))),
                              DataCell(Text(session.title)),
                              DataCell(_statusChip(session.status)),
                              DataCell(Text('${_money(paid)} ₪')),
                              DataCell(Text('${_money(remaining)} ₪')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(SessionStatus status) {
    Color background;
    Color foreground;

    switch (status) {
      case SessionStatus.completed:
        background = const Color(0xFFECFDF5);
        foreground = const Color(0xFF047857);
        break;
      case SessionStatus.cancelled:
        background = const Color(0xFFFEF2F2);
        foreground = const Color(0xFFB91C1C);
        break;
      case SessionStatus.scheduled:
        background = const Color(0xFFEFF6FF);
        foreground = const Color(0xFF0050CB);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 19,
            color: const Color(0xFF0050CB),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF131B2E),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: const Color(0xFF727687),
      ),
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFE4E8FF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFE4E8FF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF0050CB),
          width: 1.5,
        ),
      ),
    );
  }
}

// ============================================================
// ADD SESSION DIALOG
// ============================================================

class _AddSessionDialog extends StatefulWidget {
  final Treatment treatment;
  final Patient patient;
  final Doctor doctor;

  const _AddSessionDialog({
    required this.treatment,
    required this.patient,
    required this.doctor,
  });

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlot;
  List<DateTime> _availableSlots = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
    });
  }

  void _loadSlots() {
    final provider = context.read<AppointmentProvider>();

    final slots = provider.getAvailableSlots(
      doctor: widget.doctor,
      date: _selectedDate,
      slotDuration: 30,
    );

    setState(() {
      _availableSlots = slots;
      _selectedSlot = null;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (date == null) return;

    setState(() {
      _selectedDate = date;
    });

    _loadSlots();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirm() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر وقت الجلسة أولاً.'),
        ),
      );
      return;
    }

    final treatmentProvider = context.read<TreatmentProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();

    final nextSessionNumber = widget.treatment.totalSessionsCount + 1;

    final sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    final appointmentId = '${DateTime.now().microsecondsSinceEpoch + 1}';

    final currentSession = widget.treatment.sessions.isNotEmpty
        ? widget.treatment.sessions.last
        : null;

    final session = TreatmentSession(
      id: sessionId,
      treatmentId: widget.treatment.id,
      appointmentId: appointmentId,
      sessionNumber: nextSessionNumber,
      title: currentSession?.title ?? widget.treatment.title,
      date: _selectedSlot!,
      status: SessionStatus.scheduled,
      cost: currentSession?.cost ?? 0,
      createdAt: DateTime.now(),
    );

    final appointment = Appointment(
      id: appointmentId,
      patientId: widget.patient.id,
      doctorId: widget.doctor.id,
      dateTime: _selectedSlot!,
      duration: 30,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
    );

    try {
      await appointmentProvider.addAppointment(appointment);

      await treatmentProvider.addSession(widget.treatment.id, session);

      await treatmentProvider.linkSessionToAppointment(
        treatmentId: widget.treatment.id,
        sessionId: session.id,
        appointmentId: appointment.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء جدولة الجلسة: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: Color(0xFF0050CB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إضافة جلسة علاج جديدة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'اختر التاريخ والوقت فقط',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0050CB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'المريض: ${widget.patient.fullName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'الطبيب: ${widget.doctor.fullName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'التاريخ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE4E8FF),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: Color(0xFF0050CB),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF727687),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'الوقت المتاح',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (_availableSlots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'لا توجد أوقات متاحة لهذا الطبيب في هذا اليوم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((slot) {
                    final selected = _selectedSlot == slot;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSlot = slot;
                        });
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF0050CB)
                              : const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _formatTime(slot),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF424656),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedSlot == null ? null : _confirm,
                      icon: const Icon(
                        Icons.event_available,
                        size: 18,
                      ),
                      label: const Text('جدولة الجلسة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0050CB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD8DCE8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
