import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../utils/constant.dart';
import 'presence_screen.dart';

class AttendanceTabScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDashboardData;
  const AttendanceTabScreen({super.key, this.initialDashboardData});

  @override
  State<AttendanceTabScreen> createState() => _AttendanceTabScreenState();
}

class _AttendanceTabScreenState extends State<AttendanceTabScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  Position? _currentPosition;
  double _distanceToOffice = 0.0;
  bool _isWithinGeofence = false;

  @override
  void initState() {
    super.initState();
    _dashboardData = widget.initialDashboardData;
    _determinePosition();
    _refreshData();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          _calculateDistance();
        }
      }
    } catch (_) {}
  }

  void _calculateDistance() {
    if (_currentPosition == null || _dashboardData == null) return;
    final cabang = _dashboardData?['cabang'];
    if (cabang == null || cabang['lokasi_cabang'] == null) return;
    
    final parts = cabang['lokasi_cabang'].toString().split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        final double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );
        final double radius = double.tryParse(cabang['radius_cabang'].toString()) ?? 50.0;
        setState(() {
          _distanceToOffice = distance;
          _isWithinGeofence = distance <= radius;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final freshData = await _authService.getDashboardData();
    if (freshData != null && mounted) {
      setState(() {
        _dashboardData = freshData;
        _isLoading = false;
      });
      _determinePosition();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getWorkProgress() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 8, 0);
    final end = DateTime(now.year, now.month, now.day, 17, 0);
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }

  @override
  Widget build(BuildContext context) {
    final p = _dashboardData?['presensi'];
    final jk = _dashboardData?['jam_kerja'];
    final String jamIn = p != null && p['jam_in'] != null 
        ? p['jam_in'] 
        : (jk != null && jk['jam_masuk'] != null ? jk['jam_masuk'] : '--:--');
    final String jamOut = p != null && p['jam_out'] != null 
        ? p['jam_out'] 
        : (jk != null && jk['jam_pulang'] != null ? jk['jam_pulang'] : '--:--');
    
    final progress = _getWorkProgress();
    final percent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: const Text('Kehadiran & Absensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Constants.primaryColor),
            onPressed: _refreshData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: Constants.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Work Hours Progress Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade700, Colors.teal.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Progress Jam Kerja Hari Ini',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          
                          // Circular Progress Gauge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.white.withOpacity(0.12),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                  ),
                                  const Text(
                                    'Selesai',
                                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Masuk Shift', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _dashboardData?['jam_kerja']?['jam_masuk'] ?? '08:00',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 20, color: Colors.white24),
                              Column(
                                children: [
                                  const Text('Pulang Shift', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _dashboardData?['jam_kerja']?['jam_pulang'] ?? '17:00',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Selfie Presence Trigger
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PresenceScreen(initialDashboardData: _dashboardData),
                          ),
                        );
                        if (result == true || result == null) {
                          _refreshData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.teal.shade200, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.photo_camera_front_rounded, color: Colors.teal, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Buka Kamera Presensi',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Constants.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    jamIn == '--:--' ? 'Lakukan Absen Masuk Sekarang' : 'Lakukan Absen Pulang / Istirahat',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.teal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Geofence status message
                    if (_currentPosition != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isWithinGeofence ? Colors.teal.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _isWithinGeofence ? Colors.teal.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isWithinGeofence ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _isWithinGeofence ? Colors.teal.shade800 : Colors.red.shade800,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isWithinGeofence
                                    ? 'Lokasi Anda berada dalam radius geofence kantor (${_distanceToOffice.toStringAsFixed(1)}m)'
                                    : 'Lokasi Anda berada di luar radius kantor (${_distanceToOffice.toStringAsFixed(1)}m, batas: 50m)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isWithinGeofence ? Colors.teal.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Working Timeline (Today's checkmarks)
                    const Text(
                      '📋 Alur Kehadiran Hari Ini',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildTimelineStep(
                            icon: Icons.login_rounded,
                            title: 'Absen Masuk (Check-In)',
                            time: jamIn,
                            isCompleted: jamIn != '--:--',
                            color: Colors.teal,
                          ),
                          _buildTimelineDivider(),
                          _buildTimelineStep(
                            icon: Icons.coffee_rounded,
                            title: 'Mulai Istirahat',
                            time: p?['istirahat_out'] ?? '--:--',
                            isCompleted: p?['istirahat_out'] != null,
                            color: Colors.orange,
                          ),
                          _buildTimelineDivider(),
                          _buildTimelineStep(
                            icon: Icons.work_history_rounded,
                            title: 'Kembali Bekerja',
                            time: p?['istirahat_in'] ?? '--:--',
                            isCompleted: p?['istirahat_in'] != null,
                            color: Colors.blue,
                          ),
                          _buildTimelineDivider(),
                          _buildTimelineStep(
                            icon: Icons.logout_rounded,
                            title: 'Absen Pulang (Check-Out)',
                            time: jamOut,
                            isCompleted: jamOut != '--:--',
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String time,
    required bool isCompleted,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? color.withOpacity(0.12) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: isCompleted ? color : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Constants.textDark : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCompleted ? 'Dilakukan pada jam $time' : 'Belum dilakukan',
                style: TextStyle(
                  fontSize: 10,
                  color: isCompleted ? color : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 17),
      height: 20,
      width: 2,
      color: Colors.grey.shade200,
    );
  }
}
