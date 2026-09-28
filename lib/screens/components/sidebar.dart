import 'package:flutter/material.dart';

import '../account_screen.dart';
import '../patients_screen.dart';

class Sidebar extends StatelessWidget {
  final String activeRoute;

  const Sidebar({
    super.key,
    this.activeRoute = 'patients',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(-1, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),

          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'lib/assets/logo.JPG',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FikraDental',
                            style: TextStyle(
                              color: Color(0xFF0050CB),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'FikraDental',
                            style: TextStyle(
                              color: Color(0xFF727687),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'عيادة الأسنان',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF424656),
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C1FD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _sidebarItem(
                  icon: Icons.grid_view_rounded,
                  title: 'الرئيسية / لوحة التحكم',
                  active: false,
                ),
                _sidebarItem(
                  icon: Icons.groups_rounded,
                  title: 'سجل المرضى',
                  active: activeRoute == 'patients',
                  onTap: () {
                    if (activeRoute != 'patients') {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const PatientsScreen(),
                        ),
                      );
                    }
                  },
                ),
                _sidebarItem(
                  icon: Icons.calendar_month_rounded,
                  title: 'المواعيد والتقويم',
                  active: false,
                ),
                _sidebarItem(
                  icon: Icons.medical_services_outlined,
                  title: 'العلاجات والأسنان',
                  active: false,
                ),
                _sidebarItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'الفواتير والمدفوعات',
                  active: false,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _sidebarItem(
                  icon: Icons.manage_accounts_outlined,
                  title: 'الحساب',
                  active: activeRoute == 'account',
                  onTap: () {
                    if (activeRoute != 'account') {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFF006688),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الدعم الفني الطبي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF131B2E),
                              ),
                            ),
                            Text(
                              'متصل 24/7',
                              style: TextStyle(
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    required bool active,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: active
            ? const Color(0xFF0066FF)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            size: 21,
            color: active
                ? Colors.white
                : const Color(0xFF424656),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : const Color(0xFF424656),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
