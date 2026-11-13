import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../utils/constant.dart';
import '../../order_detail_screen.dart';
import '../../presence_screen.dart';

class HomeDetailSheets {
  static void _showBaseSheet({
    required BuildContext context,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  /// 1. Detail Notifikasi Baru
  static void showUnreadNotifications(
    BuildContext context,
    List<NotificationModel> unreadNotifications,
    VoidCallback? onNavigateToAll,
  ) {
    _showBaseSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Constants.surveyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: Constants.surveyColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifikasi Baru',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                      ),
                      Text(
                        '${unreadNotifications.length} notifikasi belum dibaca',
                        style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (unreadNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.mark_email_read_outlined, size: 48, color: Colors.teal.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Semua notifikasi sudah dibaca!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ada notifikasi baru saat ini.',
                        style: TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: unreadNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final n = unreadNotifications[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (n.orderId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => OrderDetailScreen(orderId: n.orderId!)),
                          );
                        } else if (onNavigateToAll != null) {
                          onNavigateToAll();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Constants.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_outlined, size: 16, color: Colors.amber),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    n.message,
                                    style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (onNavigateToAll != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onNavigateToAll();
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('Buka Halaman Notifikasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 2. Detail Tugas Pending
  static void showPendingTasks(
    BuildContext context,
    List<NotificationModel> pendingTasks,
    VoidCallback? onNavigateToAll,
  ) {
    _showBaseSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Constants.estimasiColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: Constants.estimasiColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tugas Pending',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                      ),
                      Text(
                        '${pendingTasks.length} tugas butuh tindakan / respon',
                        style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (pendingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Semua tugas selesai!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ada tugas pending yang memerlukan respon Anda.',
                        style: TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendingTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final task = pendingTasks[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (task.orderId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => OrderDetailScreen(orderId: task.orderId!)),
                          );
                        } else if (onNavigateToAll != null) {
                          onNavigateToAll();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Constants.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pending_actions_rounded, size: 18, color: Colors.orange),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Perlu Respon',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.message,
                                    style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (task.order != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Project: ${task.order!.namaProject} • ${task.order!.customerName}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.teal.shade700),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (onNavigateToAll != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onNavigateToAll();
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Buka Semua Tugas di Notifikasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 3. Detail Tugas Hari Ini
  static void showTodayTasks(
    BuildContext context,
    List<NotificationModel> todayTasks,
    VoidCallback? onNavigateToAll,
  ) {
    _showBaseSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Constants.konstruksiColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_rounded, color: Constants.konstruksiColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tugas Hari Ini',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                      ),
                      Text(
                        '${todayTasks.length} tugas masuk hari ini',
                        style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (todayTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, size: 48, color: Colors.blueGrey),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada tugas baru hari ini',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tugas baru yang masuk hari ini akan ditampilkan di sini.',
                        style: TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: todayTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final t = todayTasks[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (t.orderId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => OrderDetailScreen(orderId: t.orderId!)),
                          );
                        } else if (onNavigateToAll != null) {
                          onNavigateToAll();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Constants.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Constants.borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.message,
                                    style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 4. Detail Selesai Bulan Ini
  static void showCompletedTasks(
    BuildContext context,
    List<NotificationModel> completedTasks,
    VoidCallback? onNavigateToAll,
  ) {
    _showBaseSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Constants.financeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Constants.financeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selesai Bulan Ini',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                      ),
                      Text(
                        '${completedTasks.length} tugas diselesaikan bulan ini',
                        style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (completedTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada tugas selesai bulan ini',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: completedTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final t = completedTasks[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (t.orderId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => OrderDetailScreen(orderId: t.orderId!)),
                          );
                        } else if (onNavigateToAll != null) {
                          onNavigateToAll();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Constants.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.title,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '✓ Selesai',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.message,
                                    style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 5. Detail Rekap Kehadiran (Hadir / Sakit / Izin / Cuti)
  static void showAttendanceRecap(
    BuildContext context, {
    required String title,
    required String count,
    required String label,
    required Color color,
    required IconData icon,
    required List<dynamic> entries,
    required VoidCallback onSwitchToHistory,
    required VoidCallback onOpenIzinCuti,
  }) {
    _showBaseSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                      ),
                      Text(
                        'Total: $count hari di bulan ini',
                        style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(icon, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada data $label untuk bulan ini.',
                        style: const TextStyle(fontSize: 13, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = entries[i];
                    final tgl = item['tanggal']?.toString() ?? '-';
                    final shift = item['nama_jam_kerja']?.toString() ?? 'Shift Regular';
                    final jamIn = item['jam_in']?.toString() ?? '--:--';
                    final jamOut = item['jam_out']?.toString() ?? '--:--';
                    final keterangan = item['keterangan_izin'] ?? item['keterangan_sakit'] ?? item['keterangan_cuti'];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Constants.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Constants.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tgl,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shift,
                                style: const TextStyle(fontSize: 11, color: Constants.textMedium),
                              ),
                              if (keterangan != null && keterangan.toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  keterangan.toString(),
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: color),
                                ),
                              ],
                            ],
                          ),
                          if (label == 'Hadir')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'In: $jamIn',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                                Text(
                                  'Out: $jamOut',
                                  style: TextStyle(fontSize: 11, color: jamOut != '--:--' ? Colors.redAccent : Colors.grey),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                label.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (label == 'Hadir')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onSwitchToHistory();
                      },
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('Lihat Riwayat Lengkap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onOpenIzinCuti();
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text('Ajukan $label Baru'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 6. Detail Presensi Hari Ini (Header Card Tap)
  static void showTodayPresence(
    BuildContext context, {
    required Map<String, dynamic>? dashboardData,
    required VoidCallback onOpenPresence,
  }) {
    final p = dashboardData?['presensi'];
    final jk = dashboardData?['jam_kerja'];
    final bool hasCheckedIn = p != null && p['jam_in'] != null;
    final bool hasCheckedOut = p != null && p['jam_out'] != null;

    final String jamIn = hasCheckedIn
        ? p['jam_in']
        : (jk != null && jk['jam_masuk'] != null ? jk['jam_masuk'] : '--:--');
    final String jamOut = hasCheckedOut
        ? p['jam_out']
        : (jk != null && jk['jam_pulang'] != null ? jk['jam_pulang'] : '--:--');
    final String? fotoIn = p != null ? p['foto_in'] : null;
    final String? fotoOut = p != null ? p['foto_out'] : null;
    final String shiftName = jk != null && jk['nama_jam_kerja'] != null ? jk['nama_jam_kerja'] : 'Shift Regular';

    _showBaseSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Presensi Hari Ini',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                      ),
                      Text(
                        shiftName,
                        style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Masuk & Pulang Cards
            Row(
              children: [
                // Masuk
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jam Masuk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            Icon(Icons.login_rounded, size: 16, color: Colors.teal.shade700),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          jamIn,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasCheckedIn ? Colors.teal.shade800 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCheckedIn ? '✓ Sudah Masuk' : 'Belum Absen',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasCheckedIn ? Colors.teal : Colors.grey),
                        ),
                        if (fotoIn != null && fotoIn.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fotoIn,
                              height: 60,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Pulang
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jam Pulang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          jamOut,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasCheckedOut ? Colors.redAccent : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCheckedOut ? '✓ Sudah Pulang' : 'Belum Pulang',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasCheckedOut ? Colors.redAccent : Colors.grey),
                        ),
                        if (fotoOut != null && fotoOut.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fotoOut,
                              height: 60,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onOpenPresence();
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(
                  !hasCheckedIn
                      ? 'Lakukan Presensi Masuk'
                      : (!hasCheckedOut ? 'Lakukan Presensi Pulang' : 'Buka Layar Presensi'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
