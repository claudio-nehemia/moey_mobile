import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onRefresh;
  final VoidCallback onMarkAllAsRead;

  const NotificationHeader({
    super.key,
    required this.unreadCount,
    required this.onRefresh,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Constants.textDark,
              letterSpacing: -0.5,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Constants.errorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh_rounded, color: Constants.textLight, size: 20),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onMarkAllAsRead,
            child: const Text(
              'Tandai Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Constants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
