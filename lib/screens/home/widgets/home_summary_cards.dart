import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../utils/constant.dart';
import 'home_detail_sheets.dart';

class HomeSummaryCards extends StatelessWidget {
  final int unreadCount;
  final int pendingCount;
  final int todayCount;
  final int completedThisMonth;
  final Map<String, dynamic>? dashboardData;
  final List<NotificationModel> notifications;
  final VoidCallback? onNavigateToNotifications;
  final Function(int)? onSwitchTab;
  final VoidCallback? onOpenIzinCuti;

  const HomeSummaryCards({
    super.key,
    required this.unreadCount,
    required this.pendingCount,
    required this.todayCount,
    required this.completedThisMonth,
    required this.dashboardData,
    this.notifications = const [],
    this.onNavigateToNotifications,
    this.onSwitchTab,
    this.onOpenIzinCuti,
  });

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Constants.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Constants.textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: Constants.textLight.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapItem(
    IconData icon,
    String value,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Constants.textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecap(BuildContext context) {
    final rekap = dashboardData?['rekap'];
    final hadir = rekap?['hadir']?.toString() ?? '0';
    final sakit = rekap?['sakit']?.toString() ?? '0';
    final izin = rekap?['izin']?.toString() ?? '0';
    final cuti = rekap?['cuti']?.toString() ?? '0';

    final List<dynamic> listPresensi = (dashboardData?['datapresensi'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rekap Kehadiran Bulan Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            GestureDetector(
              onTap: () => onSwitchTab?.call(1),
              child: const Row(
                children: [
                  Text(
                    'Riwayat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.teal),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRecapItem(
                Icons.check_circle_outline,
                hadir,
                'Hadir',
                Colors.teal,
                onTap: () {
                  final hadirList = listPresensi.where((e) {
                    final s = e['status']?.toString().toLowerCase();
                    return s == 'h' || s == 'hadir';
                  }).toList();
                  HomeDetailSheets.showAttendanceRecap(
                    context,
                    title: 'Kehadiran Bulan Ini',
                    count: hadir,
                    label: 'Hadir',
                    color: Colors.teal,
                    icon: Icons.check_circle_outline,
                    entries: hadirList,
                    onSwitchToHistory: () => onSwitchTab?.call(1),
                    onOpenIzinCuti: onOpenIzinCuti ?? () {},
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRecapItem(
                Icons.healing_outlined,
                sakit,
                'Sakit',
                Colors.amber.shade800,
                onTap: () {
                  final sakitList = listPresensi.where((e) {
                    final s = e['status']?.toString().toLowerCase();
                    return s == 's' || s == 'sakit';
                  }).toList();
                  HomeDetailSheets.showAttendanceRecap(
                    context,
                    title: 'Riwayat Sakit Bulan Ini',
                    count: sakit,
                    label: 'Sakit',
                    color: Colors.amber.shade800,
                    icon: Icons.healing_outlined,
                    entries: sakitList,
                    onSwitchToHistory: () => onSwitchTab?.call(1),
                    onOpenIzinCuti: onOpenIzinCuti ?? () {},
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRecapItem(
                Icons.insert_drive_file_outlined,
                izin,
                'Izin',
                Colors.blue,
                onTap: () {
                  final izinList = listPresensi.where((e) {
                    final s = e['status']?.toString().toLowerCase();
                    return s == 'i' || s == 'izin';
                  }).toList();
                  HomeDetailSheets.showAttendanceRecap(
                    context,
                    title: 'Riwayat Izin Bulan Ini',
                    count: izin,
                    label: 'Izin',
                    color: Colors.blue,
                    icon: Icons.insert_drive_file_outlined,
                    entries: izinList,
                    onSwitchToHistory: () => onSwitchTab?.call(1),
                    onOpenIzinCuti: onOpenIzinCuti ?? () {},
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRecapItem(
                Icons.date_range_outlined,
                cuti,
                'Cuti',
                Colors.redAccent,
                onTap: () {
                  final cutiList = listPresensi.where((e) {
                    final s = e['status']?.toString().toLowerCase();
                    return s == 'c' || s == 'cuti';
                  }).toList();
                  HomeDetailSheets.showAttendanceRecap(
                    context,
                    title: 'Riwayat Cuti Bulan Ini',
                    count: cuti,
                    label: 'Cuti',
                    color: Colors.redAccent,
                    icon: Icons.date_range_outlined,
                    entries: cutiList,
                    onSwitchToHistory: () => onSwitchTab?.call(1),
                    onOpenIzinCuti: onOpenIzinCuti ?? () {},
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                Icons.notifications_active_outlined,
                '$unreadCount',
                'Notifikasi Baru',
                Constants.surveyColor,
                onTap: () {
                  final unread = notifications.where((n) => !n.isRead).toList();
                  HomeDetailSheets.showUnreadNotifications(context, unread, onNavigateToNotifications);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                Icons.access_time_outlined,
                '$pendingCount',
                'Tugas Pending',
                Constants.estimasiColor,
                onTap: () {
                  final pending = notifications.where((n) => n.requiresActionResponse && !n.isResponded).toList();
                  HomeDetailSheets.showPendingTasks(context, pending, onNavigateToNotifications);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                Icons.today_outlined,
                '$todayCount',
                'Tugas Hari Ini',
                Constants.konstruksiColor,
                onTap: () {
                  final today = DateTime.now();
                  final todayTasks = notifications.where((n) {
                    final created = DateTime.tryParse(n.createdAt);
                    return created != null &&
                        created.year == today.year &&
                        created.month == today.month &&
                        created.day == today.day &&
                        n.requiresActionResponse &&
                        !n.isResponded;
                  }).toList();
                  HomeDetailSheets.showTodayTasks(context, todayTasks, onNavigateToNotifications);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                Icons.trending_up_outlined,
                '$completedThisMonth',
                'Selesai Bulan Ini',
                Constants.financeColor,
                onTap: () {
                  final now = DateTime.now();
                  final completed = notifications.where((n) {
                    final created = DateTime.tryParse(n.createdAt);
                    return created != null &&
                        created.year == now.year &&
                        created.month == now.month &&
                        n.requiresActionResponse &&
                        n.isResponded;
                  }).toList();
                  HomeDetailSheets.showCompletedTasks(context, completed, onNavigateToNotifications);
                },
              ),
            ),
          ],
        ),
        _buildAttendanceRecap(context),
      ],
    );
  }
}
