import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class HomeAttendanceMenu extends StatelessWidget {
  final bool featureVisitTracking;
  final bool featureDailyActivity;
  final VoidCallback onPresensi;
  final VoidCallback onIzinCuti;
  final VoidCallback onLembur;
  final VoidCallback onKoreksiAbsen;
  final VoidCallback onKunjungan;
  final VoidCallback onAktivitas;
  final VoidCallback onSlipGaji;

  const HomeAttendanceMenu({
    super.key,
    required this.featureVisitTracking,
    required this.featureDailyActivity,
    required this.onPresensi,
    required this.onIzinCuti,
    required this.onLembur,
    required this.onKoreksiAbsen,
    required this.onKunjungan,
    required this.onAktivitas,
    required this.onSlipGaji,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Presensi',
        'icon': Icons.fingerprint_rounded,
        'color': Colors.teal,
        'visible': true,
        'action': onPresensi,
      },
      {
        'title': 'Izin & Cuti',
        'icon': Icons.date_range_rounded,
        'color': Colors.indigo,
        'visible': true,
        'action': onIzinCuti,
      },
      {
        'title': 'Lembur',
        'icon': Icons.alarm_on_rounded,
        'color': Colors.redAccent,
        'visible': true,
        'action': onLembur,
      },
      {
        'title': 'Koreksi Absen',
        'icon': Icons.edit_calendar_rounded,
        'color': Colors.purple,
        'visible': true,
        'action': onKoreksiAbsen,
      },
      {
        'title': 'Kunjungan Lapangan',
        'icon': Icons.add_location_alt_rounded,
        'color': Colors.blue,
        'visible': featureVisitTracking,
        'action': onKunjungan,
      },
      {
        'title': 'Aktivitas Harian',
        'icon': Icons.assignment_outlined,
        'color': Colors.orange,
        'visible': featureDailyActivity,
        'action': onAktivitas,
      },
      {
        'title': 'Slip Gaji',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.teal,
        'visible': true,
        'action': onSlipGaji,
      },
    ];

    final visibleItems = menuItems.where((item) => item['visible'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Menu Presensi & Kehadiran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: visibleItems.length,
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return GestureDetector(
              onTap: item['action'] as VoidCallback,
              child: Container(
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Constants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
