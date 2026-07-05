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

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToNotifications;
  const HomeScreen({super.key, this.onNavigateToNotifications});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  User? _currentUser;
  List<NotificationModel> _notifications = [];
  List<dynamic> _csOrders = [];
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

      List<dynamic> orders = [];
      if (user?.isCustomerService == true) {
        try {
          orders = await _orderService.getOrders();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _notifications = response.data;
          _unreadCount = count;
          _csOrders = orders;
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
                          _buildAlertsSection(),
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildRecentTasks(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          _buildCsOrdersList(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Constants.cardColor,
        border: Border(
          bottom: BorderSide(color: Constants.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting, $firstName 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Constants.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Semoga harimu produktif!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Constants.textMedium,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_currentUser?.isKepalaMarketing == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Constants.primaryColor.withOpacity(0.15)),
                      ),
                      child: const Text(
                        'Kepala Marketing',
                        style: TextStyle(
                          color: Constants.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Constants.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Constants.borderColor),
              ),
              child: Center(
                child: Text(
                  _getInitials(_currentUser?.name ?? 'U'),
                  style: const TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 15,
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
      ],
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
    final taskAlert = _currentUser?.nearestTask;
    final paymentAlert = _currentUser?.nearestPayment;
    final isLegalAdmin = _currentUser?.isLegalAdmin == true;

    if (taskAlert == null && (paymentAlert == null || !isLegalAdmin)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripeColor, width: 4)),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
}
