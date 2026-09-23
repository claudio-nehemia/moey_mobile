import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../utils/constant.dart';
import '../../widgets/shimmer_loading.dart';
import '../aktivitas_screen.dart';
import '../create_order_screen.dart';
import '../izin_cuti_screen.dart';
import '../kunjungan_screen.dart';
import '../lembur_screen.dart';
import '../login_screen.dart';
import '../presence_screen.dart';
import '../slip_gaji_screen.dart';
import 'widgets/birthday_dialog.dart';
import 'widgets/home_alerts.dart';
import 'widgets/home_announcements.dart';
import 'widgets/home_attendance_menu.dart';
import 'widgets/home_cs_orders.dart';
import 'widgets/home_header.dart';
import 'widgets/home_presence_history.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_recent_tasks.dart';
import 'widgets/home_summary_cards.dart';

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

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      final token = await _authService.getToken();

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
            showBirthdayDialog(context, _currentUser?.name, age);
          });
        }
      }
    } catch (e) {
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
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
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
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
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
                    HomeHeader(
                      currentUser: _currentUser,
                      greeting: _greeting,
                      unreadCount: _unreadCount,
                      timeString: _timeString,
                      dateString: _dateString,
                      dashboardData: _dashboardData,
                      avatarPulseAnimation: _avatarPulseAnimation,
                      onNavigateToNotifications: widget.onNavigateToNotifications,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomeAttendanceMenu(
                            featureVisitTracking: _featureVisitTracking,
                            featureDailyActivity: _featureDailyActivity,
                            onPresensi: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PresenceScreen(initialDashboardData: _dashboardData)),
                              );
                              _loadData(silent: true);
                            },
                            onIzinCuti: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const IzinCutiScreen()),
                            ),
                            onLembur: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LemburScreen()),
                            ),
                            onKoreksiAbsen: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const IzinCutiScreen()),
                            ),
                            onKunjungan: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const KunjunganScreen()),
                            ),
                            onAktivitas: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AktivitasScreen()),
                            ),
                            onSlipGaji: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SlipGajiScreen()),
                            ),
                          ),
                          HomeQuickActions(
                            isCS: _currentUser?.isCustomerService == true,
                            unreadCount: _unreadCount,
                            pendingCount: _pendingCount,
                            onNavigateToNotifications: widget.onNavigateToNotifications,
                            onCreateOrder: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                              ).then((value) {
                                if (value == true) {
                                  _loadData();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          HomeAlerts(currentUser: _currentUser),
                          HomeAnnouncements(dashboardData: _dashboardData),
                          HomeSummaryCards(
                            unreadCount: _unreadCount,
                            pendingCount: _pendingCount,
                            todayCount: _todayCount,
                            completedThisMonth: _completedThisMonth,
                            dashboardData: _dashboardData,
                          ),
                          _buildTabBar(),
                          if (_activeTab == 0) ...[
                            HomeRecentTasks(
                              recentPending: _recentPending,
                              onNavigateToNotifications: widget.onNavigateToNotifications,
                            ),
                            const SizedBox(height: 16),
                            HomeCsOrders(
                              currentUser: _currentUser,
                              csOrders: _csOrders,
                              onRefresh: _loadData,
                            ),
                          ] else ...[
                            HomePresenceHistory(dashboardData: _dashboardData),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
