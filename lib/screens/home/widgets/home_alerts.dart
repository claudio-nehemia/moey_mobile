import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../utils/constant.dart';

class HomeAlerts extends StatelessWidget {
  final User? currentUser;
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRegisterFace;
  final Function(int orderId)? onOpenOrder;
  final VoidCallback? onNavigateToNotifications;

  const HomeAlerts({
    super.key,
    required this.currentUser,
    this.dashboardData,
    this.onRegisterFace,
    this.onOpenOrder,
    this.onNavigateToNotifications,
  });

  Widget _buildFaceRegistrationAlert({required VoidCallback? onTap}) {
    const Color stripeColor = Constants.errorColor;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stripeColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: stripeColor.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: stripeColor, width: 6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stripeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: stripeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Wajah Belum Terdaftar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Constants.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stripeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Wajib Absensi',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: stripeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Anda belum mendaftarkan wajah. Segera daftarkan foto wajah Anda agar dapat melakukan absensi presensi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Constants.textDark,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.face_retouching_natural_rounded, size: 16),
                  label: const Text('Daftarkan Wajah Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required int daysLeft,
    required Color stripeColor,
    required IconData icon,
    VoidCallback? onTap,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFaceRegistered = dashboardData == null || (dashboardData!['has_face_registered'] != false);
    final overdueAlert = currentUser?.overdueTask;
    final taskAlert = currentUser?.nearestTask;
    final paymentAlert = currentUser?.nearestPayment;
    final isLegalAdmin = currentUser?.isLegalAdmin == true;

    final bool showFaceAlert = !hasFaceRegistered;
    final bool hasOtherAlerts = overdueAlert != null || taskAlert != null || (paymentAlert != null && isLegalAdmin);

    if (!showFaceAlert && !hasOtherAlerts) {
      return const SizedBox.shrink();
    }

    void handleAlertTap(Map<String, dynamic>? alert) {
      final dynamic rawOrderId = alert?['order_id'];
      final int? orderId = rawOrderId is int ? rawOrderId : int.tryParse(rawOrderId?.toString() ?? '');
      if (orderId != null && onOpenOrder != null) {
        onOpenOrder!(orderId);
      } else if (onNavigateToNotifications != null) {
        onNavigateToNotifications!();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFaceAlert) ...[
          _buildFaceRegistrationAlert(onTap: onRegisterFace),
          const SizedBox(height: 12),
        ],
        if (overdueAlert != null) ...[
          _buildAlertCard(
            title: 'Peringatan Tugas Terlambat',
            message: overdueAlert['message'] ?? '',
            daysLeft: (overdueAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.errorColor,
            icon: Icons.warning_amber_rounded,
            onTap: () => handleAlertTap(overdueAlert),
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
            onTap: () => handleAlertTap(taskAlert),
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
            onTap: () => handleAlertTap(paymentAlert),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
