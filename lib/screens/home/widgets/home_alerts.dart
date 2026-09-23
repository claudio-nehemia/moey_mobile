import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../utils/constant.dart';

class HomeAlerts extends StatelessWidget {
  final User? currentUser;

  const HomeAlerts({
    super.key,
    required this.currentUser,
  });

  Widget _buildAlertCard({
    required String title,
    required String message,
    required int daysLeft,
    required Color stripeColor,
    required IconData icon,
  }) {
    String deadlineText = '';
    Color deadlineColor = Constants.textMedium;
    if (daysLeft == 0) {
      deadlineText = 'Hari ini!';
      deadlineColor = Constants.errorColor;
    } else if (daysLeft < 0) {
      deadlineText = 'Terlewat ${daysLeft.abs()} hari!';
      deadlineColor = Constants.errorColor;
    } else {
      deadlineText = '$daysLeft hari lagi';
      deadlineColor = daysLeft <= 2 ? Constants.errorColor : Constants.successColor;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: stripeColor.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripeColor, width: 6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stripeColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: stripeColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Constants.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: deadlineColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: deadlineColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Constants.textDark,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
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

  @override
  Widget build(BuildContext context) {
    final overdueAlert = currentUser?.overdueTask;
    final taskAlert = currentUser?.nearestTask;
    final paymentAlert = currentUser?.nearestPayment;
    final isLegalAdmin = currentUser?.isLegalAdmin == true;

    if (overdueAlert == null && taskAlert == null && (paymentAlert == null || !isLegalAdmin)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdueAlert != null) ...[
          _buildAlertCard(
            title: 'Peringatan Tugas Terlambat',
            message: overdueAlert['message'] ?? '',
            daysLeft: (overdueAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.errorColor,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 12),
        ],
        if (taskAlert != null) ...[
          _buildAlertCard(
            title: 'Info Tugas Terdekat',
            message: taskAlert['message'] ?? '',
            daysLeft: (taskAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.accentColor,
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (isLegalAdmin && paymentAlert != null) ...[
          _buildAlertCard(
            title: 'Remind Pembayaran',
            message: paymentAlert['message'] ?? '',
            daysLeft: (paymentAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.financeColor,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
