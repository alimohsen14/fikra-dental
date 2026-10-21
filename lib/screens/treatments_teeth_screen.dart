import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/treatment.dart';
import '../models/treatment_session.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/treatment_provider.dart';
import 'components/sidebar.dart';
import 'treatment_payment_screen.dart';

class _ToothTreatmentData {
  String title;
  String description;
  String cost;
  String sessions;

  _ToothTreatmentData({
    this.title = '',
    this.description = '',
    this.cost = '',
    this.sessions = '1',
  });
}

class TreatmentsTeethScreen extends StatefulWidget {
  final String? initialAppointmentId;
  final String? initialPatientId;
  final String? initialDoctorId;
  final int? initialToothNumber;

  const TreatmentsTeethScreen({
    super.key,
    this.initialAppointmentId,
    this.initialPatientId,
    this.initialDoctorId,
    this.initialToothNumber,
  });

  @override
  State<TreatmentsTeethScreen> createState() => _TreatmentsTeethScreenState();
}

class _TreatmentsTeethScreenState extends State<TreatmentsTeethScreen> {
  static const _bg = Color(0xFFFAF8FF);
  static const _primary = Color(0xFF0567F9);
  static const _text = Color(0xFF30364B);
  static const _muted = Color(0xFF777D91);
  static const _border = Color(0xFFE6E8F4);

  bool _fromAppointment = true;

  String? _selectedAppointmentId;
  String? _selectedPatientId;
  String? _selectedDoctorId;

  final Set<int> _selectedTeeth = {};
  int? _currentEditingTooth;
  final Map<int, _ToothTreatmentData> _toothData = {};

  final _treatmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _sessionsController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();

