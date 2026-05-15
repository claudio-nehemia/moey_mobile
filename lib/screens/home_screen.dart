import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/constant.dart';
import '../widgets/shimmer_loading.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToNotifications;
  const HomeScreen({super.key, this.onNavigateToNotifications});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  User? _currentUser;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      final response = await _notificationService.getNotifications(perPage: 50);
      final count = await _notificationService.getUnreadCount();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _notifications = response.data;
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
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
    return _notifications
        .where((n) => n.requiresActionResponse && n.isResponded)
        .length;
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 28),
                          _buildRecentTasks(),
                          const SizedBox(height: 28),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final firstName = _currentUser?.name.split(' ').first ?? 'User';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Constants.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting, $firstName 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semoga harimu produktif!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Constants.accentColor.withOpacity(0.9),
                    ),
                  ),
                  if (_currentUser?.isKepalaMarketing == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Kepala Marketing',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Constants.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  _getInitials(_currentUser?.name ?? 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Constants.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Constants.textDark)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Constants.textMedium)),
        ],
      ),
    );
  }

  Widget _buildRecentTasks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tugas Terbaru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Constants.textDark)),
            if (widget.onNavigateToNotifications != null)
              GestureDetector(
                onTap: widget.onNavigateToNotifications,
                child: Text(
                  'Lihat Semua >',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Constants.surveyColor),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Constants.secondaryColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 40, color: Constants.successColor.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text('Semua tugas sudah ditangani!', style: TextStyle(fontSize: 13, color: Constants.textLight)),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Constants.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isUnread ? color.withOpacity(0.3) : Constants.secondaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: TextStyle(fontSize: 14, fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, color: Constants.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          n.order?.namaProject ?? '',
                          style: TextStyle(fontSize: 12, color: Constants.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Constants.textLight),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeAgo(DateTime.tryParse(n.createdAt) ?? DateTime.now()),
                              style: TextStyle(fontSize: 11, color: Constants.textLight),
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
            );
          }),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Constants.textDark)),
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Constants.secondaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notifications_outlined, size: 24, color: Constants.surveyColor),
                      const SizedBox(height: 10),
                      const Text('Notifikasi Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark)),
                      const SizedBox(height: 2),
                      Text('$_unreadCount unread', style: TextStyle(fontSize: 12, color: Constants.textLight)),
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Constants.secondaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.access_time_outlined, size: 24, color: Constants.estimasiColor),
                    const SizedBox(height: 10),
                    const Text('Tugas Pending', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark)),
                    const SizedBox(height: 2),
                    Text('$_pendingCount tasks', style: TextStyle(fontSize: 12, color: Constants.textLight)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
}
