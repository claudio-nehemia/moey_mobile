import 'package:flutter/material.dart';
import '../utils/constant.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';
import 'orders_list_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  int _unreadCount = 0;
  late PageController _pageController;
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isUserLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pageController = PageController(initialPage: _currentIndex);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isUserLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUserLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool get _isCS => _currentUser?.isCustomerService == true;

  List<Widget> _buildPages() {
    return [
      HomeScreen(onNavigateToNotifications: () => _switchTab(1)),
      NotificationScreen(
        onUnreadCountChanged: (count) {
          if (mounted) setState(() => _unreadCount = count);
        },
      ),
      if (_isCS) const OrdersListScreen(),
      const TasksScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserLoaded) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Constants.primaryColor),
        ),
      );
    }

    final pages = _buildPages();
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // swipe disabled, only nav
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Constants.cardColor,
        border: Border(
          top: BorderSide(color: Constants.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildNavItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    if (_isCS) {
      return [
        _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
        _buildNavItem(1, Icons.notifications_outlined, Icons.notifications_rounded, 'Notifikasi', badge: _unreadCount),
        _buildNavItem(2, Icons.business_center_outlined, Icons.business_center_rounded, 'Orders'),
        _buildNavItem(3, Icons.assignment_outlined, Icons.assignment_rounded, 'Tugas'),
        _buildNavItem(4, Icons.person_outline, Icons.person_rounded, 'Profile'),
      ];
    } else {
      return [
        _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
        _buildNavItem(1, Icons.notifications_outlined, Icons.notifications_rounded, 'Notifikasi', badge: _unreadCount),
        _buildNavItem(2, Icons.assignment_outlined, Icons.assignment_rounded, 'Tugas'),
        _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'Profile'),
      ];
    }
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? Constants.primaryColor.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    size: 22,
                    color: isActive ? Constants.primaryColor : Constants.textLight,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Constants.errorColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Constants.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
