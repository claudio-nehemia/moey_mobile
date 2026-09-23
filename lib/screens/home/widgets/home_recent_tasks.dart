import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../utils/constant.dart';

class HomeRecentTasks extends StatelessWidget {
  final List<NotificationModel> recentPending;
  final VoidCallback? onNavigateToNotifications;

  const HomeRecentTasks({
    super.key,
    required this.recentPending,
    this.onNavigateToNotifications,
  });

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
      case NotificationModel.typeSurveyScheduleRequest:
        return Constants.surveyColor;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeDesignApproval:
      case NotificationModel.typeFinalDesignRequest:
        return Constants.designColor;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Constants.estimasiColor;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Constants.financeColor;
      case NotificationModel.typeKontrakRequest:
        return Constants.kontrakColor;
      case NotificationModel.typeGambarKerjaRequest:
        return Constants.gambarKerjaColor;
      default:
        return Constants.konstruksiColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
        return Icons.assignment_outlined;
      case NotificationModel.typeSurveyScheduleRequest:
        return Icons.event_available_outlined;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeDesignApproval:
      case NotificationModel.typeFinalDesignRequest:
        return Icons.design_services_outlined;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Icons.calculate_outlined;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Icons.payment_outlined;
      case NotificationModel.typeKontrakRequest:
        return Icons.description_outlined;
      case NotificationModel.typeItemPekerjaanRequest:
        return Icons.build_outlined;
      case NotificationModel.typeWorkplanRequest:
        return Icons.calendar_today_outlined;
      case NotificationModel.typeGambarKerjaRequest:
        return Icons.architecture_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tugas Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            if (onNavigateToNotifications != null)
              GestureDetector(
                onTap: onNavigateToNotifications,
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.surveyColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentPending.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 36, color: Constants.successColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  const Text(
                    'Semua tugas sudah ditangani!',
                    style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(recentPending.length, (i) {
            final n = recentPending[i];
            final color = _getTypeColor(n.type);
            final icon = _getTypeIcon(n.type);
            final isUnread = !n.isRead;

            return Container(
              margin: EdgeInsets.only(bottom: i < recentPending.length - 1 ? 10 : 0),
              decoration: BoxDecoration(
                color: Constants.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Constants.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: color, width: 4)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Constants.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: Constants.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n.order?.namaProject ?? '',
                              style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 12, color: Constants.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeAgo(DateTime.tryParse(n.createdAt) ?? DateTime.now()),
                                  style: const TextStyle(fontSize: 11, color: Constants.textLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
