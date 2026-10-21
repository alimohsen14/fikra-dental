import 'package:flutter/material.dart';

/// Placeholder for the upcoming Debt page.
///
/// Receives the outstanding balance transferred from the Treatment Payment
/// screen so the future implementation can create the debt records. No new
/// architecture is introduced here — it only carries the data forward.
class DebtScreen extends StatelessWidget {
  final String patientId;
  final List<String> treatmentIds;
  final double amount;

  const DebtScreen({
    super.key,
    required this.patientId,
    required this.treatmentIds,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        appBar: AppBar(
          title: const Text('الديون'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF131B2E),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 56,
                color: Color(0xFF0050CB),
              ),
              const SizedBox(height: 16),
              const Text(
                'صفحة الديون قيد الإنشاء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'المبلغ المراد تحويله إلى الديون: '
                '${amount.toStringAsFixed(2)} ₪',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF727687),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
