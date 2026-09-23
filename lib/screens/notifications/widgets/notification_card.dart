import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../models/user.dart';
import '../../../utils/constant.dart';
import '../helpers/notification_helpers.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isHighlighted;
  final User? currentUser;
  final bool hasUnrespondedTask;
  final VoidCallback onCardTap;
  final VoidCallback onAction;
  final VoidCallback onPmAction;
  final VoidCallback onViewTask;

  const NotificationCard({
    super.key,
    required this.notification,
    this.isHighlighted = false,
    required this.currentUser,
    required this.hasUnrespondedTask,
    required this.onCardTap,
    required this.onAction,
    required this.onPmAction,
    required this.onViewTask,
  });

  @override
  Widget build(BuildContext context) {
    final color = NotificationHelpers.getColor(notification.type);
    final icon = NotificationHelpers.getIcon(notification.type);
    final createdAt = DateTime.tryParse(notification.createdAt) ?? DateTime.now();
    final isUnread = !notification.isRead;
    final isResponded = notification.isResponded;
    final requiresAction = notification.requiresActionResponse;

    return GestureDetector(
      onTap: onCardTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Constants.infoColor.withOpacity(0.06)
              : Constants.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? Constants.infoColor.withOpacity(0.4)
                : Constants.borderColor,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isHighlighted
                      ? Constants.infoColor
                      : (isResponded ? Constants.successColor : color),
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main row: icon + content + unread dot
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Constants.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isResponded ? Icons.check_circle_outline : icon,
                        size: 18,
                        color: isResponded ? Constants.successColor : color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: Constants.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: const TextStyle(fontSize: 12, color: Constants.textMedium, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isUnread)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Project chip + Time
                Row(
                  children: [
                    if (notification.order != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Constants.surfaceColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Constants.borderColor),
                        ),
                        child: Text(
                          notification.order!.namaProject,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Constants.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 12, color: Constants.textLight),
                    const SizedBox(width: 3),
                    Text(
                      NotificationHelpers.formatTimeAgo(createdAt),
                      style: const TextStyle(fontSize: 11, color: Constants.textLight),
                    ),
                  ],
                ),

                // Response info banners
                if (requiresAction && isResponded) ...[
                  if (notification.responseInfo != null) ...[
                    const SizedBox(height: 10),
                    _buildResponseBanner(
                      '✓ Direspon',
                      notification.responseInfo!['by'],
                      notification.responseInfo!['time'],
                      Constants.successColor,
                    ),
                  ],
                  if (notification.pmResponseInfo != null) ...[
                    const SizedBox(height: 6),
                    _buildResponseBanner(
                      '✓ Marketing Response',
                      notification.pmResponseInfo!['by'],
                      notification.pmResponseInfo!['time'],
                      Constants.marketingColor,
                    ),
                  ],
                ],

                // Action buttons
                if (requiresAction && !isResponded) ...[
                  const SizedBox(height: 12),
                  if (currentUser != null && currentUser!.isKepalaMarketing) ...[
                    if (notification.pmResponseInfo == null)
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: onPmAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.marketingColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Marketing Response',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    else
                      _buildResponseBanner(
                        '✓ Marketing Response',
                        notification.pmResponseInfo!['by'],
                        notification.pmResponseInfo!['time'],
                        Constants.marketingColor,
                      ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          notification.actionText,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  if (!(currentUser?.isKepalaMarketing ?? false) && notification.pmResponseInfo != null) ...[
                    const SizedBox(height: 8),
                    _buildResponseBanner(
                      '✓ Marketing Response',
                      notification.pmResponseInfo!['by'],
                      notification.pmResponseInfo!['time'],
                      Constants.marketingColor,
                    ),
                  ],
                ],

                // Responded notification - show PM button if PM hasn't responded
                if (requiresAction &&
                    isResponded &&
                    currentUser != null &&
                    currentUser!.isKepalaMarketing &&
                    notification.pmResponseInfo == null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: onPmAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.marketingColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Marketing Response',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],

                // View-only button
                if (!requiresAction) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onViewTask,
                      icon: Icon(
                        hasUnrespondedTask ? Icons.arrow_forward : Icons.find_in_page_outlined,
                        size: 14,
                        color: Constants.primaryColor,
                      ),
                      label: Text(
                        hasUnrespondedTask ? 'Menuju Tugas' : 'Check Response',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Constants.primaryColor,
                        side: const BorderSide(color: Constants.borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponseBanner(String label, String? by, String? time, Color color) {
    final parts = <String>[];
    if (by != null) parts.add('oleh $by');
    if (time != null) parts.add('— ${NotificationHelpers.formatResponseTime(time)}');
    final detail = parts.join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, color: color),
                children: [
                  TextSpan(text: label.replaceAll('✓ ', ''), style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (detail.isNotEmpty) TextSpan(text: '  $detail', style: TextStyle(color: color.withOpacity(0.8))),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
