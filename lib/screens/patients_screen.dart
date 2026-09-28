import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient.dart';
import '../providers/patient_provider.dart';
import 'components/sidebar.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _genderFilter = 'all';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        body: Consumer<PatientProvider>(
          builder: (context, provider, child) {
            final patients = _getFilteredPatients(provider);

            return Row(
              children: [
                const Sidebar(),
                Expanded(
                  child: _buildMainContent(
                    context,
                    provider,
                    patients,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Patient> _getFilteredPatients(PatientProvider provider) {
    if (_genderFilter == 'all') {
      return provider.filteredPatients;
    }

    if (_genderFilter == 'male') {
      return provider.filteredPatients
          .where((patient) => patient.genderEnum == Gender.male)
          .toList();
    }

    if (_genderFilter == 'female') {
      return provider.filteredPatients
          .where((patient) => patient.genderEnum == Gender.female)
          .toList();
    }

    return provider.filteredPatients;
  }

  Widget _buildMainContent(
    BuildContext context,
    PatientProvider provider,
    List<Patient> patients,
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
                _buildPageHeader(context, provider),
                const SizedBox(height: 24),

                _buildStatistics(provider),
                const SizedBox(height: 24),

                _buildSearchAndFilters(provider),
                const SizedBox(height: 20),

                _buildPatientsTable(
                  context,
                  provider,
                  patients,
                ),
              ],
            ),
          ),
        ),
      ],
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
                      'نظام إدارة العيادة • متصل',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF006688),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.today_outlined,
                      size: 16,
                      color: Color(0xFF424656),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'اليوم',
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

          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF424656),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
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

              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFDAE1FF),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF0050CB),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'د. الطبيب',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'طبيب أسنان',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF727687),
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

  Widget _buildPageHeader(
    BuildContext context,
    PatientProvider provider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'إدارة سجلات المرضى',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _patientCountBadge(provider.count),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'عرض وإدارة السجلات الطبية والملفات الشخصية وتواريخ المواعيد بنظام الربط السريري المباشر.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),

        Row(
          children: [
            _secondaryActionButton(
              icon: Icons.file_download_outlined,
              title: 'تصدير تقرير',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _secondaryActionButton(
              icon: Icons.tune_rounded,
              title: 'تصفية متقدمة',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _primaryButton(
              icon: Icons.person_add_alt_1_rounded,
              title: 'إضافة مريض',
              onTap: () {
                _showPatientDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _patientCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF0066FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'إجمالي المرضى:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF0050CB),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0050CB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF424656),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF0066FF),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0050CB),
                Color(0xFF0066FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(PatientProvider provider) {
    final now = DateTime.now();

    final newThisMonth = provider.patients.where((patient) {
      return patient.createdAt.year == now.year &&
          patient.createdAt.month == now.month;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'المرضى النشطون اليوم',
            value: '—',
            subtitle: 'سيتم ربطها بالمواعيد لاحقاً',
            icon: Icons.airline_seat_recline_extra_rounded,
            iconColor: const Color(0xFF0050CB),
            iconBackground: const Color(0xFFEAEDFF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: 'مرضى جدد هذا الشهر',
            value: '$newThisMonth',
            subtitle: 'سجل جديد',
            icon: Icons.group_add_rounded,
            iconColor: const Color(0xFF006688),
            iconBackground: const Color(0xFFC2E8FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: 'مواعيد اليوم القادمة',
            value: '—',
            subtitle: 'سيتم ربطها بالمواعيد لاحقاً',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF355C83),
            iconBackground: const Color(0xFFDAE2FD),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF727687),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF006688),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 27,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(PatientProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText:
                    'ابحث بالاسم الكامل، رقم الهوية، أو رقم الهاتف...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF727687),
                ),
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          _filterButton(
            title: 'جميع المرضى',
            active: _genderFilter == 'all',
            onTap: () {
              setState(() {
                _genderFilter = 'all';
              });
            },
          ),
          const SizedBox(width: 6),

          _filterButton(
            title: 'ذكور',
            active: _genderFilter == 'male',
            onTap: () {
              setState(() {
                _genderFilter = 'male';
              });
            },
          ),
          const SizedBox(width: 6),

          _filterButton(
            title: 'إناث',
            active: _genderFilter == 'female',
            onTap: () {
              setState(() {
                _genderFilter = 'female';
              });
            },
          ),

          const SizedBox(width: 10),

          Container(
            width: 1,
            height: 25,
            color: const Color(0xFFE2E7FF),
          ),

          const SizedBox(width: 10),

          const Row(
            children: [
              Text(
                'ترتيب: الأحدث إضافة',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF727687),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Color(0xFF727687),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? const Color(0xFF0050CB)
          : const Color(0xFFF2F3FF),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 7,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active
                  ? Colors.white
                  : const Color(0xFF424656),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsTable(
    BuildContext context,
    PatientProvider provider,
    List<Patient> patients,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              12,
            ),
            child: Row(
              children: [
                const Text(
                  'سجل المرضى',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${patients.length} مريض',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF727687),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: Color(0xFFEAEDFF),
          ),

          if (patients.isEmpty)
            _buildEmptyPatients()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF2F3FF),
                ),
                dataRowMinHeight: 72,
                dataRowMaxHeight: 80,
                columnSpacing: 30,
                horizontalMargin: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      'المريض',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'رقم الهوية',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'العمر والميلاد',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الجنس',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'رقم الهاتف',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'آخر زيارة',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'الإجراءات',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424656),
                      ),
                    ),
                  ),
                ],
                rows: patients.map((patient) {
                  return _buildPatientRow(
                    context,
                    provider,
                    patient,
                  );
                }).toList(),
              ),
            ),

          _buildPagination(patients.length),
        ],
      ),
    );
  }

  DataRow _buildPatientRow(
    BuildContext context,
    PatientProvider provider,
    Patient patient,
  ) {
    final isMale = patient.genderEnum == Gender.male;

    final firstLetter = patient.fullName.isNotEmpty
        ? patient.fullName.substring(0, 1)
        : '?';

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 210,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isMale
                        ? const Color(0xFFC2E8FF)
                        : const Color(0xFFDAE1FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    firstLetter,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isMale
                          ? const Color(0xFF006688)
                          : const Color(0xFF0050CB),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ملف: ${patient.id.substring(0, patient.id.length > 8 ? 8 : patient.id.length)}',
                        style: const TextStyle(
                          fontSize: 10,
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

        DataCell(
          Text(
            patient.nationalId,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF424656),
            ),
          ),
        ),

        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${patient.age} سنة',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatDate(patient.dateOfBirth),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF727687),
                ),
              ),
            ],
          ),
        ),

        DataCell(
          _genderBadge(patient.genderEnum),
        ),

        DataCell(
          Text(
            patient.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF424656),
            ),
          ),
        ),

        DataCell(
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF0066FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                '—',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF727687),
                ),
              ),
            ],
          ),
        ),

        DataCell(
          Row(
            children: [
              _tableActionButton(
                icon: Icons.medical_services_outlined,
                tooltip: 'عرض الملف السريري',
                color: const Color(0xFF0050CB),
                onTap: () {},
              ),
              const SizedBox(width: 5),
              _tableActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'تعديل السجل',
                onTap: () {
                  _showPatientDialog(
                    context,
                    patient: patient,
                  );
                },
              ),
              const SizedBox(width: 5),
              _tableActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'حذف المريض',
                onTap: () {
                  _confirmDelete(
                    context,
                    provider,
                    patient,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderBadge(Gender? gender) {
    final isMale = gender == Gender.male;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isMale
            ? const Color(0xFFC2E8FF)
            : const Color(0xFFDAE2FD),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isMale
                  ? const Color(0xFF006688)
                  : const Color(0xFF0050CB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isMale ? 'ذكر' : 'أنثى',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isMale
                  ? const Color(0xFF004D67)
                  : const Color(0xFF0050CB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableActionButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 18,
              color: color ?? const Color(0xFF424656),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPatients() {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60,
            color: Color(0xFF727687),
          ),
          SizedBox(height: 12),
          Text(
            'لا يوجد مرضى',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF131B2E),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'ابدأ بإضافة أول مريض إلى النظام.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF727687),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'عرض $count من المرضى',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF727687),
            ),
          ),
          const Spacer(),
          _paginationButton(
            icon: Icons.chevron_right,
            enabled: false,
          ),
          const SizedBox(width: 5),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0050CB),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 5),
          _paginationButton(
            icon: Icons.chevron_left,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled
            ? const Color(0xFF424656)
            : const Color(0xFFB8BBC5),
      ),
    );
  }

  Future<void> _showPatientDialog(
    BuildContext context, {
    Patient? patient,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _PatientFormDialog(
          patient: patient,
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PatientProvider provider,
    Patient patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المريض'),
          content: Text(
            'هل أنت متأكد من حذف سجل "${patient.fullName}"؟\n'
            'هذا الحذف نهائي ولا يوجد أرشفة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await provider.deletePatient(patient.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف سجل المريض'),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _PatientFormDialog extends StatefulWidget {
  final Patient? patient;

  const _PatientFormDialog({
    this.patient,
  });

  @override
  State<_PatientFormDialog> createState() =>
      _PatientFormDialogState();
}

class _PatientFormDialogState
    extends State<_PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  DateTime? _dateOfBirth;
  Gender _gender = Gender.male;
  bool _saving = false;

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();

    final patient = widget.patient;

    _nameController = TextEditingController(
      text: patient?.fullName ?? '',
    );

    _nationalIdController = TextEditingController(
      text: patient?.nationalId ?? '',
    );

    _phoneController = TextEditingController(
      text: patient?.phone ?? '',
    );

    _addressController = TextEditingController(
      text: patient?.address ?? '',
    );

    _notesController = TextEditingController(
      text: patient?.notes ?? '',
    );

    _dateOfBirth = patient?.dateOfBirth;
    _gender = patient?.genderEnum ?? Gender.male;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _calculatedAge {
    final dob = _dateOfBirth;

    if (dob == null) {
      return null;
    }

    final today = DateTime.now();

    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month &&
            today.day < dob.day)) {
      age--;
    }

    return age;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'اختر تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (selected != null) {
      setState(() {
        _dateOfBirth = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تاريخ الميلاد'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final provider = context.read<PatientProvider>();

    try {
      if (_isEditing) {
        final oldPatient = widget.patient!;

        final updatedPatient = oldPatient.copyWith(
          fullName: _nameController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          dateOfBirth: _dateOfBirth!,
          gender: _gender.toStorageValue(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
        );

        await provider.updatePatient(updatedPatient);
      } else {
        final now = DateTime.now();

        final patient = Patient(
          id: now.microsecondsSinceEpoch.toString(),
          fullName: _nameController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          dateOfBirth: _dateOfBirth!,
          gender: _gender.toStorageValue(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: now,
        );

        await provider.addPatient(patient);
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'تم تحديث بيانات المريض بنجاح'
                  : 'تم إضافة المريض بنجاح',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculatedAge;

    return Dialog(
      insetPadding: const EdgeInsets.all(30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 850,
          maxHeight: 850,
        ),
        child: Column(
          children: [
            _buildDialogHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _nameController,
                              label: 'الاسم الكامل',
                              hint: 'مثال: محمد أحمد',
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _textField(
                              controller: _nationalIdController,
                              label: 'رقم الهوية / الإقامة',
                              hint: 'رقم الهوية',
                              required: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildBirthDateField(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAgeCard(age),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildGenderField(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _textField(
                              controller: _phoneController,
                              label: 'رقم الجوال',
                              hint: '05XXXXXXXX',
                              required: true,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _textField(
                        controller: _addressController,
                        label: 'العنوان ومكان الإقامة',
                        hint: 'مثال: نابلس - ...',
                      ),

                      const SizedBox(height: 18),

                      _textField(
                        controller: _notesController,
                        label:
                            'ملاحظات طبية سريرية وعامة',
                        hint:
                            'الحساسية، الأمراض المزمنة، ملاحظات مهمة...',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _buildDialogFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F3FF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0050CB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEditing
                  ? Icons.edit_rounded
                  : Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'تعديل ملف المريض'
                      : 'إضافة ملف مريض جديد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEditing
                      ? 'تعديل البيانات الأساسية للمريض'
                      : 'يرجى تعبئة البيانات الشخصية لإنشاء سجل المريض',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF424656),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving
                ? null
                : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF131B2E),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: required
              ? (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF727687),
            ),
            filled: true,
            fillColor: const Color(0xFFF2F3FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFF00C1FD),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'تاريخ الميلاد',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 3),
            Text(
              '*',
              style: TextStyle(
                color: Color(0xFFBA1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: Color(0xFF0050CB),
                ),
                const SizedBox(width: 9),
                Text(
                  _dateOfBirth == null
                      ? 'اختر تاريخ الميلاد'
                      : _formatDate(_dateOfBirth!),
                  style: TextStyle(
                    fontSize: 13,
                    color: _dateOfBirth == null
                        ? const Color(0xFF727687)
                        : const Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeCard(int? age) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'العمر المحسوب تلقائياً',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'احتساب ذكي',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF006688),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDAE2FD),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cake_outlined,
                size: 20,
                color: Color(0xFF0050CB),
              ),
              const SizedBox(width: 9),
              Text(
                age == null ? '-- سنة' : '$age سنة',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF131B2E),
                ),
              ),
              const Spacer(),
              Text(
                age == null
                    ? 'اختر تاريخ الميلاد'
                    : 'تم الاحتساب تلقائياً',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF727687),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'يتم احتساب العمر فوراً دون الحاجة لإدخاله يدوياً.',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF424656),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'الجنس',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 3),
            Text(
              '*',
              style: TextStyle(
                color: Color(0xFFBA1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _genderChoice(
                title: 'ذكر',
                icon: Icons.male_rounded,
                gender: Gender.male,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _genderChoice(
                title: 'أنثى',
                icon: Icons.female_rounded,
                gender: Gender.female,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genderChoice({
    required String title,
    required IconData icon,
    required Gender gender,
  }) {
    final active = _gender == gender;

    return Material(
      color: active
          ? const Color(0xFF0050CB)
          : const Color(0xFFF2F3FF),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          setState(() {
            _gender = gender;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active
                    ? Colors.white
                    : const Color(0xFF424656),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : const Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogFooter() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F3FF),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _saving
                ? null
                : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0050CB),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                    size: 18,
                  ),
            label: Text(
              _saving ? 'جارٍ الحفظ...' : 'حفظ المريض',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

extension GenderStorage on Gender {
  String toStorageValue() {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
    }
  }
}