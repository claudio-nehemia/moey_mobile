import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class PresenceActionButtons extends StatelessWidget {
  final bool isLoading;
  final String statusMessage;
  final bool hasCheckedInToday;
  final bool hasCheckedOutToday;
  final bool isBreakActive;
  final Map<String, dynamic>? dashboardData;
  final void Function(String type) onSubmitPresence;

  const PresenceActionButtons({
    super.key,
    required this.isLoading,
    required this.statusMessage,
    required this.hasCheckedInToday,
    required this.hasCheckedOutToday,
    required this.isBreakActive,
    required this.dashboardData,
    required this.onSubmitPresence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GPS status message
        Center(
          child: Text(
            '📍 $statusMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Buttons Block
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: Constants.primaryColor),
          )
        else ...[
          // Check In Button
          if (!hasCheckedInToday)
            ElevatedButton.icon(
              onPressed: () => onSubmitPresence('masuk'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('CHECK IN MASUK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Sudah Check-In Masuk pada jam: ${dashboardData?['presensi']?['jam_in'] ?? '-'}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Break toggle (only if jam kerja has istirahat enabled)
          if (hasCheckedInToday &&
              !hasCheckedOutToday &&
              dashboardData?['jam_kerja']?['istirahat'] == 1) ...[
            ElevatedButton.icon(
              onPressed: () => onSubmitPresence('istirahat'),
              icon: Icon(
                isBreakActive
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
              label: Text(
                isBreakActive ? 'MULAI KEMBALI BEKERJA' : 'MULAI ISTIRAHAT',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBreakActive ? Colors.blue : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Check Out Button
          if (hasCheckedInToday && !hasCheckedOutToday)
            ElevatedButton.icon(
              onPressed: () => onSubmitPresence('pulang'),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('CHECK OUT PULANG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else if (hasCheckedOutToday)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Sudah Check-Out Pulang pada jam: ${dashboardData?['presensi']?['jam_out'] ?? '-'}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
