import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class HomeQuickActions extends StatelessWidget {
  final bool isCS;
  final int unreadCount;
  final int pendingCount;
  final VoidCallback? onNavigateToNotifications;
  final VoidCallback? onCreateOrder;

  const HomeQuickActions({
    super.key,
    required this.isCS,
    required this.unreadCount,
    required this.pendingCount,
    this.onNavigateToNotifications,
    this.onCreateOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onNavigateToNotifications,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Constants.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Constants.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 22, color: Constants.surveyColor),
                      const SizedBox(height: 10),
                      const Text(
                        'Notifikasi Baru',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Constants.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$unreadCount unread',
                        style: const TextStyle(fontSize: 11, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.access_time_outlined, size: 22, color: Constants.estimasiColor),
                    const SizedBox(height: 10),
                    const Text(
                      'Tugas Pending',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Constants.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pendingCount tasks',
                      style: const TextStyle(fontSize: 11, color: Constants.textMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (isCS && onCreateOrder != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCreateOrder,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Constants.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Constants.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Constants.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Order Baru',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tambah proyek/klien ke dalam sistem',
                          style: TextStyle(fontSize: 12, color: Constants.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Constants.textLight.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