    if (widget.initialAppointmentId != null) {
      _fromAppointment = true;
      _selectedAppointmentId = widget.initialAppointmentId;
    } else if (widget.initialPatientId != null) {
      _fromAppointment = false;
      _selectedPatientId = widget.initialPatientId;
      _selectedDoctorId = widget.initialDoctorId;
      if (widget.initialToothNumber != null) {
        _selectedTeeth.add(widget.initialToothNumber!);
        _currentEditingTooth = widget.initialToothNumber;
        _toothData[widget.initialToothNumber!] = _ToothTreatmentData();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
      context.read<DoctorProvider>().loadDoctors();
      context.read<AppointmentProvider>().loadAppointments();
      context.read<TreatmentProvider>().loadTreatments();
    });
  }

  @override
  void dispose() {
    _treatmentController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  void _saveCurrentToothForm() {
    if (_currentEditingTooth != null) {
      final data = _toothData.putIfAbsent(
        _currentEditingTooth!,
        () => _ToothTreatmentData(),
      );
      data.title = _treatmentController.text;
      data.description = _descriptionController.text;
      data.cost = _costController.text;
      data.sessions = _sessionsController.text;
    }
  }

  void _loadToothForm(int tooth) {
    _currentEditingTooth = tooth;
    final data = _toothData.putIfAbsent(
      tooth,
      () => _ToothTreatmentData(),
    );
    _treatmentController.text = data.title;
    _descriptionController.text = data.description;
    _costController.text = data.cost;
    _sessionsController.text = data.sessions.isEmpty ? '1' : data.sessions;
  }

  void _onToothToggled(int tooth) {
    setState(() {
      _saveCurrentToothForm();

      if (_selectedTeeth.contains(tooth)) {
        _selectedTeeth.remove(tooth);
        _toothData.remove(tooth);
        if (_currentEditingTooth == tooth) {
          if (_selectedTeeth.isNotEmpty) {
            _loadToothForm(_selectedTeeth.first);
          } else {
            _currentEditingTooth = null;
            _treatmentController.clear();
            _descriptionController.clear();
            _costController.clear();
            _sessionsController.text = '1';
          }
        }
      } else {
        _selectedTeeth.add(tooth);
        final current = _currentEditingTooth != null
            ? _toothData[_currentEditingTooth]
            : null;
        _toothData[tooth] = _ToothTreatmentData(
          title: current?.title ?? '',
          description: current?.description ?? '',
          cost: current?.cost ?? '',
          sessions: current?.sessions ?? '1',
        );
        _loadToothForm(tooth);
      }
    });
  }

  void _switchEditingTooth(int tooth) {
    if (_currentEditingTooth == tooth) return;
    setState(() {
      _saveCurrentToothForm();
      _loadToothForm(tooth);
    });
  }

  Appointment? get _selectedAppointment {
    final id = _selectedAppointmentId;
    if (id == null) return null;

    for (final appointment
        in context.read<AppointmentProvider>().appointments) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }

  Patient? get _selectedPatient {
    final id = _fromAppointment
        ? _selectedAppointment?.patientId
        : _selectedPatientId;

    if (id == null) return null;
    return context.read<PatientProvider>().getById(id);
  }

  Doctor? get _selectedDoctor {
    final id = _fromAppointment
        ? _selectedAppointment?.doctorId
        : _selectedDoctorId;

    if (id == null) return null;
    return context.read<DoctorProvider>().getDoctorById(id);
  }

  List<Appointment> _availableAppointments(
    AppointmentProvider provider,
  ) {
    final list = provider.appointments
        .where(
          (a) =>
              a.status != AppointmentStatus.cancelled &&
              a.status != AppointmentStatus.completed,
        )
        .toList();

    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  List<Treatment> _patientHistory(TreatmentProvider provider) {
    final patient = _selectedPatient;
    if (patient == null) return [];

    return provider
        .getTreatmentsByPatient(patient.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _addTreatment() async {
    _saveCurrentToothForm();

    final patient = _selectedPatient;
    final doctor = _selectedDoctor;

    if (patient == null) {
      _showError('اختر المريض أولاً.');
      return;
    }

    if (doctor == null) {
      _showError('اختر الطبيب أولاً.');
      return;
    }

    if (_selectedTeeth.isEmpty) {
      _showError('اختر سنًا واحدًا على الأقل من مخطط الأسنان.');
      return;
    }

    for (final tooth in _selectedTeeth) {
      final data = _toothData[tooth];
      final title = data?.title.trim() ?? '';
      final cost = double.tryParse(
            (data?.cost ?? '').trim().replaceAll(',', '.'),
          ) ??
          -1;
      final plannedSessions =
          int.tryParse((data?.sessions ?? '').trim()) ?? 0;

      if (title.isEmpty) {
        _showError('يرجى كتابة نوع / اسم العلاج للسن رقم $tooth.');
        _switchEditingTooth(tooth);
        return;
      }

      if (cost < 0) {
        _showError('التكلفة غير صحيحة للسن رقم $tooth.');
        _switchEditingTooth(tooth);
        return;
      }

      if (plannedSessions < 1) {
        _showError('عدد الجلسات للسن $tooth يجب أن يكون جلسة واحدة على الأقل.');
        _switchEditingTooth(tooth);
        return;
      }
    }

    final treatmentProvider = context.read<TreatmentProvider>();
    final now = DateTime.now();
    var idx = 0;

    for (final tooth in _selectedTeeth) {
      final data = _toothData[tooth]!;
      final title = data.title.trim();
      final description = data.description.trim();
      final cost = double.tryParse(
            data.cost.trim().replaceAll(',', '.'),
          ) ??
          0;
      final plannedSessions =
          int.tryParse(data.sessions.trim()) ?? 1;

      final treatmentId = '${now.microsecondsSinceEpoch}_$idx';
      idx++;

      final initialSession = TreatmentSession(
        id: '${treatmentId}_session_1',
        treatmentId: treatmentId,
        appointmentId: _selectedAppointment?.id,
        sessionNumber: 1,
        title: title,
        date: _selectedAppointment?.dateTime ?? now,
        cost: 0,
        createdAt: now,
      );

      final treatment = Treatment(
        id: treatmentId,
        patientId: patient.id,
        doctorId: doctor.id,
        toothNumber: tooth,
        title: title,
        description: description.isEmpty ? null : description,
        totalAmount: cost,
        plannedSessionCount: plannedSessions,
        status: TreatmentStatus.planned,
        createdAt: now,
        sessions: [initialSession],
      );

      await treatmentProvider.addTreatment(treatment);
    }

    if (!mounted) return;

    final count = _selectedTeeth.length;
    setState(() {
      _selectedTeeth.clear();
      _toothData.clear();
      _currentEditingTooth = null;
      _treatmentController.clear();
      _descriptionController.clear();
      _costController.clear();
      _sessionsController.text = '1';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 1
              ? 'تمت إضافة علاج $count أسنان بنجاح'
              : 'تمت إضافة العلاج بنجاح',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectAppointment(String? id) {
    setState(() {
      _saveCurrentToothForm();
      _selectedAppointmentId = id;
      _selectedPatientId = null;
      _selectedDoctorId = null;
      _selectedTeeth.clear();
      _toothData.clear();
      _currentEditingTooth = null;
      _treatmentController.clear();
      _descriptionController.clear();
      _costController.clear();
      _sessionsController.text = '1';
    });
  }

  void _switchMode(bool fromAppointment) {
    setState(() {
      _saveCurrentToothForm();
      _fromAppointment = fromAppointment;
      _selectedAppointmentId = null;
      _selectedPatientId = null;
      _selectedDoctorId = null;
      _selectedTeeth.clear();
      _toothData.clear();
      _currentEditingTooth = null;
      _treatmentController.clear();
      _descriptionController.clear();
      _costController.clear();
      _sessionsController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        // في الـ RTL أول عنصر في الـ Row يظهر على اليمين،
        // لذلك الـ Sidebar لازم يكون أول عنصر ليظهر يمين الصفحة.
        body: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Sidebar(activeRoute: 'treatments_teeth'),
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                        child: Column(
                          children: [
                            _buildModeSwitch(),
                            const SizedBox(height: 16),
                            _buildContextSection(),
                            const SizedBox(height: 16),
                            _buildMainWorkspace(),
                            const SizedBox(height: 16),
                            _buildHistorySection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.medical_services_outlined,
              color: _primary, size: 28),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'العلاجات والأسنان',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'إدارة علاجات الأسنان وتسجيل الإجراءات لكل سن',
                style: TextStyle(
                  fontSize: 14,
                  color: _muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Center(
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _modeButton(
                label: 'من موعد',
                icon: Icons.calendar_month_outlined,
                selected: _fromAppointment,
                onTap: () => _switchMode(true),
              ),
            ),
            Expanded(
              child: _modeButton(
                label: 'بدون موعد',
                icon: Icons.person_outline,
                selected: !_fromAppointment,
                onTap: () => _switchMode(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : _muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'بيانات المريض والموعد',
                  Icons.person_outline,
                ),
                const SizedBox(height: 14),
                if (_fromAppointment)
                  _buildAppointmentSelector()
                else
                  _buildWalkInSelectors(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPatientSummary(),
        ),
      ],
    );
  }

  Widget _buildAppointmentSelector() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, _) {
        final appointments = _availableAppointments(provider);

        return DropdownButtonFormField<String>(
          initialValue: _selectedAppointmentId,
          isExpanded: true,
          decoration: _inputDecoration(
            'اختيار الموعد',
            Icons.calendar_today_outlined,
          ),
          items: appointments.map((appointment) {
            final patient = context
                .read<PatientProvider>()
                .getById(appointment.patientId);
            final doctor = context
                .read<DoctorProvider>()
                .getDoctorById(appointment.doctorId);

            return DropdownMenuItem<String>(
              value: appointment.id,
              child: Text(
                '${patient?.fullName ?? 'مريض'}  •  '
                '${doctor?.fullName ?? 'طبيب'}  •  '
                '${_formatDateTime(appointment.dateTime)}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _selectAppointment,
        );
      },
    );
  }

  Widget _buildWalkInSelectors() {
    return Row(
      children: [
        Expanded(
          child: Consumer<PatientProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                initialValue: _selectedPatientId,
                isExpanded: true,
                decoration: _inputDecoration(
                  'المريض',
                  Icons.person_outline,
                ),
                items: provider.patients.map((patient) {
                  return DropdownMenuItem<String>(
                    value: patient.id,
                    child: Text(patient.fullName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _saveCurrentToothForm();
                    _selectedPatientId = value;
                    _selectedTeeth.clear();
                    _toothData.clear();
                    _currentEditingTooth = null;
                    _treatmentController.clear();
                    _descriptionController.clear();
                    _costController.clear();
                    _sessionsController.text = '1';
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<DoctorProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                initialValue: _selectedDoctorId,
                isExpanded: true,
                decoration: _inputDecoration(
                  'الطبيب',
                  Icons.medical_services_outlined,
                ),
                items: provider.activeDoctors.map((doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor.id,
                    child: Text(doctor.fullName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDoctorId = value);
                },
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _readOnlyField(
            label: 'التاريخ',
            value: _formatDate(DateTime.now()),
            icon: Icons.event_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientSummary() {
    final patient = _selectedPatient;
    final doctor = _selectedDoctor;
    final appointment = _selectedAppointment;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('البيانات الحالية', Icons.badge_outlined),
          const SizedBox(height: 10),
          _summaryRow('المريض', patient?.fullName ?? '—'),
          _summaryRow('الطبيب', doctor?.fullName ?? '—'),
          if (_fromAppointment) ...[
            _summaryRow(
              'التاريخ',
              appointment == null
                  ? '—'
                  : _formatDate(appointment.dateTime),
            ),
            _summaryRow(
              'الوقت',
              appointment == null
                  ? '—'
                  : _formatTime(appointment.dateTime),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainWorkspace() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildOdontogramCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _buildTreatmentFormCard(),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 260,
          child: _buildTreatmentSummary(),
        ),
      ],
    );
  }

  Widget _buildOdontogramCard() {
    final patient = _selectedPatient;

    return _card(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      child: Column(
        children: [
          Row(
            children: [
              _sectionTitle(
                'مخطط الأسنان',
                Icons.health_and_safety_outlined,
              ),
              const Spacer(),
              if (_selectedTeeth.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedTeeth.length} محدد',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 560,
            child: DentalChart(
              selectedTeeth: _selectedTeeth,
              currentEditingTooth: _currentEditingTooth,
              treatments: patient == null
                  ? const []
                  : context
                      .read<TreatmentProvider>()
                      .getTreatmentsByPatient(patient.id)
                      .toList(),
              onToothSelected: _onToothToggled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentFormCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('إضافة علاج', Icons.add_box_outlined),
              const Spacer(),
              if (_selectedTeeth.isNotEmpty)
                Text(
                  '${_selectedTeeth.length} أسنان محددة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_selectedTeeth.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    color: _primary,
                    size: 30,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اختر سنًا أو عدة أسنان من المخطط لإضافة العلاج',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _selectedToothCard(),
            const SizedBox(height: 14),
            TextField(
              controller: _treatmentController,
              decoration: _inputDecoration(
                'نوع / اسم العلاج (للسن #$_currentEditingTooth)',
                Icons.edit_note_outlined,
              ).copyWith(
                suffixIcon: const Icon(Icons.edit_outlined),
              ),
              onChanged: (_) => _saveCurrentToothForm(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: _inputDecoration(
                'الوصف التفصيلي (للسن #$_currentEditingTooth)',
                Icons.notes_outlined,
              ),
              onChanged: (_) => _saveCurrentToothForm(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(
                      'التكلفة (₪)',
                      Icons.payments_outlined,
                    ),
                    onChanged: (_) => _saveCurrentToothForm(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sessionsController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'عدد الجلسات',
                      Icons.event_repeat_outlined,
                    ),
                    onChanged: (_) => _saveCurrentToothForm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addTreatment,
                icon: const Icon(Icons.add),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(
                    _selectedTeeth.length > 1
                        ? 'إضافة علاج ${_selectedTeeth.length} أسنان'
                        : 'إضافة العلاج',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectedToothCard() {
    final sortedTeeth = _selectedTeeth.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _primary.withValues(alpha: .18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'السن الحالي للتعديل',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'السن #$_currentEditingTooth',
                    style: const TextStyle(
                      fontSize: 15,
                      color: _primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (_selectedTeeth.length > 1)
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: _currentEditingTooth,
                      isDense: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: _primary,
                      ),
                      items: sortedTeeth.map((tooth) {
                        return DropdownMenuItem<int>(
                          value: tooth,
                          child: Text(
                            'تعديل السن #$tooth',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _switchEditingTooth(val);
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sortedTeeth.map((tooth) {
              final isCurrent = tooth == _currentEditingTooth;
              return InkWell(
                onTap: () => _switchEditingTooth(tooth),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrent
                          ? _primary
                          : const Color(0xFFBAC8FF),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tooth',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : _primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _onToothToggled(tooth),
                        child: Icon(
                          Icons.close,
                          size: 13,
                          color: isCurrent ? Colors.white70 : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSummary() {
    final patient = _selectedPatient;

    return _card(
      child: Consumer<TreatmentProvider>(
        builder: (context, provider, _) {
          final history = patient == null
              ? <Treatment>[]
              : _patientHistory(provider);

          final total = history.fold<double>(
            0,
            (sum, treatment) => sum + treatment.totalAmount,
          );

          final completed = history
              .where((t) => t.status.isCompleted)
              .length;

          final needsTreatment =
              history.length - completed;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                'ملخص العلاجات',
                Icons.pie_chart_outline,
              ),
              const SizedBox(height: 14),
              _statRow('إجمالي العلاجات', '${history.length}'),
              _statRow('الأسنان المعالجة', '$completed'),
              _statRow('تحتاج علاج', '$needsTreatment'),
              const Divider(height: 26),
              _statRow(
                'التكلفة الإجمالية',
                '${total.toStringAsFixed(2)} ₪',
                strong: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistorySection() {
    final patient = _selectedPatient;

    return _card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Consumer<TreatmentProvider>(
        builder: (context, provider, _) {
          final history = patient == null
              ? <Treatment>[]
              : _patientHistory(provider);

          return Column(
            children: [
              Row(
                children: [
                  _sectionTitle(
                    'تاريخ علاجات المريض',
                    Icons.history_outlined,
                  ),
                  const Spacer(),
                  Text(
                    '${history.length} علاج',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'لا توجد علاجات مسجلة لهذا المريض.',
                    style: TextStyle(color: _muted),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF5F6FD)),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('رقم السن')),
                      DataColumn(label: Text('العلاج')),
                      DataColumn(label: Text('الوصف')),
                      DataColumn(label: Text('الجلسات')),
                      DataColumn(label: Text('التكلفة')),
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('إجراءات')),
                    ],
                    rows: List.generate(history.length, (index) {
                      final treatment = history[index];

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text('${treatment.toothNumber ?? '—'}')),
                          DataCell(Text(treatment.title)),
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                treatment.description?.isNotEmpty == true
                                    ? treatment.description!
                                    : '—',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${treatment.completedSessionsCount}'
                              ' / '
                              '${treatment.plannedSessionCount}',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${treatment.totalAmount.toStringAsFixed(2)} ₪',
                            ),
                          ),
                          DataCell(_statusChip(treatment)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (treatment.isEditable) ...[
                                  IconButton(
                                    tooltip: 'تعديل عدد الجلسات',
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 19,
                                      color: _primary,
                                    ),
                                    onPressed: () =>
                                        _showEditSessionsDialog(treatment),
                                  ),
                                  if (treatment.canAddSession)
                                    IconButton(
                                      tooltip: 'حجز جلسة قادمة',
                                      icon: const Icon(
                                        Icons.add_alarm_rounded,
                                        size: 19,
                                        color: Color(0xFF006688),
                                      ),
                                      onPressed: () =>
                                          _showAddSessionDialog(treatment),
                                    ),
                                ],
                                IconButton(
                                  tooltip: 'سداد / دفع العلاج',
                                  icon: const Icon(
                                    Icons.payments_outlined,
                                    size: 19,
                                    color: Color(0xFF00897B),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TreatmentPaymentScreen(
                                          initialTreatmentId: treatment.id,
                                          initialPatientId:
                                              treatment.patientId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSessionDialog(Treatment treatment) async {
    final doctor =
        context.read<DoctorProvider>().getDoctorById(treatment.doctorId);
    if (doctor == null) {
      _showError('لم يتم العثور على الطبيب المرتبط بهذا العلاج');
      return;
    }

    final appointmentProvider = context.read<AppointmentProvider>();
    final nextSessionNum = treatment.sessions.length + 1;
    final titleController = TextEditingController(
      text: '${treatment.title} - جلسة $nextSessionNum',
    );
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    DateTime? selectedSlot;
    const duration = 30;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableSlots = appointmentProvider.getAvailableSlots(
              doctor: doctor,
              date: selectedDate,
              slotDuration: duration,
            );

            return AlertDialog(
              title: Text(
                'حجز موعد جلسة جديدة ($nextSessionNum / ${treatment.plannedSessionCount})',
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الطبيب المعالج: ${doctor.fullName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان / إجراء الجلسة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = picked;
                                    selectedSlot = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                'التاريخ: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'الأوقات المتاحة وفق جدول الطبيب:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (availableSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: const Text(
                            'لا توجد فترات متاحة للطبيب في هذا اليوم، يرجى اختيار يوم آخر.',
                            style: TextStyle(fontSize: 12, color: Colors.brown),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableSlots.map((slot) {
                            final isSelected = selectedSlot == slot;
                            final timeText =
                                '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
                            return ChoiceChip(
                              label: Text(timeText),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  selectedSlot = selected ? slot : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: selectedSlot == null
                      ? null
                      : () async {
                          final session = TreatmentSession(
                            id: '${treatment.id}_session_$nextSessionNum',
                            treatmentId: treatment.id,
                            sessionNumber: nextSessionNum,
                            title: titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : treatment.title,
                            date: selectedSlot!,
                            cost: 0,
                            createdAt: DateTime.now(),
                          );

                          final messenger =
                              ScaffoldMessenger.of(this.context);
                          final trProvider =
                              context.read<TreatmentProvider>();
                          final apptId =
                              await trProvider.addSessionWithAppointment(
                            treatmentId: treatment.id,
                            session: session,
                            doctor: doctor,
                            appointmentProvider: appointmentProvider,
                            appointmentDurationMinutes: duration,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) return;

                          if (apptId != null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم حجز موعد الجلسة وإضافتها بنجاح',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            _showError(
                              'تعذر إضافة الجلسة (تحقق من عدم تعارض المواعيد أو اكتمال عدد الجلسات)',
                            );
                          }
                        },
                  child: const Text('تأكيد وحجز الموعد'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
  }

  Future<void> _showEditSessionsDialog(Treatment treatment) async {
    final controller = TextEditingController(
      text: treatment.plannedSessionCount.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل عدد الجلسات'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد الجلسات المخطط',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(controller.text.trim());
                if (count == null || count < 1) return;

                context
                    .read<TreatmentProvider>()
                    .updatePlannedSessionCount(
                      treatment.id,
                      count,
                    );

                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Widget _statusChip(Treatment treatment) {
    final completed = treatment.status.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFFEAF8EE)
            : const Color(0xFFFFF3E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        completed ? 'معالج' : 'يحتاج علاج',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: completed
              ? const Color(0xFF159447)
              : const Color(0xFFE88A00),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 7),
            color: Color(0x0A34405A),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 19),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    String label,
    String value, {
    bool strong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: strong ? _primary : _text,
              fontWeight: FontWeight.w800,
              fontSize: strong ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(label, icon),
      child: Text(
        value,
        style: const TextStyle(
          color: _text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: _primary),
      filled: true,
      fillColor: const Color(0xFFFCFCFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.5,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return '${_formatTime(value)}  ${_formatDate(value)}';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

enum _DentalToothState { treated, needsTreatment }

class DentalChart extends StatelessWidget {
  final Set<int> selectedTeeth;
  final int? currentEditingTooth;
  final List<Treatment> treatments;
  final ValueChanged<int> onToothSelected;

  const DentalChart({
    super.key,
    required this.selectedTeeth,
    this.currentEditingTooth,
    required this.treatments,
    required this.onToothSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final tooth = _DentalChartGeometry.hitTest(
              details.localPosition,
              size,
            );
            if (tooth != null) onToothSelected(tooth);
          },
          child: CustomPaint(
            painter: DentalChartPainter(
              selectedTeeth: selectedTeeth,
              currentEditingTooth: currentEditingTooth,
              treatments: treatments,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _ToothLayout {
  final int number;
  final int type;
  final Offset center;
  final Offset label;
  final double width;
  final double depth;
  final double angle;

  const _ToothLayout({
    required this.number,
    required this.type,
    required this.center,
    required this.label,
    required this.width,
    required this.depth,
    required this.angle,
  });
}

class _DentalChartGeometry {
  static const double theta = 97 * math.pi / 180;

  static const Map<int, double> widths = {
    1: 44, 2: 38, 3: 44, 4: 42,
    5: 42, 6: 60, 7: 56, 8: 50,
  };

  static const Map<int, double> depths = {
    1: 40, 2: 38, 3: 46, 4: 46,
    5: 46, 6: 58, 7: 56, 8: 50,
  };

  // الترقيم العالمي 1-32 (من اليسار لليمين كما يظهر على الشاشة):
  // الفك العلوي: 1 → 16 (من ضرس العقل الأيمن للمريض)
  static const List<int> upper = [
    1, 2, 3, 4, 5, 6, 7, 8,
    9, 10, 11, 12, 13, 14, 15, 16,
  ];

  // الفك السفلي: 32 → 17
  static const List<int> lower = [
    32, 31, 30, 29, 28, 27, 26, 25,
    24, 23, 22, 21, 20, 19, 18, 17,
  ];

  /// نوع السن: 1 قاطع مركزي ... 8 ضرس العقل
  static int typeOf(int tooth) {
    if (tooth <= 8) return 9 - tooth;
    if (tooth <= 16) return tooth - 8;
    if (tooth >= 25) return tooth - 24;
    return 25 - tooth;
  }

  static List<_ToothLayout> build(Size size) {
    const w = 800.0;
    const h = 850.0;

    final scale = math.min(size.width / w, size.height / h);
    final ox = (size.width - w * scale) / 2;
    final oy = (size.height - h * scale) / 2;
    final result = <_ToothLayout>[];

    void jaw({
      required List<int> order,
      required double cy,
      required double rx,
      required double ry,
      required bool top,
    }) {
      Offset point(double t) => Offset(
            400 + rx * math.sin(t),
            top
                ? cy - ry * math.cos(t)
                : cy + ry * math.cos(t),
          );

      const n = 600;
      final arc = <double>[0];
      var previous = point(-theta);

      for (var i = 1; i <= n; i++) {
        final t = -theta + 2 * theta * i / n;
        final current = point(t);
        arc.add(arc.last + (current - previous).distance);
        previous = current;
      }

      final length = arc.last;
      final total = order.fold<double>(
        0,
        (sum, tooth) => sum + (widths[typeOf(tooth)] ?? 44),
      );
      final k = length * .99 / total;

      var used = 0.0;

      for (final tooth in order) {
        final type = typeOf(tooth);
        final tw = (widths[type] ?? 44) * k;
        final td = (depths[type] ?? 46) * k * 1.05;
        final target = used + tw / 2;
        used += tw;

        var index = 0;
        while (index < n && arc[index] < target + length * .005) {
          index++;
        }

        final t = -theta + 2 * theta * index / n;
        final c = point(t);

        final nx = math.sin(t) / rx;
        final ny = (top ? -1 : 1) * math.cos(t) / ry;
        final m = math.sqrt(nx * nx + ny * ny);

        final normal = Offset(nx / m, ny / m);

        result.add(
          _ToothLayout(
            number: tooth,
            type: type,
            center: Offset(
              ox + c.dx * scale,
              oy + c.dy * scale,
            ),
            width: tw * scale,
            depth: td * scale,
            angle: (top ? 1 : -1) * t,
            label: Offset(
              ox + (c.dx + normal.dx * (td / 2 + 38)) * scale,
              oy + (c.dy + normal.dy * (td / 2 + 38)) * scale + 5,
            ),
          ),
        );
      }
    }

    jaw(order: upper, cy: 360, rx: 215, ry: 225, top: true);
    jaw(order: lower, cy: 540, rx: 215, ry: 200, top: false);

    return result;
  }

  static int? hitTest(Offset point, Size size) {
    int? result;
    var best = double.infinity;

    for (final tooth in build(size)) {
      final dx = (point.dx - tooth.center.dx) /
          math.max(1, tooth.width / 2);
      final dy = (point.dy - tooth.center.dy) /
          math.max(1, tooth.depth / 2);
      final d = dx * dx + dy * dy;

      if (d < best && d <= 4.5) {
        best = d;
        result = tooth.number;
      }
    }

    return result;
  }
}

class DentalChartPainter extends CustomPainter {
  final Set<int> selectedTeeth;
  final int? currentEditingTooth;
  final List<Treatment> treatments;

  const DentalChartPainter({
    required this.selectedTeeth,
    this.currentEditingTooth,
    required this.treatments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final teeth = _DentalChartGeometry.build(size);
    _guides(canvas, size);
    _gums(canvas, size);
    _teeth(canvas, teeth);
    _numbers(canvas, teeth);
    _jawLabels(canvas, size);
  }

  void _guides(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;

    _dash(
      canvas,
      Offset(size.width * .34, size.height * .535),
      Offset(size.width * .66, size.height * .535),
      p,
    );

    _dash(
      canvas,
      Offset(size.width / 2, size.height * .08),
      Offset(size.width / 2, size.height * .32),
      p,
    );

    _dash(
      canvas,
      Offset(size.width / 2, size.height * .75),
      Offset(size.width / 2, size.height * .87),
      p,
    );
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint p) {
    final length = (b - a).distance;
    if (length == 0) return;

    final direction = (b - a) / length;
    const dash = 5.0;
    const gap = 5.0;

    for (var x = 0.0; x < length; x += dash + gap) {
      final end = math.min(x + dash, length);
      canvas.drawLine(
        a + direction * x,
        a + direction * end,
        p,
      );
    }
  }

  void _gums(Canvas canvas, Size size) {
    final scale = math.min(size.width / 800, size.height / 850);
    final ox = (size.width - 800 * scale) / 2;
    final oy = (size.height - 850 * scale) / 2;

    void drawJaw({
      required double cy,
      required double rx,
      required double ry,
      required bool top,
    }) {
      final path = Path();

      for (var i = 0; i <= 140; i++) {
        final t = -_DentalChartGeometry.theta +
            2 * _DentalChartGeometry.theta * i / 140;

        final point = Offset(
          ox + (400 + rx * math.sin(t)) * scale,
          oy +
              (top
                      ? cy - ry * math.cos(t)
                      : cy + ry * math.cos(t)) *
                  scale,
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 84 * scale
          ..color = const Color(0xFFF4A9A9),
      );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 60 * scale
          ..color = const Color(0xFFF9C7C7),
      );
    }

    drawJaw(cy: 360, rx: 215, ry: 225, top: true);
    drawJaw(cy: 540, rx: 215, ry: 200, top: false);
  }

  void _teeth(Canvas canvas, List<_ToothLayout> teeth) {
    for (final tooth in teeth) {
      final isSelected = selectedTeeth.contains(tooth.number);
      final isCurrentEditing = tooth.number == currentEditingTooth;
      final state = _stateFor(tooth.number);

      canvas.save();
      canvas.translate(tooth.center.dx, tooth.center.dy);
      canvas.rotate(tooth.angle);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: tooth.width,
        height: tooth.depth,
      );

      final radius = tooth.type >= 6
          ? tooth.width * .30
          : tooth.type >= 4
              ? tooth.width * .36
              : tooth.width * .42;

      final path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(radius),
          ),
        );

      canvas.drawShadow(
        path,
        isSelected
            ? (isCurrentEditing ? const Color(0xAA38BDF8) : const Color(0x6638BDF8))
            : const Color(0x447F1D1D),
        isSelected ? (isCurrentEditing ? 10 : 6) : 3,
        true,
      );

      canvas.drawPath(
        path,
        Paint()..shader = _shader(rect, isSelected, isCurrentEditing, state),
      );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrentEditing ? 3.0 : (isSelected ? 2.0 : 1.2)
          ..color = isCurrentEditing
              ? const Color(0xFF0284C7)
              : (isSelected
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFD8C7AB)),
      );

      _details(canvas, tooth, isSelected);
      canvas.restore();
    }
  }

  Shader _shader(
    Rect rect,
    bool selected,
    bool isCurrentEditing,
    _DentalToothState? state,
  ) {
    if (selected) {
      if (isCurrentEditing) {
        return const RadialGradient(
          center: Alignment(-.35, -.45),
          radius: 1.1,
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFF38BDF8),
            Color(0xFF1D4ED8),
          ],
        ).createShader(rect);
      }
      return const RadialGradient(
        center: Alignment(-.35, -.45),
        radius: 1.1,
        colors: [
          Color(0xFFE0F2FE),
          Color(0xFF93C5FD),
          Color(0xFF3B82F6),
        ],
      ).createShader(rect);
    }

    if (state == _DentalToothState.treated) {
      return const RadialGradient(
        center: Alignment(-.35, -.45),
        radius: 1.1,
        colors: [
          Color(0xFFECFDF5),
          Color(0xFF86EFAC),
          Color(0xFF22C55E),
        ],
      ).createShader(rect);
    }

    if (state == _DentalToothState.needsTreatment) {
      return const RadialGradient(
        center: Alignment(-.35, -.45),
        radius: 1.1,
        colors: [
          Color(0xFFFFFBEB),
          Color(0xFFFCD34D),
          Color(0xFFF59E0B),
        ],
      ).createShader(rect);
    }

    return const RadialGradient(
      center: Alignment(-.35, -.45),
      radius: 1.1,
      colors: [
        Color(0xFFFFFEFB),
        Color(0xFFF6ECDC),
        Color(0xFFE3D3BA),
      ],
    ).createShader(rect);
  }

  void _details(
    Canvas canvas,
    _ToothLayout tooth,
    bool selected,
  ) {
    final w = tooth.width;
    final d = tooth.depth;

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = selected
          ? Colors.white.withValues(alpha: .82)
          : const Color(0xFFC9B493);

    final light = Paint()
      ..color = Colors.white.withValues(alpha: .50);

    if (tooth.type >= 6) {
      final grooves = Path()
        ..moveTo(-w * .32, 0)
        ..quadraticBezierTo(0, -d * .12, w * .32, 0)
        ..moveTo(0, -d * .32)
        ..quadraticBezierTo(w * .06, 0, 0, d * .32);

      canvas.drawPath(grooves, line);

      for (final p in [
        Offset(-w * .20, -d * .20),
        Offset(w * .20, -d * .20),
        Offset(-w * .20, d * .20),
        Offset(w * .20, d * .20),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: p,
            width: w * .30,
            height: d * .28,
          ),
          light,
        );
      }
    } else if (tooth.type >= 4) {
      final groove = Path()
        ..moveTo(-w * .30, 0)
        ..quadraticBezierTo(0, d * .10, w * .30, 0);

      canvas.drawPath(groove, line);

      for (final sign in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(sign * w * .18, 0),
            width: w * .32,
            height: d * .48,
          ),
          light,
        );
      }
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-w * .10, -d * .12),
          width: w * .48,
          height: d * .36,
        ),
        light,
      );

      final edge = Path()
        ..moveTo(-w * .30, d * .30)
        ..quadraticBezierTo(0, d * .38, w * .30, d * .30);

      canvas.drawPath(edge, line);
    }
  }

  void _numbers(Canvas canvas, List<_ToothLayout> teeth) {
    for (final tooth in teeth) {
      final isSelected = selectedTeeth.contains(tooth.number);
      final isCurrentEditing = tooth.number == currentEditingTooth;

      final painter = TextPainter(
        text: TextSpan(
          text: '${tooth.number}',
          style: TextStyle(
            fontSize: isCurrentEditing ? 21 : (isSelected ? 19 : 17),
            fontWeight:
                isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isCurrentEditing
                ? const Color(0xFF0052CC)
                : (isSelected
                    ? const Color(0xFF0066FF)
                    : const Color(0xFF64748B)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        tooth.label -
            Offset(
              painter.width / 2,
              painter.height / 2,
            ),
      );
    }
  }

  void _jawLabels(Canvas canvas, Size size) {
    void label(String text, double y) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          size.width / 2 - painter.width / 2,
          y - painter.height / 2,
        ),
      );
    }

    label('الفك العلوي', size.height * .40);
    label('الفك السفلي', size.height * .69);
  }

  _DentalToothState? _stateFor(int tooth) {
    final list = treatments
        .where((t) => t.toothNumber == tooth)
        .toList();

    if (list.isEmpty) return null;

    if (list.any((t) => t.status.isActive)) {
      return _DentalToothState.needsTreatment;
    }

    if (list.any((t) => t.status.isCompleted)) {
      return _DentalToothState.treated;
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant DentalChartPainter oldDelegate) {
    if (oldDelegate.currentEditingTooth != currentEditingTooth) return true;
    if (!setEquals(oldDelegate.selectedTeeth, selectedTeeth)) return true;
    if (oldDelegate.treatments.length != treatments.length) return true;

    for (var i = 0; i < treatments.length; i++) {
      final a = oldDelegate.treatments[i];
      final b = treatments[i];

      if (a.id != b.id ||
          a.status != b.status ||
          a.toothNumber != b.toothNumber) {
        return true;
      }
    }

    return false;
  }
}