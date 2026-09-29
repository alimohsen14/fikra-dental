import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../providers/appointment_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';
import 'components/sidebar.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final appointmentProvider = context.read<AppointmentProvider>();
      final doctorProvider = context.read<DoctorProvider>();
      final patientProvider = context.read<PatientProvider>();

      await appointmentProvider.loadAppointments();
      await doctorProvider.loadDoctors();
      await patientProvider.loadPatients();

      if (mounted) {
        setState(() {});
      }
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _weekdayArabic(DateTime date) {
    const names = {
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
      DateTime.monday: 'الاثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
    };

    return names[date.weekday] ?? '';
  }

  String _monthArabic(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return months[month];
  }

  String _formatDateArabic(DateTime date) {
    return '${_weekdayArabic(date)}، ${date.day} ${_monthArabic(date.month)} ${date.year}';
  }

  void _changeDay(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = _dateOnly(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        body: Row(
          children: [
            const Sidebar(activeRoute: 'appointments'),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Consumer3<AppointmentProvider, DoctorProvider, PatientProvider>(
        builder: (
          context,
          appointmentProvider,
          doctorProvider,
          patientProvider,
          child,
        ) {
          final doctors = doctorProvider.activeDoctors;

          final todayAppointments = appointmentProvider
              .getByDate(DateTime.now())
              .where(
                (appointment) =>
                    appointment.status != AppointmentStatus.cancelled,
              )
              .toList();

          final pendingToday = todayAppointments
              .where(
                (appointment) =>
                    appointment.status == AppointmentStatus.pending,
              )
              .length;

          final completedToday = todayAppointments
              .where(
                (appointment) =>
                    appointment.status == AppointmentStatus.completed,
              )
              .length;

          final selectedAppointments = appointmentProvider
              .getByDate(_selectedDate)
              .where(
                (appointment) =>
                    appointment.status != AppointmentStatus.cancelled,
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(),

                const SizedBox(height: 24),

                _buildStats(
                  totalToday: todayAppointments.length,
                  pendingToday: pendingToday,
                  completedToday: completedToday,
                ),

                const SizedBox(height: 20),

                _buildDateNavigation(),

                const SizedBox(height: 20),

                if (doctors.isEmpty)
                  _buildNoDoctors()
                else
                  _buildDoctorsSchedule(
                    doctors,
                    selectedAppointments,
                  ),

                const SizedBox(height: 20),

                if (selectedAppointments.isEmpty)
                  _buildEmptyDay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'إدارة وجدول المواعيد',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF131B2E),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'متابعة مواعيد المرضى وجداول الأطباء اليومية',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _openBookingModal,
          icon: Icon(
            Icons.add_circle_outline_rounded,
            color: Colors.white,
          ),
          label: Text(
            'حجز موعد',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              const Color(0xFF0066FF),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            elevation: WidgetStateProperty.all(4),
          ),
        ),
      ],
    );
  }

  Widget _buildStats({
    required int totalToday,
    required int pendingToday,
    required int completedToday,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'إجمالي مواعيد اليوم',
            value: totalToday,
            subtitle: 'موعد مسجل',
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF0050CB),
            iconBg: const Color(0xFFE2E7FF),
            subtitleColor: const Color(0xFF0050CB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: 'مواعيد قيد الانتظار',
            value: pendingToday,
            subtitle: 'بانتظار التأكيد',
            icon: Icons.pending_actions_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            subtitleColor: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: 'الجلسات المكتملة اليوم',
            value: completedToday,
            subtitle: 'تم إكمالها',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF006688),
            iconBg: const Color(0xFFC2E8FF),
            subtitleColor: const Color(0xFF006688),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF424656),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: Color(0xFF131B2E),
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    final isToday = _isSameDate(
      _selectedDate,
      DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'اليوم السابق',
                  onPressed: () => _changeDay(-1),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _dateOnly(DateTime.now());
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0050CB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'اليوم',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'اليوم التالي',
                  onPressed: () => _changeDay(1),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF0050CB),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDateArabic(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2E8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'اليوم: ${_weekdayArabic(_selectedDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF004D67),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(
              Icons.event_rounded,
              size: 18,
            ),
            label: const Text('تاريخ مخصص'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF424656),
              side: const BorderSide(
                color: Color(0xFFC2C6D8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSchedule(
    List<Doctor> doctors,
    List<Appointment> appointments,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 1250) {
          columns = doctors.length >= 3 ? 3 : doctors.length;
        } else if (constraints.maxWidth >= 850) {
          columns = doctors.length >= 2 ? 2 : 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: doctors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 500,
          ),
          itemBuilder: (context, index) {
            final doctor = doctors[index];

            final doctorAppointments = appointments
                .where(
                  (appointment) =>
                      appointment.doctorId == doctor.id,
                )
                .toList()
              ..sort(
                (a, b) => a.dateTime.compareTo(b.dateTime),
              );

            return _buildDoctorColumn(
              doctor,
              doctorAppointments,
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorColumn(
    Doctor doctor,
    List<Appointment> appointments,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAE1FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      doctor.fullName.isEmpty
                          ? 'د'
                          : doctor.fullName.characters.first,
                      style: const TextStyle(
                        color: Color(0xFF0050CB),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'د. ${doctor.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF355C83),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E7FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${appointments.length} مواعيد',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0050CB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (appointments.any((a) => a.status == AppointmentStatus.pending)) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 11,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${appointments.where((a) => a.status == AppointmentStatus.pending).length} قيد الانتظار',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: appointments.isEmpty
                ? _buildDoctorEmpty()
                : ListView.separated(
                    itemCount: appointments.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      return _buildAppointmentCard(
                        appointments[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorEmpty() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 38,
            color: Color(0xFF727687),
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد مواعيد لهذا اليوم',
            style: TextStyle(
              color: Color(0xFF727687),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment,
  ) {
    final patientProvider = context.read<PatientProvider>();
    final patient = patientProvider.getById(
      appointment.patientId,
    );

    final patientName =
        patient?.fullName ?? 'مريض غير معروف';

    final isPending = appointment.status == AppointmentStatus.pending;
    final isConfirmed = appointment.status == AppointmentStatus.confirmed;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFFDF9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPending
            ? Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                width: 1.3,
              )
            : isConfirmed
                ? Border.all(
                    color: const Color(0xFF0050CB).withValues(alpha: 0.15),
                  )
                : null,
        boxShadow: [
          BoxShadow(
            color: isPending
                ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.025),
            blurRadius: isPending ? 9 : 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.schedule_rounded,
                      size: 15,
                      color: isPending
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0050CB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(appointment.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPending
                            ? const Color(0xFF92400E)
                            : const Color(0xFF131B2E),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _statusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'مدة الموعد: ${appointment.duration} دقيقة',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF727687),
            ),
          ),
          const SizedBox(height: 11),
          _appointmentActions(appointment),
        ],
      ),
    );
  }

  Widget _statusBadge(AppointmentStatus status) {
    late String text;
    late Color background;
    late Color foreground;
    late Color borderColor;
    late IconData icon;

    switch (status) {
      case AppointmentStatus.pending:
        text = 'قيد الانتظار';
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFFB45309);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.hourglass_top_rounded;
        break;

      case AppointmentStatus.confirmed:
        text = 'مؤكد';
        background = const Color(0xFFDAE1FF);
        foreground = const Color(0xFF0050CB);
        borderColor = const Color(0xFFBAC8FF);
        icon = Icons.check_circle_outline_rounded;
        break;

      case AppointmentStatus.completed:
        text = 'مكتمل';
        background = const Color(0xFFC2E8FF);
        foreground = const Color(0xFF006688);
        borderColor = const Color(0xFF94DCFF);
        icon = Icons.task_alt_rounded;
        break;

      case AppointmentStatus.cancelled:
        text = 'ملغى';
        background = const Color(0xFFFFDAD6);
        foreground = const Color(0xFFBA1A1A);
        borderColor = const Color(0xFFFFB4AB);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentActions(
    Appointment appointment,
  ) {
    final provider = context.read<AppointmentProvider>();

    switch (appointment.status) {
      case AppointmentStatus.pending:
        return Row(
          children: [
            Expanded(
              child: _smallActionButton(
                title: 'تأكيد الموعد',
                color: const Color(0xFF0066FF),
                onPressed: () async {
                  await provider.confirmAppointment(
                    appointment.id,
                  );
                },
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _smallActionButton(
                title: 'إلغاء',
                color: const Color(0xFFBA1A1A),
                background: const Color(0xFFFFDAD6),
                onPressed: () async {
                  await provider.cancelAppointment(
                    appointment.id,
                  );
                },
              ),
            ),
          ],
        );

      case AppointmentStatus.confirmed:
        return Row(
          children: [
            Expanded(
              child: _smallActionButton(
                title: 'إكمال الجلسة',
                color: const Color(0xFF006688),
                onPressed: () async {
                  await provider.completeAppointment(
                    appointment.id,
                  );
                },
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _smallActionButton(
                title: 'إلغاء',
                color: const Color(0xFFBA1A1A),
                background: const Color(0xFFFFDAD6),
                onPressed: () async {
                  await provider.cancelAppointment(
                    appointment.id,
                  );
                },
              ),
            ),
          ],
        );

      case AppointmentStatus.completed:
        return const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'تم إكمال الجلسة',
            style: TextStyle(
              color: Color(0xFF006688),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case AppointmentStatus.cancelled:
        return const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'تم إلغاء الموعد',
            style: TextStyle(
              color: Color(0xFFBA1A1A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }

  Widget _smallActionButton({
    required String title,
    required Color color,
    required VoidCallback onPressed,
    Color? background,
  }) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              background ?? color,
          foregroundColor:
              background == null ? Colors.white : color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 50,
            color: Color(0xFF727687),
          ),
          SizedBox(height: 12),
          Text(
            'لا يوجد أطباء نشطون',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'أضف طبيباً من صفحة الحساب والإعدادات للبدء بحجز المواعيد.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF727687),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    return const SizedBox.shrink();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    final minuteText = minute.toString().padLeft(2, '0');

    return '$displayHour:$minuteText ${isPm ? 'م' : 'ص'}';
  }

  Future<void> _openBookingModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xFF131B2E).withValues(
        alpha: 0.45,
      ),
      builder: (_) => const _BookingModal(),
    );

    if (mounted) {
      setState(() {});
    }
  }
}

// ============================================================
// Booking Modal
// ============================================================

class _BookingModal extends StatefulWidget {
  const _BookingModal();

  @override
  State<_BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<_BookingModal> {
  Patient? _selectedPatient;
  Doctor? _selectedDoctor;

  DateTime _selectedDate = DateTime.now();

  int _duration = 30;

  DateTime? _selectedSlot;

  AppointmentStatus _bookingStatus = AppointmentStatus.confirmed;

  String _patientSearch = '';

  final TextEditingController _notesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doctors = context.read<DoctorProvider>().activeDoctors;

      if (doctors.isNotEmpty && mounted) {
        setState(() {
          _selectedDoctor = doctors.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _weekdayArabic(DateTime date) {
    const names = {
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
      DateTime.monday: 'الاثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
    };

    return names[date.weekday] ?? '';
  }

  String _monthArabic(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return months[month];
  }

  String _formatDateArabic(DateTime date) {
    return '${_weekdayArabic(date)}، ${date.day} ${_monthArabic(date.month)} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
        _selectedSlot = null;
      });
    }
  }

  List<Patient> _filteredPatients(
    PatientProvider provider,
  ) {
    final query = _patientSearch.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    return provider.patients.where((patient) {
      return patient.fullName
              .toLowerCase()
              .contains(query) ||
          patient.nationalId
              .toLowerCase()
              .contains(query);
    }).take(8).toList();
  }

  WeekDay _weekDayFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return WeekDay.saturday;
      case DateTime.sunday:
        return WeekDay.sunday;
      case DateTime.monday:
        return WeekDay.monday;
      case DateTime.tuesday:
        return WeekDay.tuesday;
      case DateTime.wednesday:
        return WeekDay.wednesday;
      case DateTime.thursday:
        return WeekDay.thursday;
      case DateTime.friday:
        return WeekDay.friday;
      default:
        return WeekDay.sunday;
    }
  }

  DoctorSchedule? _getScheduleForDate(
    Doctor doctor,
    DateTime date,
  ) {
    final day = _weekDayFromDate(date);

    for (final schedule in doctor.schedules) {
      if (schedule.day == day && schedule.isWorking) {
        return schedule;
      }
    }

    return null;
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return 0;
    }

    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts[1]) ?? 0);
  }

  DateTime _dateWithMinutes(
    DateTime date,
    int minutes,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  bool _overlaps(
    DateTime start,
    int duration,
    Appointment appointment,
  ) {
    final startA = start;
    final endA = start.add(
      Duration(minutes: duration),
    );

    final startB = appointment.dateTime;
    final endB = appointment.dateTime.add(
      Duration(minutes: appointment.duration),
    );

    return startA.isBefore(endB) &&
        endA.isAfter(startB);
  }

  List<Appointment> _doctorAppointments() {
    if (_selectedDoctor == null) {
      return [];
    }

    final provider =
        context.read<AppointmentProvider>();

    return provider
        .getByDoctor(
          _selectedDoctor!.id,
          date: _selectedDate,
        )
        .where(
          (appointment) => appointment.blocksSlot,
        )
        .toList();
  }

  List<DateTime> _availableSlots() {
    if (_selectedDoctor == null) {
      return [];
    }

    final schedule = _getScheduleForDate(
      _selectedDoctor!,
      _selectedDate,
    );

    if (schedule == null) {
      return [];
    }

    final startMinutes =
        _timeToMinutes(schedule.startTime);

    final endMinutes =
        _timeToMinutes(schedule.endTime);

    if (endMinutes <= startMinutes) {
      return [];
    }

    final appointments = _doctorAppointments();

    final slots = <DateTime>[];

    for (
      int minutes = startMinutes;
      minutes + _duration <= endMinutes;
      minutes += _duration
    ) {
      final slot = _dateWithMinutes(
        _selectedDate,
        minutes,
      );

      final blocked = appointments.any(
        (appointment) => _overlaps(
          slot,
          _duration,
          appointment,
        ),
      );

      if (!blocked) {
        slots.add(slot);
      }
    }

    return slots;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    final isPm = hour >= 12;
    final displayHour =
        hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} ${isPm ? 'م' : 'ص'}';
  }

  Future<void> _saveAppointment([AppointmentStatus? targetStatus]) async {
    if (_selectedPatient == null) {
      _showError('يرجى اختيار المريض أولاً.');
      return;
    }

    if (_selectedDoctor == null) {
      _showError('يرجى اختيار الطبيب أولاً.');
      return;
    }

    if (_selectedSlot == null) {
      _showError('يرجى اختيار الوقت المناسب.');
      return;
    }

    final status = targetStatus ?? _bookingStatus;
    final appointmentProvider =
        context.read<AppointmentProvider>();

    final alreadyBooked =
        appointmentProvider
            .getByDoctor(
              _selectedDoctor!.id,
              date: _selectedDate,
            )
            .any(
              (appointment) =>
                  appointment.blocksSlot &&
                  _overlaps(
                    _selectedSlot!,
                    _duration,
                    appointment,
                  ),
            );

    if (alreadyBooked) {
      _showError(
        'هذا الوقت تم حجزه بالفعل. اختر وقتاً آخر.',
      );
      return;
    }

    final appointment = Appointment(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      patientId: _selectedPatient!.id,
      doctorId: _selectedDoctor!.id,
      dateTime: _selectedSlot!,
      duration: _duration,
      status: status,
      createdAt: DateTime.now(),
    );

    await appointmentProvider.addAppointment(
      appointment,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    final statusMessage = status == AppointmentStatus.confirmed
        ? 'تم تسجيل الموعد بنجاح كـ "حجز مؤكد".'
        : 'تم حفظ الموعد كـ "قيد الانتظار".';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          statusMessage,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 950,
            maxHeight: 850,
          ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.18,
                ),
                blurRadius: 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildModalHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildPatientSection(),
                      const SizedBox(height: 22),
                      _buildDoctorSection(),
                      const SizedBox(height: 22),
                      _buildDateAndDuration(),
                      const SizedBox(height: 22),
                      _buildSlotsSection(),
                      const SizedBox(height: 22),
                      _buildStatusSection(),
                      const SizedBox(height: 22),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
              _buildModalFooter(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildModalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E7FF),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF0050CB),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'حجز موعد جديد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF131B2E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'تسجيل موعد للمريض في جدول الطبيب',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF727687),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSection() {
    final patientProvider =
        context.watch<PatientProvider>();

    final results =
        _filteredPatients(patientProvider);

    return _section(
      number: '1',
      title: 'اختيار المريض',
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _patientSearch = value;
              });
            },
            decoration: InputDecoration(
              hintText:
                  'ابحث باسم المريض أو رقم الهوية...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF727687),
              ),
              filled: true,
              fillColor: const Color(0xFFF2F3FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  color: Color(0xFFE2E7FF),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: results.map(
                  (patient) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFFDAE1FF),
                        child: Text(
                          patient.fullName
                                  .isEmpty
                              ? 'م'
                              : patient.fullName
                                  .characters
                                  .first,
                          style: const TextStyle(
                            color: Color(0xFF0050CB),
                          ),
                        ),
                      ),
                      title: Text(
                        patient.fullName,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'رقم الهوية: ${patient.nationalId}',
                      ),
                      onTap: () {
                        setState(() {
                          _selectedPatient =
                              patient;
                          _patientSearch =
                              patient.fullName;
                        });
                      },
                    );
                  },
                ).toList(),
              ),
            ),
          ],
          if (_selectedPatient != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF0050CB),
                    foregroundColor: Colors.white,
                    child: Text(
                      _selectedPatient!
                              .fullName.isEmpty
                          ? 'م'
                          : _selectedPatient!
                              .fullName
                              .characters
                              .first,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPatient!.fullName,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'الهوية: ${_selectedPatient!.nationalId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color:
                                Color(0xFF727687),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPatient = null;
                        _patientSearch = '';
                      });
                    },
                    child: const Text('تغيير'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorSection() {
    final doctors =
        context.watch<DoctorProvider>().activeDoctors;

    return _section(
      number: '2',
      title: 'اختيار الطبيب',
      child: doctors.isEmpty
          ? const Text(
              'لا يوجد أطباء نشطون.',
              style: TextStyle(
                color: Color(0xFF727687),
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: doctors.map(
                (doctor) {
                  final selected =
                      _selectedDoctor?.id ==
                          doctor.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDoctor = doctor;
                        _selectedSlot = null;
                      });
                    },
                    borderRadius:
                        BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 180),
                      width: 205,
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFDAE1FF)
                            : const Color(0xFFF2F3FF),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF0050CB)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor:
                                selected
                                    ? const Color(
                                        0xFF0050CB,
                                      )
                                    : const Color(
                                        0xFFDAE2FD,
                                      ),
                            foregroundColor:
                                selected
                                    ? Colors.white
                                    : const Color(
                                        0xFF355C83,
                                      ),
                            child: Text(
                              doctor.fullName
                                      .isEmpty
                                  ? 'د'
                                  : doctor.fullName
                                      .characters
                                      .first,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'د. ${doctor.fullName}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: selected
                                        ? const Color(
                                            0xFF0050CB,
                                          )
                                        : const Color(
                                            0xFF131B2E,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doctor.specialty,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color:
                                        Color(0xFF727687),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF0050CB),
                              size: 19,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _buildDateAndDuration() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _section(
            number: '3',
            title: 'تاريخ الموعد',
            child: InkWell(
              onTap: _pickDate,
              borderRadius:
                  BorderRadius.circular(9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF0050CB),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _formatDateArabic(
                          _selectedDate,
                        ),
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: Color(0xFF727687),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _section(
            number: '4',
            title: 'مدة الموعد',
            child: DropdownButtonFormField<int>(
              initialValue: _duration,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    const Color(0xFFF2F3FF),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 30,
                  child: Text('30 دقيقة'),
                ),
                DropdownMenuItem(
                  value: 45,
                  child: Text('45 دقيقة'),
                ),
                DropdownMenuItem(
                  value: 60,
                  child: Text('60 دقيقة'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _duration = value;
                  _selectedSlot = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsSection() {
    final slots = _availableSlots();

    final schedule = _selectedDoctor == null
        ? null
        : _getScheduleForDate(
            _selectedDoctor!,
            _selectedDate,
          );

    return _section(
      number: '5',
      title: 'الأوقات المتاحة للطبيب',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          if (_selectedDoctor == null)
            const Text(
              'اختر الطبيب أولاً.',
              style: TextStyle(
                color: Color(0xFF727687),
              ),
            )
          else if (schedule == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                'الطبيب غير متاح يوم ${_weekdayArabic(_selectedDate)}.',
                style: const TextStyle(
                  color: Color(0xFF8A5A00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                'جدول الطبيب: ${schedule.startTime} - ${schedule.endTime}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF424656),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (slots.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'لا توجد أوقات متاحة بهذا اليوم والمدة المحددة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF727687),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map(
                  (slot) {
                    final selected =
                        _selectedSlot == slot;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSlot = slot;
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 150,
                        ),
                        width: 115,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF0066FF)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? const Color(
                                    0xFF0066FF,
                                  )
                                : const Color(
                                    0xFFE2E7FF,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(slot),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(
                                        0xFF131B2E,
                                      ),
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _section(
      number: null,
      title: 'ملاحظات',
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              'أدخل أي ملاحظات خاصة بالموعد...',
          filled: true,
          fillColor: const Color(0xFFF2F3FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _section({
    String? number,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (number != null) ...[
              Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFFDAE1FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0050CB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131B2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        child,
      ],
    );
  }

  Widget _buildStatusSection() {
    return _section(
      number: '6',
      title: 'خيار ونوع الحجز',
      child: Row(
        children: [
          Expanded(
            child: _statusChoiceCard(
              title: 'حجز مؤكد',
              subtitle: 'تثبيت الموعد مباشرة كحجز مؤكد',
              icon: Icons.check_circle_outline_rounded,
              status: AppointmentStatus.confirmed,
              activeColor: const Color(0xFF0066FF),
              activeBg: const Color(0xFFE2E7FF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _statusChoiceCard(
              title: 'قيد الانتظار',
              subtitle: 'حفظ الموعد كـ قيد الانتظار للتأكيد لاحقاً',
              icon: Icons.hourglass_top_rounded,
              status: AppointmentStatus.pending,
              activeColor: const Color(0xFFD97706),
              activeBg: const Color(0xFFFEF3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppointmentStatus status,
    required Color activeColor,
    required Color activeBg,
  }) {
    final selected = _bookingStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _bookingStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? activeBg.withValues(alpha: 0.4) : const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE2E7FF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? activeBg : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? activeColor : const Color(0xFF727687),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF131B2E) : const Color(0xFF424656),
                    ),
                  ),
                  const SizedBox(height: 2),
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
            if (selected)
              Icon(
                Icons.radio_button_checked_rounded,
                color: activeColor,
                size: 20,
              )
            else
              const Icon(
                Icons.radio_button_off_rounded,
                color: Color(0xFFC2C6D8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E7FF),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  const Color(0xFF424656),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
            ),
            child: const Text('إلغاء'),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _saveAppointment(AppointmentStatus.pending),
            icon: const Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: Color(0xFFD97706),
            ),
            label: const Text(
              'قيد الانتظار',
              style: TextStyle(
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFFDE68A),
                width: 1.4,
              ),
              backgroundColor: const Color(0xFFFEF3C7),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _saveAppointment(AppointmentStatus.confirmed),
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              size: 19,
              color: Colors.white,
            ),
            label: const Text(
              'حجز مؤكد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(9),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }
}