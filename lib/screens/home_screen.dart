import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../utils/constant.dart';
import '../widgets/shimmer_loading.dart';
import 'dart:async';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import 'login_screen.dart';
import 'presence_screen.dart';
import 'izin_cuti_screen.dart';
import 'lembur_screen.dart';
import 'kunjungan_screen.dart';
import 'aktivitas_screen.dart';
import 'slip_gaji_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToNotifications;
  const HomeScreen({super.key, this.onNavigateToNotifications});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  User? _currentUser;
  List<NotificationModel> _notifications = [];
  List<dynamic> _csOrders = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  bool _featureVisitTracking = true;
  bool _featureDailyActivity = true;
  Timer? _pollTimer;
  Timer? _clockTimer;
  String _timeString = '';
  String _dateString = '';
  bool _birthdayShown = false;

  int _activeTab = 0; // 0 = Tugas & Proyek, 1 = Riwayat Presensi
  late AnimationController _avatarPulseController;
  late Animation<double> _avatarPulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData(silent: true));
    _timeString = _formatDateTime(DateTime.now());
    _dateString = _formatFullDate(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());

    _avatarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _avatarPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_avatarPulseController);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _avatarPulseController.dispose();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _timeString = _formatDateTime(DateTime.now());
        _dateString = _formatFullDate(DateTime.now());
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');
    return "$hour:$minute:$second";
  }

  String _formatFullDate(DateTime dateTime) {
    const List<String> days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    String dayName = days[dateTime.weekday % 7];
    String day = dateTime.day.toString();
    String monthName = months[dateTime.month - 1];
    String year = dateTime.year.toString();
    return "$dayName, $day $monthName $year";
  }

  void _showBirthdayDialog(String age) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎂',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selamat Ulang Tahun!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.name ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Semoga sukses, sehat selalu, dan dilancarkan rezekinya. Selamat hari lahir yang ke-$age tahun! 🎉',
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Terima Kasih! 🙏', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      final token = await _authService.getToken();

      print("DEBUG_ALERTS: Loaded user ${user?.name} (ID: ${user?.id}, Role: ${user?.roleName})");
      print("DEBUG_ALERTS: User nearestTask payload: ${user?.nearestTask}");
      print("DEBUG_ALERTS: User overdueTask payload: ${user?.overdueTask}");

      if (user == null || token == null) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      final response = await _notificationService.getNotifications(perPage: 50);
      final count = await _notificationService.getUnreadCount();

      List<dynamic> orders = [];
      if (user.isCustomerService == true) {
        try {
          orders = await _orderService.getOrders();
        } catch (_) {}
      }

      Map<String, dynamic>? dashboardData;
      try {
        dashboardData = await _authService.getDashboardData();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _currentUser = user;
          _notifications = response.data;
          _unreadCount = count;
          _csOrders = orders;
          _dashboardData = dashboardData;
          if (dashboardData != null && dashboardData['features'] != null) {
            _featureVisitTracking = dashboardData['features']['visit_tracking'] ?? true;
            _featureDailyActivity = dashboardData['features']['daily_activity'] ?? true;
          }
          _isLoading = false;
        });

        // Trigger birthday celebration
        final bdayData = dashboardData;
        if (bdayData != null && bdayData['is_birthday'] == true && !_birthdayShown) {
          _birthdayShown = true;
          final String age = bdayData['umur']?.toString() ?? '0';
          Future.microtask(() {
            _showBirthdayDialog(age);
          });
        }
      }
    } catch (e) {
      print("DEBUG_ALERTS: Error loading data: $e");
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
        return;
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Computed stats
  int get _pendingCount => _notifications
      .where((n) => n.requiresActionResponse && !n.isResponded)
      .length;

  int get _todayCount {
    final today = DateTime.now();
    return _notifications.where((n) {
      final created = DateTime.tryParse(n.createdAt);
      return created != null &&
          created.year == today.year &&
          created.month == today.month &&
          created.day == today.day &&
          n.requiresActionResponse &&
          !n.isResponded;
    }).length;
  }

  int get _completedThisMonth {
    final now = DateTime.now();
    return _notifications.where((n) {
      final created = DateTime.tryParse(n.createdAt);
      return created != null &&
          created.year == now.year &&
          created.month == now.month &&
          n.requiresActionResponse &&
          n.isResponded;
    }).length;
  }

  List<NotificationModel> get _recentPending => _notifications
      .where((n) => n.requiresActionResponse && !n.isResponded)
      .take(5)
      .toList();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
      case NotificationModel.typeSurveyScheduleRequest:
        return Constants.surveyColor;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeDesignApproval:
      case NotificationModel.typeFinalDesignRequest:
        return Constants.designColor;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Constants.estimasiColor;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Constants.financeColor;
      case NotificationModel.typeKontrakRequest:
        return Constants.kontrakColor;
      case NotificationModel.typeGambarKerjaRequest:
        return Constants.gambarKerjaColor;
      default:
        return Constants.konstruksiColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
        return Icons.assignment_outlined;
      case NotificationModel.typeSurveyScheduleRequest:
        return Icons.event_available_outlined;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeDesignApproval:
      case NotificationModel.typeFinalDesignRequest:
        return Icons.design_services_outlined;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Icons.calculate_outlined;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Icons.payment_outlined;
      case NotificationModel.typeKontrakRequest:
        return Icons.description_outlined;
      case NotificationModel.typeItemPekerjaanRequest:
        return Icons.build_outlined;
      case NotificationModel.typeWorkplanRequest:
        return Icons.calendar_today_outlined;
      case NotificationModel.typeGambarKerjaRequest:
        return Icons.architecture_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: _isLoading
          ? const DashboardSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Constants.accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAttendanceMenu(),
                          _buildQuickActions(),
                          const SizedBox(height: 16),
                          _buildAlertsSection(),
                          _buildAnnouncementSection(),
                          _buildSummaryCards(),
                          _buildTabBar(),
                          if (_activeTab == 0) ...[
                            _buildRecentTasks(),
                            const SizedBox(height: 16),
                            _buildCsOrdersList(),
                          ] else ...[
                            _buildPresenceHistoryList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _currentUser?.isCustomerService == true
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                ).then((value) {
                  if (value == true) {
                    _loadData();
                  }
                });
              },
              backgroundColor: Constants.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Buat Order',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final firstName = _currentUser?.name.split(' ').first ?? 'User';
    final userRole = _currentUser?.roleName ?? 'Karyawan';
    
    // Check if we have check-in/out times from _dashboardData, or fallback to global shift times
    final p = _dashboardData?['presensi'];
    final jk = _dashboardData?['jam_kerja'];
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
            color: Colors.black.withOpacity(0.12),
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
                          '$_greeting, $firstName 👋',
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
                            color: Colors.white.withOpacity(0.8),
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
                        onPressed: widget.onNavigateToNotifications,
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                      ),
                      if (_unreadCount > 0)
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
                    _timeString.isNotEmpty ? _timeString : '00:00:00',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateString.isNotEmpty ? _dateString : 'Hari ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
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
                      color: Colors.black.withOpacity(0.06),
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
                    if (_dashboardData?['jam_kerja'] != null) ...[
                      const Divider(height: 20, color: Constants.borderColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: Constants.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Jadwal Shift: ${_dashboardData!['jam_kerja']['nama_jam_kerja']} (${_dashboardData!['jam_kerja']['jam_masuk'] ?? '--:--'} - ${_dashboardData!['jam_kerja']['jam_pulang'] ?? '--:--'})',
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

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem(Icons.notifications_active_outlined, '$_unreadCount', 'Notifikasi Baru', Constants.surveyColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem(Icons.access_time_outlined, '$_pendingCount', 'Tugas Pending', Constants.estimasiColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatItem(Icons.today_outlined, '$_todayCount', 'Tugas Hari Ini', Constants.konstruksiColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem(Icons.trending_up_outlined, '$_completedThisMonth', 'Selesai Bulan Ini', Constants.financeColor)),
          ],
        ),
        _buildAttendanceRecap(),
      ],
    );
  }

  Widget _buildAttendanceRecap() {
    final rekap = _dashboardData?['rekap'];
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Constants.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
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
      ),
    );
  }

  Widget _buildRecentTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tugas Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            if (widget.onNavigateToNotifications != null)
              GestureDetector(
                onTap: widget.onNavigateToNotifications,
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.surveyColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentPending.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 36, color: Constants.successColor.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  const Text(
                    'Semua tugas sudah ditangani!',
                    style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_recentPending.length, (i) {
            final n = _recentPending[i];
            final color = _getTypeColor(n.type);
            final icon = _getTypeIcon(n.type);
            final isUnread = !n.isRead;

            return Container(
              margin: EdgeInsets.only(bottom: i < _recentPending.length - 1 ? 10 : 0),
              decoration: BoxDecoration(
                color: Constants.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Constants.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: color, width: 4)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Constants.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: Constants.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n.order?.namaProject ?? '',
                              style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 12, color: Constants.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeAgo(DateTime.tryParse(n.createdAt) ?? DateTime.now()),
                                  style: const TextStyle(fontSize: 11, color: Constants.textLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildQuickActions() {
    final isCS = _currentUser?.isCustomerService == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onNavigateToNotifications,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Constants.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Constants.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 22, color: Constants.surveyColor),
                      const SizedBox(height: 10),
                      const Text(
                        'Notifikasi Baru',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Constants.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_unreadCount unread',
                        style: const TextStyle(fontSize: 11, color: Constants.textMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.access_time_outlined, size: 22, color: Constants.estimasiColor),
                    const SizedBox(height: 10),
                    const Text(
                      'Tugas Pending',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Constants.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_pendingCount tasks',
                      style: const TextStyle(fontSize: 11, color: Constants.textMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (isCS) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
              ).then((value) {
                if (value == true) {
                  _loadData();
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Constants.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Constants.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Constants.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Order Baru',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tambah proyek/klien ke dalam sistem',
                          style: TextStyle(fontSize: 12, color: Constants.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Constants.textLight.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertsSection() {
    final overdueAlert = _currentUser?.overdueTask;
    final taskAlert = _currentUser?.nearestTask;
    final paymentAlert = _currentUser?.nearestPayment;
    final isLegalAdmin = _currentUser?.isLegalAdmin == true;

    print("DEBUG_ALERTS: Render _buildAlertsSection called.");
    print("DEBUG_ALERTS: Local overdueAlert: $overdueAlert");
    print("DEBUG_ALERTS: Local taskAlert: $taskAlert");
    print("DEBUG_ALERTS: Local paymentAlert: $paymentAlert");

    if (overdueAlert == null && taskAlert == null && (paymentAlert == null || !isLegalAdmin)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdueAlert != null) ...[
          _buildAlertCard(
            title: 'Peringatan Tugas Terlambat',
            message: overdueAlert['message'] ?? '',
            daysLeft: (overdueAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.errorColor,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 12),
        ],
        if (taskAlert != null) ...[
          _buildAlertCard(
            title: 'Info Tugas Terdekat',
            message: taskAlert['message'] ?? '',
            daysLeft: (taskAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.accentColor,
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (isLegalAdmin && paymentAlert != null) ...[
          _buildAlertCard(
            title: 'Remind Pembayaran',
            message: paymentAlert['message'] ?? '',
            daysLeft: (paymentAlert['days_left'] as num?)?.toInt() ?? 0,
            stripeColor: Constants.financeColor,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAnnouncementSection() {
    if (_dashboardData == null || _dashboardData!['pengumuman'] == null) {
      return const SizedBox.shrink();
    }

    final p = _dashboardData!['pengumuman'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pengumuman Internal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                p['created_at'] ?? '',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p['judul'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p['isi'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required int daysLeft,
    required Color stripeColor,
    required IconData icon,
  }) {
    String deadlineText = '';
    Color deadlineColor = Constants.textMedium;
    if (daysLeft == 0) {
      deadlineText = 'Hari ini!';
      deadlineColor = Constants.errorColor;
    } else if (daysLeft < 0) {
      deadlineText = 'Terlewat ${daysLeft.abs()} hari!';
      deadlineColor = Constants.errorColor;
    } else {
      deadlineText = '$daysLeft hari lagi';
      deadlineColor = daysLeft <= 2 ? Constants.errorColor : Constants.successColor;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: stripeColor.withOpacity(0.12),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripeColor, width: 6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stripeColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: stripeColor, size: 18),
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
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Constants.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: deadlineColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: deadlineColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Constants.textDark,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
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

  Widget _buildCsOrdersList() {
    if (_currentUser?.isCustomerService != true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Daftar Proyek Anda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Constants.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_csOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 36,
                    color: Constants.textLight.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada proyek yang dibuat',
                    style: TextStyle(
                      fontSize: 13,
                      color: Constants.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_csOrders.length, (i) {
            final order = _csOrders[i];
            final statusColor = _getStatusColor(order['project_status'] ?? 'pending');
            final dateStr = order['created_at'] != null
                ? _formatDate(DateTime.tryParse(order['created_at']) ?? DateTime.now())
                : '-';

            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: order['id']),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: i < _csOrders.length - 1 ? 10 : 0),
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Constants.primaryColor, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Constants.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business_center_outlined,
                          size: 18,
                          color: Constants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['nama_project'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Constants.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Customer: ${order['customer_name'] ?? '-'} (${order['company_name'] ?? '-'})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Constants.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Dibuat: $dateStr',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Constants.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (order['tahapan_proyek'] ?? order['project_status'] ?? 'pending')
                              .toString()
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          }),
      ],
    );
  }

  Widget _buildAttendanceMenu() {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Presensi',
        'icon': Icons.fingerprint_rounded,
        'color': Colors.teal,
        'visible': true,
        'action': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PresenceScreen(initialDashboardData: _dashboardData)),
          );
          _loadData(silent: true);
        },
      },
      {
        'title': 'Izin & Cuti',
        'icon': Icons.date_range_rounded,
        'color': Colors.indigo,
        'visible': true,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IzinCutiScreen()),
        ),
      },
      {
        'title': 'Lembur',
        'icon': Icons.alarm_on_rounded,
        'color': Colors.redAccent,
        'visible': true,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LemburScreen()),
        ),
      },
      {
        'title': 'Koreksi Absen',
        'icon': Icons.edit_calendar_rounded,
        'color': Colors.purple,
        'visible': true,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IzinCutiScreen()),
        ),
      },
      {
        'title': 'Kunjungan Lapangan',
        'icon': Icons.add_location_alt_rounded,
        'color': Colors.blue,
        'visible': _featureVisitTracking,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KunjunganScreen()),
        ),
      },
      {
        'title': 'Aktivitas Harian',
        'icon': Icons.assignment_outlined,
        'color': Colors.orange,
        'visible': _featureDailyActivity,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AktivitasScreen()),
        ),
      },
      {
        'title': 'Slip Gaji',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.teal,
        'visible': true,
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SlipGajiScreen()),
        ),
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
                        color: (item['color'] as Color).withOpacity(0.08),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'completed':
      case 'active':
        return Constants.successColor;
      case 'progress':
      case 'in_progress':
      case 'survey':
      case 'moodboard':
      case 'estimasi':
        return Constants.primaryColor;
      case 'pending':
      case 'menunggu':
        return Constants.warningColor;
      default:
        return Constants.textMedium;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  Widget _buildPulsingAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          _getInitials(_currentUser?.name ?? 'U'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusBadge() {
    final p = _dashboardData?['presensi'];
    final bool isWorking = p != null && p['jam_in'] != null && p['jam_out'] == null;
    
    if (!isWorking) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.4), width: 1),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? Colors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 0
                        ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Tugas & Proyek',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 0 ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? Colors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 1
                        ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Riwayat Presensi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 1 ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceHistoryList() {
    final List<dynamic> history = _dashboardData?['history'] ?? [];
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
          onTap: () => _showPresenceDetailDialog(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
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

  void _showPresenceDetailDialog(Map<String, dynamic> item) {
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
                    color: statusColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
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
}
