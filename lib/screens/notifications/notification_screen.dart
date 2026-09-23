import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../models/user.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constant.dart';
import '../../widgets/shimmer_loading.dart';
import '../login_screen.dart';
import 'helpers/notification_helpers.dart';
import 'widgets/notification_header.dart';
import 'widgets/notification_search_bar.dart';
import 'widgets/notification_filter_chips.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_dialogs.dart';

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

    if (mounted) {
      setState(() => _currentUser = user);
    }
    await _loadNotifications();
    await _loadUnreadCount();
  }

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        filter: _currentFilter,
      );
      if (mounted) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
        widget.onUnreadCountChanged?.call(count);
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════
  // RESPONSE HANDLERS
  // ═══════════════════════════════════════════════════

  Future<void> _handleNotificationResponse(NotificationModel notification) async {
    NotificationDialogs.showLoadingDialog(context, 'Memproses response...', color: Constants.accentColor);

    try {
      final result = await _notificationService.handleResponse(notification.id);
      if (mounted) {
        Navigator.pop(context);
        if (result.success) {
          NotificationDialogs.showResponseSuccessDialog(
            context,
            message: result.message,
            action: result.action ?? 'view',
            notification: notification,
          );
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
    final confirmed = await NotificationDialogs.showPmConfirmDialog(context, notification);
    if (confirmed != true) return;

    if (!mounted) return;
    NotificationDialogs.showLoadingDialog(context, 'Merekam Marketing response...', color: Constants.marketingColor);

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
    int targetIndex = _filteredNotifications.indexWhere((n) =>
        n.orderId == viewOnlyNotif.orderId &&
        n.requiresActionResponse &&
        !n.isResponded);

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

    _markAsRead(viewOnlyNotif);

    final offset = (targetIndex * 192.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );

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
            NotificationHeader(
              unreadCount: _unreadCount,
              onRefresh: () {
                _loadNotifications();
                _loadUnreadCount();
              },
              onMarkAllAsRead: _markAllAsRead,
            ),
            NotificationSearchBar(
              controller: _searchController,
              searchQuery: _searchQuery,
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            NotificationFilterChips(
              currentFilter: _currentFilter,
              onFilterChanged: _changeFilter,
            ),
            Expanded(child: _buildNotificationsList()),
          ],
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
            Icon(Icons.notifications_off_outlined, size: 64, color: Constants.textLight.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Tidak ada notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.textMedium)),
            const SizedBox(height: 6),
            const Text('Semua tugas sudah ditangani!', style: TextStyle(fontSize: 13, color: Constants.textLight)),
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
        itemBuilder: (context, index) {
          final notif = list[index];
          final hasUnresponded = _notifications.any(
            (n) => n.orderId == notif.orderId && n.requiresActionResponse && !n.isResponded,
          );

          return NotificationCard(
            notification: notif,
            isHighlighted: _highlightedIndex == index,
            currentUser: _currentUser,
            hasUnrespondedTask: hasUnresponded,
            onCardTap: () => _markAsRead(notif),
            onAction: () => _handleNotificationResponse(notif),
            onPmAction: () => _handlePmResponse(notif),
            onViewTask: () => _scrollToNotification(notif),
          );
        },
      ),
    );
  }
}
