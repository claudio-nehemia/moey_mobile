import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../utils/constant.dart';

class HomeHeader extends StatelessWidget {
  final User? currentUser;
  final String greeting;
  final int unreadCount;
  final String timeString;
  final String dateString;
  final Map<String, dynamic>? dashboardData;
  final Animation<double> avatarPulseAnimation;
  final VoidCallback? onNavigateToNotifications;

  const HomeHeader({
    super.key,
    required this.currentUser,
    required this.greeting,
    required this.unreadCount,
    required this.timeString,
    required this.dateString,
    required this.dashboardData,
    required this.avatarPulseAnimation,
    this.onNavigateToNotifications,
  });

  Widget _buildPulsingAvatar() {
    final avatarUrl = currentUser?.avatar;
    final initial = currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : 'U';

    return AnimatedBuilder(
      animation: avatarPulseAnimation,
      builder: (context, child) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3 * (1 - avatarPulseAnimation.value)),
                blurRadius: 10 * avatarPulseAnimation.value,
                spreadRadius: 4 * avatarPulseAnimation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLiveStatusBadge() {
    final p = dashboardData?['presensi'];
    final bool isWorking = p != null && p['jam_in'] != null && p['jam_out'] == null;

    if (!isWorking) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Sedang Bekerja',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = currentUser?.name.split(' ').first ?? 'User';
    final userRole = currentUser?.roleName ?? 'Karyawan';

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Row 1: Profile and Avatar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userRole,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Top-Right Notification Button with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: onNavigateToNotifications,
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  _buildPulsingAvatar(),
                ],
              ),
            ),

            // Row 2: Clock & Date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Text(
                    timeString.isNotEmpty ? timeString : '00:00:00',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateString.isNotEmpty ? dateString : 'Hari ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLiveStatusBadge(),
                ],
              ),
            ),

            // Row 3: Quick Attendance status overlay (Jam Masuk vs Jam Pulang)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Jam Masuk
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: fotoIn != null && fotoIn.isNotEmpty
                                      ? Image.network(fotoIn, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.camera_alt_outlined, size: 18, color: Colors.teal.shade800))
                                      : Icon(Icons.camera_alt_outlined, size: 18, color: Colors.teal.shade800),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jam Masuk',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      jamIn,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: hasCheckedIn ? Colors.teal.shade800 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),

                        // Jam Pulang
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: fotoOut != null && fotoOut.isNotEmpty
                                      ? Image.network(fotoOut, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.camera_alt_outlined, size: 18, color: Colors.redAccent))
                                      : Icon(Icons.camera_alt_outlined, size: 18, color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jam Pulang',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      jamOut,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: hasCheckedOut ? Colors.redAccent : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (dashboardData?['jam_kerja'] != null) ...[
                      const Divider(height: 20, color: Constants.borderColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: Constants.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Jadwal Shift: ${dashboardData!['jam_kerja']['nama_jam_kerja']} (${dashboardData!['jam_kerja']['jam_masuk'] ?? '--:--'} - ${dashboardData!['jam_kerja']['jam_pulang'] ?? '--:--'})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Constants.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
