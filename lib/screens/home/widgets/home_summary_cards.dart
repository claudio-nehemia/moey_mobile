import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class HomeSummaryCards extends StatelessWidget {
  final int unreadCount;
  final int pendingCount;
  final int todayCount;
  final int completedThisMonth;
  final Map<String, dynamic>? dashboardData;

  const HomeSummaryCards({
    super.key,
    required this.unreadCount,
    required this.pendingCount,
    required this.todayCount,
    required this.completedThisMonth,
    required this.dashboardData,
  });

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildRecapItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.borderColor),
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
    );
  }

  Widget _buildAttendanceRecap() {
    final rekap = dashboardData?['rekap'];
    final hadir = rekap?['hadir']?.toString() ?? '0';
    final sakit = rekap?['sakit']?.toString() ?? '0';
    final izin = rekap?['izin']?.toString() ?? '0';
    final cuti = rekap?['cuti']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Rekap Kehadiran Bulan Ini',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRecapItem(Icons.check_circle_outline, hadir, 'Hadir', Colors.teal)),
            const SizedBox(width: 8),
            Expanded(child: _buildRecapItem(Icons.healing_outlined, sakit, 'Sakit', Colors.amber)),
            const SizedBox(width: 8),
            Expanded(child: _buildRecapItem(Icons.insert_drive_file_outlined, izin, 'Izin', Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildRecapItem(Icons.date_range_outlined, cuti, 'Cuti', Colors.redAccent)),
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
            Expanded(child: _buildStatItem(Icons.notifications_active_outlined, '$unreadCount', 'Notifikasi Baru', Constants.surveyColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem(Icons.access_time_outlined, '$pendingCount', 'Tugas Pending', Constants.estimasiColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatItem(Icons.today_outlined, '$todayCount', 'Tugas Hari Ini', Constants.konstruksiColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem(Icons.trending_up_outlined, '$completedThisMonth', 'Selesai Bulan Ini', Constants.financeColor)),
          ],
        ),
        _buildAttendanceRecap(),
      ],
    );
  }
}
