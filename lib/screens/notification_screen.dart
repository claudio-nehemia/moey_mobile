import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/constant.dart';
import '../widgets/shimmer_loading.dart';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  final ValueChanged<int>? onUnreadCountChanged;
  const NotificationScreen({super.key, this.onUnreadCountChanged});

  @override
  State<NotificationScreen> createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<NotificationModel> _notifications = [];
  User? _currentUser;
  int _unreadCount = 0;
  bool _isLoading = true;
  String _currentFilter = 'all';
  int _currentPage = 1;
  Timer? _pollTimer;
  String _searchQuery = '';
  int? _highlightedIndex;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _loadUserAndNotifications();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadNotifications(showLoading: false);
      _loadUnreadCount();
    });
  }

  Future<void> _loadUserAndNotifications() async {
    final user = await _authService.getCurrentUser();
    setState(() => _currentUser = user);
    await _loadNotifications();
    await _loadUnreadCount();
  }

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        filter: _currentFilter,
      );
      setState(() {
        _notifications = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() => _unreadCount = count);
      widget.onUnreadCountChanged?.call(count);
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════
  // RESPONSE HANDLERS (unchanged logic)
  // ═══════════════════════════════════════════════════

  Future<void> _handleNotificationResponse(NotificationModel notification) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.all(50),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitThreeBounce(color: Constants.accentColor, size: 28),
              const SizedBox(height: 16),
              const Text('Memproses response...', style: TextStyle(fontSize: 14, color: Constants.textMedium)),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _notificationService.handleResponse(notification.id);
      if (mounted) {
        Navigator.pop(context);
        if (result.success) {
          _showResponseDialog(result.message, result.action ?? 'view', notification);
          await _loadNotifications();
          await _loadUnreadCount();
        } else {
          _showSnackBar(result.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _handlePmResponse(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Constants.marketingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.supervisor_account, color: Constants.marketingColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Marketing Response', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Text(
          'Konfirmasi bahwa Anda sudah mereview dan menyetujui ${notification.title}?',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: TextStyle(color: Constants.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.marketingColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.all(50),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Constants.cardColor, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitThreeBounce(color: Constants.marketingColor, size: 28),
              const SizedBox(height: 16),
              const Text('Merekam Marketing response...', style: TextStyle(fontSize: 14, color: Constants.textMedium)),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _notificationService.handlePmResponse(notification.id);
      if (mounted) {
        Navigator.pop(context);
        if (result['success'] == true) {
          _showSnackBar(result['message'] ?? 'Marketing Response berhasil dicatat', isError: false);
          await _loadNotifications();
          await _loadUnreadCount();
        } else {
          _showSnackBar(result['message'] ?? 'Gagal merekam Marketing response', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  void _showResponseDialog(String message, String action, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Constants.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Constants.successColor, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Response Berhasil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Constants.textDark)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Constants.textMedium, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final success = await _notificationService.markAsRead(notification.id);
    if (success) {
      await _loadNotifications(showLoading: false);
      await _loadUnreadCount();
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success && mounted) {
      _showSnackBar('Semua notifikasi ditandai sudah dibaca', isError: false);
      await _loadNotifications();
      await _loadUnreadCount();
    }
  }

  void _changeFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _currentPage = 1;
    });
    _loadNotifications();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Constants.errorColor : Constants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  Color _getNotificationColor(String type) {
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
      case NotificationModel.typeApprovalMaterialRequest:
        return Constants.approvalColor;
      case NotificationModel.typeProjectManagementRequest:
        return Constants.pmColor;
      default:
        return Constants.konstruksiColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
        return Icons.assignment_outlined;
      case NotificationModel.typeSurveyScheduleRequest:
        return Icons.event_available_outlined;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeFinalDesignRequest:
        return Icons.design_services_outlined;
      case NotificationModel.typeDesignApproval:
        return Icons.verified_outlined;
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
      case NotificationModel.typeApprovalMaterialRequest:
        return Icons.check_circle_outline;
      case NotificationModel.typeProjectManagementRequest:
        return Icons.account_tree_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  String _formatResponseTime(String s) {
    try {
      final dt = DateTime.parse(s);
      return '${dt.day}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  // ═══════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════

  // Filtered list for search
  List<NotificationModel> get _filteredNotifications {
    if (_searchQuery.isEmpty) return _notifications;
    final q = _searchQuery.toLowerCase();
    return _notifications.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.message.toLowerCase().contains(q) ||
          (n.order?.namaProject.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _scrollToNotification(NotificationModel viewOnlyNotif) {
    // Check if there is an unresponded task for this order
    int targetIndex = _filteredNotifications.indexWhere((n) =>
        n.orderId == viewOnlyNotif.orderId &&
        n.requiresActionResponse &&
        !n.isResponded);

    // If no unresponded task, look for responded task
    if (targetIndex == -1) {
      targetIndex = _filteredNotifications.indexWhere((n) =>
          n.orderId == viewOnlyNotif.orderId &&
          n.requiresActionResponse &&
          n.isResponded);
    }

    if (targetIndex == -1) {
      _showSnackBar('Data tugas tidak ditemukan di halaman ini', isError: false);
      return;
    }

    // Mark as read
    _markAsRead(viewOnlyNotif);

    // Estimated card height ~180px
    final offset = (targetIndex * 192.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );

    // Highlight for 5 seconds
    setState(() => _highlightedIndex = targetIndex);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _highlightedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Text(
            'Notifikasi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Constants.textDark),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Constants.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () { _loadNotifications(); _loadUnreadCount(); },
            child: Icon(Icons.refresh_rounded, color: Constants.textLight, size: 22),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _markAllAsRead,
            child: Text(
              'Tandai Semua',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Constants.surveyColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 14, color: Constants.textDark),
        decoration: InputDecoration(
          hintText: 'Cari notifikasi...',
          hintStyle: TextStyle(fontSize: 14, color: Constants.textLight.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, size: 20, color: Constants.textLight),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(Icons.close, size: 18, color: Constants.textLight),
                )
              : null,
          filled: true,
          fillColor: Constants.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Constants.primaryColor.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          _buildChip('Semua', 'all'),
          const SizedBox(width: 8),
          _buildChip('Belum Dibaca', 'unread'),
          const SizedBox(width: 8),
          _buildChip('Sudah Dibaca', 'read'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final active = _currentFilter == value;
    return GestureDetector(
      onTap: () => _changeFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Constants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Constants.primaryColor : Constants.textLight.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : Constants.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const NotificationSkeleton();
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 72, color: Constants.textLight.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Tidak ada notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Constants.textMedium)),
            const SizedBox(height: 6),
            Text('Semua tugas sudah ditangani!', style: TextStyle(fontSize: 13, color: Constants.textLight)),
          ],
        ),
      );
    }

    final list = _filteredNotifications;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadNotifications();
        await _loadUnreadCount();
      },
      color: Constants.accentColor,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildNotificationCard(list[index], index: index),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, {int index = 0}) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);
    final createdAt = DateTime.tryParse(notification.createdAt) ?? DateTime.now();
    final isUnread = !notification.isRead;
    final isResponded = notification.isResponded;
    final requiresAction = notification.requiresActionResponse;
    final isHighlighted = _highlightedIndex == index;

    return GestureDetector(
      onTap: () => _markAsRead(notification),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Constants.infoColor.withOpacity(0.12)
              : (isResponded ? Constants.successColor.withOpacity(0.03) : Constants.cardColor),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? Constants.infoColor.withOpacity(0.5)
                : (isResponded
                    ? Constants.successColor.withOpacity(0.2)
                    : (isUnread ? color.withOpacity(0.25) : Constants.secondaryColor.withOpacity(0.3))),
            width: isHighlighted ? 2 : (isUnread ? 1.5 : 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row: icon + content + unread dot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isResponded ? Constants.successColor.withOpacity(0.1) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isResponded ? Icons.check_circle_outline : icon,
                    size: 22,
                    color: isResponded ? Constants.successColor : color,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: Constants.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(fontSize: 13, color: Constants.textMedium, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Project chip + Time
            Row(
              children: [
                if (notification.order != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.order!.namaProject,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 10),
                Icon(Icons.access_time, size: 13, color: Constants.textLight),
                const SizedBox(width: 3),
                Text(_formatTimeAgo(createdAt), style: TextStyle(fontSize: 11, color: Constants.textLight)),
              ],
            ),

            // Response info banners
            if (requiresAction && isResponded) ...[
              if (notification.responseInfo != null) ...[
                const SizedBox(height: 10),
                _buildResponseBanner(
                  '✓ Direspon',
                  notification.responseInfo!['by'],
                  notification.responseInfo!['time'],
                  Constants.successColor,
                ),
              ],
              if (notification.pmResponseInfo != null) ...[
                const SizedBox(height: 6),
                _buildResponseBanner(
                  '✓ Marketing Response',
                  notification.pmResponseInfo!['by'],
                  notification.pmResponseInfo!['time'],
                  Constants.marketingColor,
                ),
              ],
            ],

            // Action buttons
            if (requiresAction && !isResponded) ...[
              const SizedBox(height: 12),
              // Kepala Marketing: only Marketing Response button
              // Staff: only regular Response button
              if (_currentUser != null && _currentUser!.isKepalaMarketing) ...[
                // PM only sees Marketing Response
                if (notification.pmResponseInfo == null)
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _handlePmResponse(notification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.marketingColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Marketing Response',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  _buildResponseBanner(
                    '✓ Marketing Response',
                    notification.pmResponseInfo!['by'],
                    notification.pmResponseInfo!['time'],
                    Constants.marketingColor,
                  ),
              ] else ...[
                // Staff sees regular response button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _handleNotificationResponse(notification),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      notification.actionText,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              // Show PM response info even when staff hasn't responded yet
              if (!(_currentUser?.isKepalaMarketing ?? false) && notification.pmResponseInfo != null) ...[
                const SizedBox(height: 8),
                _buildResponseBanner(
                  '✓ Marketing Response',
                  notification.pmResponseInfo!['by'],
                  notification.pmResponseInfo!['time'],
                  Constants.marketingColor,
                ),
              ],
            ],

            // Responded notification - show PM button if PM hasn't responded
            if (requiresAction &&
                isResponded &&
                _currentUser != null &&
                _currentUser!.isKepalaMarketing &&
                notification.pmResponseInfo == null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => _handlePmResponse(notification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.marketingColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Marketing Response',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            // View-only button → Check Response / Menuju Tugas (scroll to related target card)
            if (!requiresAction) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  // Determine label based on related action notification status
                  bool isRelatedResponded = false;
                  bool hasRelatedAction = false;
                  
                  // Search all original notifications to determine status accurately
                  for (final n in _notifications) {
                    if (n.orderId == notification.orderId && n.requiresActionResponse) {
                      hasRelatedAction = true;
                      if (n.isResponded) {
                        isRelatedResponded = true;
                        break; // Responded takes precedence if both exist, or we just need to know it's done
                      }
                    }
                  }

                  // If there is an unresponded action, show Menuju Tugas. Otherwise if responded, Check Response.
                  // If we can't determine, default to Menuju Tugas.
                  final hasUnresponded = _notifications.any((n) => n.orderId == notification.orderId && n.requiresActionResponse && !n.isResponded);
                  final buttonLabel = hasUnresponded ? 'Menuju Tugas' : 'Check Response';
                  final buttonIcon = hasUnresponded ? Icons.arrow_forward : Icons.find_in_page_outlined;

                  return SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _scrollToNotification(notification),
                      icon: Icon(buttonIcon, size: 16, color: Constants.infoColor),
                      label: Text(buttonLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Constants.infoColor,
                        side: BorderSide(color: Constants.infoColor.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                }
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseBanner(String label, String? by, String? time, Color color) {
    final parts = <String>[];
    if (by != null) parts.add('oleh $by');
    if (time != null) parts.add('— ${_formatResponseTime(time)}');
    final detail = parts.join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: color),
                children: [
                  TextSpan(text: label.replaceAll('✓ ', ''), style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (detail.isNotEmpty) TextSpan(text: '  $detail', style: TextStyle(color: color.withOpacity(0.8))),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
