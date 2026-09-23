import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class HomePresenceHistory extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;

  const HomePresenceHistory({
    super.key,
    required this.dashboardData,
  });

  void _showPresenceDetailDialog(BuildContext context, Map<String, dynamic> item) {
    final String status = item['status']?.toString() ?? 'h';
    final String shiftName = item['nama_jam_kerja']?.toString() ?? 'Shift Regular';
    final String tgl = item['tanggal'] ?? '';
    final String jamIn = item['jam_in'] ?? '--:--';
    final String jamOut = item['jam_out'] ?? '--:--';
    final String shiftIn = item['jam_masuk'] ?? '--:--';
    final String shiftOut = item['jam_pulang'] ?? '--:--';
    final String? fotoIn = item['foto_in'];
    final String? fotoOut = item['foto_out'];

    Color statusColor = Colors.teal;
    String statusLabel = 'HADIR';
    if (status == 'i') {
      statusColor = Colors.blue;
      statusLabel = 'IZIN';
    } else if (status == 's') {
      statusColor = Colors.orange;
      statusLabel = 'SAKIT';
    } else if (status == 'c') {
      statusColor = Colors.redAccent;
      statusLabel = 'CUTI';
    } else if (status == 'a') {
      statusColor = Colors.grey;
      statusLabel = 'ALPA';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Presensi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shiftName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal: $tgl',
                        style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (status == 'h') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Foto Masuk',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: fotoIn != null && fotoIn.isNotEmpty
                                    ? Image.network(
                                        fotoIn,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                      )
                                    : const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Jam: $jamIn',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Constants.textDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Foto Pulang',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: fotoOut != null && fotoOut.isNotEmpty
                                    ? Image.network(
                                        fotoOut,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                      )
                                    : const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Jam: $jamOut',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Constants.textDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.black45),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jadwal Jam Kerja Shift: $shiftIn - $shiftOut',
                          style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                if (status != 'h' && item['keterangan'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alasan / Keterangan:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['keterangan'].toString(),
                          style: const TextStyle(fontSize: 12, color: Constants.textDark, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Tutup Detail', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> history = dashboardData?['history'] ?? [];
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Belum ada riwayat kehadiran bulan ini',
          style: TextStyle(color: Constants.textMedium, fontSize: 13),
        ),
      );
    }

    return Column(
      children: List.generate(history.length, (index) {
        final item = history[index];
        final String status = item['status']?.toString() ?? 'h';
        final String tanggalStr = item['tanggal'] ?? '';

        DateTime? parsedDate = DateTime.tryParse(tanggalStr);
        String dayName = 'MIN';
        String dayNum = '01';
        String formattedFullDate = tanggalStr;
        if (parsedDate != null) {
          final List<String> indoDays = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
          dayName = indoDays[parsedDate.weekday % 7];
          dayNum = parsedDate.day.toString().padLeft(2, '0');
          final List<String> indoMonths = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
          ];
          formattedFullDate = '${parsedDate.day} ${indoMonths[parsedDate.month - 1]} ${parsedDate.year}';
        }

        Color statusColor = Colors.teal;
        Color statusBg = Colors.teal.shade50;
        String statusLabel = 'Hadir';
        if (status == 'i') {
          statusColor = Colors.blue;
          statusBg = Colors.blue.shade50;
          statusLabel = 'Izin';
        } else if (status == 's') {
          statusColor = Colors.orange;
          statusBg = Colors.orange.shade50;
          statusLabel = 'Sakit';
        } else if (status == 'c') {
          statusColor = Colors.redAccent;
          statusBg = Colors.red.shade50;
          statusLabel = 'Cuti';
        } else if (status == 'a') {
          statusColor = Colors.grey;
          statusBg = Colors.grey.shade100;
          statusLabel = 'Alpa';
        }

        bool isLate = false;
        String lateText = '';
        if (status == 'h' && item['jam_in'] != null && item['jam_masuk'] != null) {
          try {
            final inParts = item['jam_in'].toString().split(':');
            final masukParts = item['jam_masuk'].toString().split(':');
            if (inParts.length >= 2 && masukParts.length >= 2) {
              final inMin = int.parse(inParts[0]) * 60 + int.parse(inParts[1]);
              final masukMin = int.parse(masukParts[0]) * 60 + int.parse(masukParts[1]);
              if (inMin > masukMin) {
                isLate = true;
                final diff = inMin - masukMin;
                lateText = 'Telat ${diff}m';
              }
            }
          } catch (_) {}
        }

        return GestureDetector(
          onTap: () => _showPresenceDetailDialog(context, item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      Text(
                        dayNum,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: statusColor, height: 1.1),
                      ),
                    ],
                  ),
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
                            formattedFullDate,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['nama_jam_kerja']?.toString() ?? 'Regular',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (status == 'h')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['jam_in'] ?? '--:--'} - ${item['jam_out'] ?? '--:--'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                            if (isLate)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lateText,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Tepat Waktu',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ),
                          ],
                        )
                      else
                        Text(
                          item['keterangan'] ?? statusLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
