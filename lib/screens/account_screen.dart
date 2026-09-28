import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/doctor_provider.dart';
import '../providers/account_provider.dart';
import 'components/sidebar.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _usernameController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadDoctors();
      context.read<AccountProvider>().loadAccount();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        body: Row(
          children: [
            const Sidebar(activeRoute: 'account'),

            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 1520,
                          ),
                          child: Column(
                            children: [
                              _buildPageHeader(),
                              const SizedBox(height: 24),
                              _buildDoctorsSection(),
                              const SizedBox(height: 24),
                              _buildAccountAndBackup(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF).withValues(alpha: 0.92),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B3B60),
            blurRadius: 8,
            offset: Offset(0, 1),
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
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: Color(0xFF00C1FD),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'نظام إدارة العيادة • متصل',
                      style: TextStyle(
                        color: Color(0xFF006688),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.today,
                      size: 16,
                      color: Color(0xFF424656),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'اليوم',
                      style: TextStyle(
                        color: Color(0xFF424656),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080B3B60),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 21,
                        color: Color(0xFF424656),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFE2E7FF),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF0050CB),
                        size: 19,
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدير النظام',
                          style: TextStyle(
                            color: Color(0xFF131B2E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'إدارة العيادة',
                          style: TextStyle(
                            color: Color(0xFF727687),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B3B60),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF0050CB),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحساب والإعدادات',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'إدارة الكادر الطبي، وتأمين حساب النظام والنسخ الاحتياطي.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF424656),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              _quickTab('إدارة الأطباء', true),
              const SizedBox(width: 4),
              _quickTab('الحساب والأمان', false),
              const SizedBox(width: 4),
              _quickTab('النسخ الاحتياطي', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTab(String title, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.white
            : const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 3,
                ),
              ]
            : null,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: active
              ? const Color(0xFF0050CB)
              : const Color(0xFF424656),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // DOCTORS
  // ============================================================

  Widget _buildDoctorsSection() {
    return Consumer<DoctorProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080B3B60),
                blurRadius: 3,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildDoctorsHeader(provider),
              _buildDoctorsTable(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorsHeader(DoctorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF2F3FF).withValues(alpha: 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0050CB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF0050CB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'إدارة الأطباء',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF131B2E),
                            ),
                          ),
                          _badge(
                            '${provider.doctorCount} أطباء مسجلين',
                            const Color(0xFFDAE1FF),
                            const Color(0xFF003FA4),
                          ),
                          _badge(
                            '${provider.activeDoctorCount} نشطين',
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                            dot: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'إدارة بيانات الأطباء وجدولة أوقات العمل داخل العيادة.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424656),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showDoctorDialog(),
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('إضافة طبيب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0050CB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
    String text,
    Color background,
    Color foreground, {
    bool dot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsTable(DoctorProvider provider) {
    if (provider.doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: Text(
            'لا يوجد أطباء مسجلون حالياً',
            style: TextStyle(
              color: Color(0xFF727687),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTableWidth = 1000;
        final double tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFEAEDFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 28,
                        child: Text(
                          'اسم الطبيب والتخصص',
                          style: TextStyle(
                            color: Color(0xFF424656),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 15,
                        child: Text(
                          'رقم الهاتف',
                          style: TextStyle(
                            color: Color(0xFF424656),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 20,
                        child: Text(
                          'أيام العمل',
                          style: TextStyle(
                            color: Color(0xFF424656),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 22,
                        child: Text(
                          'ساعات الدوام',
                          style: TextStyle(
                            color: Color(0xFF424656),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 15,
                        child: Text(
                          'الحالة',
                          style: TextStyle(
                            color: Color(0xFF424656),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 84,
                        child: Text(
                          'الإجراءات',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color(0xFF424656),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ...provider.doctors.map(
                  (doctor) => _buildDoctorRow(doctor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorRow(Doctor doctor) {
    final schedules = doctor.schedules
        .where((schedule) => schedule.isWorking)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E7FF),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 28,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: doctor.isActive
                        ? const Color(0xFFE2E7FF)
                        : const Color(0xFFEAEDFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: doctor.isActive
                        ? const Color(0xFF0050CB)
                        : const Color(0xFF727687),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF131B2E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF006688),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                doctor.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF424656),
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 20,
            child: Text(
              _workingDaysText(schedules),
              style: const TextStyle(
                color: Color(0xFF424656),
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 22,
            child: _workingHoursWidget(schedules),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 15,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: doctor.isActive,
                  onChanged: (_) {
                    context
                        .read<DoctorProvider>()
                        .toggleDoctorStatus(doctor.id);
                  },
                  activeThumbColor: const Color(0xFF0050CB),
                ),
                const SizedBox(width: 4),
                _statusBadge(doctor.isActive),
              ],
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'تعديل الطبيب',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    _showDoctorDialog(doctor: doctor);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: Color(0xFF424656),
                  ),
                ),
                IconButton(
                  tooltip: 'حذف الطبيب',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    _confirmDeleteDoctor(doctor);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFECFDF5)
            : const Color(0xFFE2E7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'نشط' : 'معطل',
        style: TextStyle(
          color: active
              ? const Color(0xFF047857)
              : const Color(0xFF727687),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _workingDaysText(List<DoctorSchedule> schedules) {
    if (schedules.isEmpty) {
      return 'لا يوجد دوام';
    }

    return schedules
        .map(_dayName)
        .join(' - ');
  }

  Widget _workingHoursWidget(List<DoctorSchedule> schedules) {
    if (schedules.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: Color(0xFF727687)),
      );
    }

    if (schedules.length == 1) {
      return _timeChip(
        '${schedules.first.startTime} - ${schedules.first.endTime}',
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: schedules.map((schedule) {
        return _timeChip(
          '${_shortDayName(schedule.day)}: '
          '${schedule.startTime} - ${schedule.endTime}',
        );
      }).toList(),
    );
  }

  Widget _timeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF131B2E),
          fontSize: 10,
        ),
      ),
    );
  }

  String _shortDayName(WeekDay day) {
    switch (day) {
      case WeekDay.saturday:
        return 'سبت';
      case WeekDay.sunday:
        return 'أحد';
      case WeekDay.monday:
        return 'اثن';
      case WeekDay.tuesday:
        return 'ثلا';
      case WeekDay.wednesday:
        return 'أرب';
      case WeekDay.thursday:
        return 'خمي';
      case WeekDay.friday:
        return 'جمع';
    }
  }

  String _dayName(DoctorSchedule schedule) {
    switch (schedule.day) {
      case WeekDay.saturday:
        return 'السبت';
      case WeekDay.sunday:
        return 'الأحد';
      case WeekDay.monday:
        return 'الاثنين';
      case WeekDay.tuesday:
        return 'الثلاثاء';
      case WeekDay.wednesday:
        return 'الأربعاء';
      case WeekDay.thursday:
        return 'الخميس';
      case WeekDay.friday:
        return 'الجمعة';
    }
  }

  // ============================================================
  // ACCOUNT + BACKUP
  // ============================================================

  Widget _buildAccountAndBackup() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildAccountSecurity(),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildBackupSection(),
        ),
      ],
    );
  }

  Widget _buildAccountSecurity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B3B60),
            blurRadius: 3,
          ),
        ],
      ),
      child: Consumer<AccountProvider>(
        builder: (context, provider, _) {
          final account = provider.account;

          if (account != null &&
              _usernameController.text.isEmpty) {
            _usernameController.text = account.username;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                icon: Icons.shield_outlined,
                title: 'الحساب والأمان',
                subtitle: 'إدارة بيانات الدخول وتأمين حساب النظام.',
                color: const Color(0xFF355C83),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0050CB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFF0050CB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اسم المستخدم النشط',
                            style: TextStyle(
                              color: Color(0xFF727687),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            account?.username ?? '—',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Color(0xFF131B2E),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _textField(
                controller: _usernameController,
                label: 'اسم المستخدم',
                hint: 'أدخل اسم المستخدم',
                icon: Icons.person_outline,
                textDirection: TextDirection.ltr,
              ),

              const SizedBox(height: 14),

              _passwordField(
                controller: _currentPasswordController,
                label: 'كلمة المرور الحالية',
                obscure: _obscureCurrent,
                onToggle: () {
                  setState(() {
                    _obscureCurrent = !_obscureCurrent;
                  });
                },
              ),

              const SizedBox(height: 14),

              _passwordField(
                controller: _newPasswordController,
                label: 'كلمة المرور الجديدة',
                hint: 'أدخل كلمة المرور الجديدة',
                obscure: _obscureNew,
                onToggle: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),

              const SizedBox(height: 14),

              _passwordField(
                controller: _confirmPasswordController,
                label: 'تأكيد كلمة المرور الجديدة',
                hint: 'أعد كتابة كلمة المرور للتأكيد',
                obscure: _obscureConfirm,
                onToggle: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateAccount(),
                  icon: const Icon(
                    Icons.lock_reset,
                    size: 20,
                  ),
                  label: const Text('تحديث الحساب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0050CB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackupSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B3B60),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.cloud_sync_outlined,
            title: 'النسخ الاحتياطي واستعادة البيانات',
            subtitle: 'حماية بيانات النظام والمرضى محلياً.',
            color: const Color(0xFF0050CB),
          ),

          const SizedBox(height: 18),

          _backupCard(
            icon: Icons.cloud_upload_outlined,
            title: 'إنشاء نسخة احتياطية',
            description:
                'إنشاء نسخة احتياطية من بيانات النظام المحلية.',
            buttonText: 'إنشاء نسخة احتياطية',
            buttonIcon: Icons.download_for_offline,
            primary: true,
            onPressed: () {
              _showComingSoon('النسخ الاحتياطي');
            },
          ),

          const SizedBox(height: 14),

          _backupCard(
            icon: Icons.settings_backup_restore,
            title: 'استعادة نسخة سابقة',
            description:
                'اختر ملف نسخة احتياطية لاستعادة بيانات النظام.',
            buttonText: 'بدء الاستعادة',
            buttonIcon: Icons.restore,
            primary: false,
            onPressed: () {
              _showComingSoon('استعادة النسخة الاحتياطية');
            },
          ),
        ],
      ),
    );
  }

  Widget _backupCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required IconData buttonIcon,
    required bool primary,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary
                      ? const Color(0xFF0050CB).withValues(alpha: 0.1)
                      : const Color(0xFF006688).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: primary
                      ? const Color(0xFF0050CB)
                      : const Color(0xFF006688),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF131B2E),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF424656),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 19),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary
                    ? const Color(0xFF0050CB)
                    : const Color(0xFFE2E7FF),
                foregroundColor: primary
                    ? Colors.white
                    : const Color(0xFF131B2E),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF131B2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF424656),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DOCTOR DIALOG
  // ============================================================

  void _showDoctorDialog({Doctor? doctor}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DoctorDialog(doctor: doctor),
    );
  }

  void _confirmDeleteDoctor(Doctor doctor) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف الطبيب'),
          content: Text(
            'هل أنت متأكد من حذف ${doctor.fullName}؟\n'
            'سيتم حذف بيانات الطبيب نهائياً.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context
                    .read<DoctorProvider>()
                    .deleteDoctor(doctor.id);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAccount() async {
    final accountProvider = context.read<AccountProvider>();

    final username = _usernameController.text.trim();
    final currentPassword =
        _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    if (username.isEmpty) {
      _showMessage('يرجى إدخال اسم المستخدم.');
      return;
    }

    if (newPassword.isNotEmpty) {
      if (currentPassword.isEmpty) {
        _showMessage('يرجى إدخال كلمة المرور الحالية.');
        return;
      }

      if (newPassword != confirmPassword) {
        _showMessage('كلمتا المرور الجديدتان غير متطابقتين.');
        return;
      }

      await accountProvider.changePassword(
        currentPassword,
        newPassword,
      );
    }

    await accountProvider.changeUsername(username);

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    if (!mounted) return;

    _showMessage('تم تحديث بيانات الحساب بنجاح.');
  }

  void _showComingSoon(String feature) {
    _showMessage('$feature ستكون متاحة عند تنفيذ الخدمة.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // FORM HELPERS
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF131B2E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textDirection: textDirection,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(
              icon,
              size: 19,
              color: const Color(0xFF727687),
            ),
            filled: true,
            fillColor: const Color(0xFFF2F3FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF00C1FD),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF131B2E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFFAF8FF),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF00C1FD),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =================================================================
// DOCTOR DIALOG
// =================================================================

class _DoctorDialog extends StatefulWidget {
  final Doctor? doctor;

  const _DoctorDialog({
    this.doctor,
  });

  @override
  State<_DoctorDialog> createState() => _DoctorDialogState();
}

class _DoctorDialogState extends State<_DoctorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String _specialty = 'طبيب أسنان عام';

  final Map<WeekDay, bool> _workingDays = {};
  final Map<WeekDay, TextEditingController> _startControllers = {};
  final Map<WeekDay, TextEditingController> _endControllers = {};

  final List<String> _specialties = const [
    'طبيب أسنان عام',
    'استشاري جراحة وتجميل الأسنان',
    'أخصائي علاج جذور وأعصاب',
    'تقويم الأسنان والفكين',
    'طب أسنان الأطفال',
    'زراعة الأسنان وأمراض اللثة',
  ];

  final List<WeekDay> _days = const [
    WeekDay.saturday,
    WeekDay.sunday,
    WeekDay.monday,
    WeekDay.tuesday,
    WeekDay.wednesday,
    WeekDay.thursday,
    WeekDay.friday,
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.doctor?.fullName ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.doctor?.phone ?? '',
    );

    if (widget.doctor != null) {
      _specialty = widget.doctor!.specialty;

      for (final schedule in widget.doctor!.schedules) {
        _workingDays[schedule.day] = schedule.isWorking;

        _startControllers[schedule.day] =
            TextEditingController(text: schedule.startTime);

        _endControllers[schedule.day] =
            TextEditingController(text: schedule.endTime);
      }
    }

    for (final day in _days) {
      _workingDays.putIfAbsent(day, () => false);

      _startControllers.putIfAbsent(
        day,
        () => TextEditingController(text: '09:00'),
      );

      _endControllers.putIfAbsent(
        day,
        () => TextEditingController(text: '17:00'),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    for (final controller in _startControllers.values) {
      controller.dispose();
    }

    for (final controller in _endControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doctor != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 650,
          constraints: const BoxConstraints(
            maxHeight: 760,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x400B3B60),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDialogHeader(isEditing),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildBasicFields(),
                      const SizedBox(height: 20),
                      _buildScheduleSection(),
                    ],
                  ),
                ),
              ),
              _buildDialogActions(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF2F3FF),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0050CB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_add,
              color: Color(0xFF0050CB),
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'تعديل بيانات الطبيب'
                      : 'إضافة طبيب جديد للكادر',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'تسجيل بيانات الطبيب وتحديد أوقات العمل لكل يوم.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF424656),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return _dialogTextField(
      label: 'اسم الطبيب الكامل',
      controller: _nameController,
      hint: 'مثال: د. ماجد السالم',
    );
  }

  Widget _buildBasicFields() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _specialty,
            decoration: _inputDecoration('التخصص السريري'),
            items: _specialties.map((specialty) {
              return DropdownMenuItem(
                value: specialty,
                child: Text(
                  specialty,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _specialty = value;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _dialogTextField(
            label: 'رقم الهاتف الجوال',
            controller: _phoneController,
            hint: '059 xxx xxxx',
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أوقات العمل',
          style: TextStyle(
            color: Color(0xFF131B2E),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'حدد أيام العمل ثم عيّن وقت البداية والنهاية لكل يوم بشكل مستقل.',
          style: TextStyle(
            color: Color(0xFF727687),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),

        ..._days.map(
          (day) => _buildDayRow(day),
        ),
      ],
    );
  }

  Widget _buildDayRow(WeekDay day) {
    final enabled = _workingDays[day] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFFF2F3FF)
            : const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? const Color(0xFFDAE2FD)
              : const Color(0xFFE2E7FF),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: CheckboxListTile(
              value: enabled,
              onChanged: (value) {
                setState(() {
                  _workingDays[day] = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                _fullDayName(day),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: 'من',
                    controller: _startControllers[day]!,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeField(
                    label: 'إلى',
                    controller: _endControllers[day]!,
                    enabled: enabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF727687),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled
                  ? Colors.white
                  : const Color(0xFFE2E7FF),
              hintText: '09:00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF131B2E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          textDirection: textDirection,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF2F3FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF00C1FD),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
    );
  }

  Widget _buildDialogActions(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E7FF),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saveDoctor,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0050CB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isEditing ? 'حفظ التعديلات' : 'حفظ الطبيب',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDoctor() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم الطبيب.');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('يرجى إدخال رقم الهاتف.');
      return;
    }

    final schedules = <DoctorSchedule>[];

    for (final day in _days) {
      if (_workingDays[day] == true) {
        schedules.add(
          DoctorSchedule(
            day: day,
            startTime: _startControllers[day]!.text.trim(),
            endTime: _endControllers[day]!.text.trim(),
            isWorking: true,
          ),
        );
      }
    }

    if (schedules.isEmpty) {
      _showError('يرجى اختيار يوم عمل واحد على الأقل.');
      return;
    }

    final doctor = Doctor(
      id: widget.doctor?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: _nameController.text.trim(),
      specialty: _specialty,
      phone: _phoneController.text.trim(),
      schedules: schedules,
      isActive: widget.doctor?.isActive ?? true,
      createdAt: widget.doctor?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<DoctorProvider>();

    if (widget.doctor == null) {
      await provider.addDoctor(doctor);
    } else {
      await provider.updateDoctor(doctor);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _fullDayName(WeekDay day) {
    switch (day) {
      case WeekDay.saturday:
        return 'السبت';
      case WeekDay.sunday:
        return 'الأحد';
      case WeekDay.monday:
        return 'الاثنين';
      case WeekDay.tuesday:
        return 'الثلاثاء';
      case WeekDay.wednesday:
        return 'الأربعاء';
      case WeekDay.thursday:
        return 'الخميس';
      case WeekDay.friday:
        return 'الجمعة';
    }
  }
}