import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../config/environment.dart';
import '../utils/constant.dart';
import 'login_screen.dart';
import 'my_training_screen.dart';
import 'request_resign_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
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

    if (mounted) setState(() { _currentUser = user; _isLoading = false; });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: TextStyle(color: Constants.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _authService.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Constants.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('M', style: TextStyle(color: Constants.accentColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppConfig.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Constants.textDark)),
              const SizedBox(height: 4),
              Text('Version ${AppConfig.appVersion}', style: TextStyle(fontSize: 13, color: Constants.textLight)),
              const SizedBox(height: 16),
              Text(AppConfig.companyName, style: const TextStyle(fontSize: 14, color: Constants.textMedium)),
              const SizedBox(height: 6),
              Text('Sistem manajemen notifikasi\nuntuk tim interior design', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Constants.textLight, height: 1.5)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Constants.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: Constants.accentColor)),
      );
    }

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMenuSection(),
            const SizedBox(height: 40),
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _currentUser?.name ?? 'User';
    final email = _currentUser?.email ?? '';
    final isKM = _currentUser?.isKepalaMarketing ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Constants.cardColor,
        border: Border(
          bottom: BorderSide(color: Constants.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar - Clean flat circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Constants.primaryColor.withOpacity(0.06),
                border: Border.all(color: Constants.borderColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  _getInitials(name),
                  style: const TextStyle(color: Constants.primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Constants.textDark, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w400),
            ),
            if (isKM) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Constants.primaryColor.withOpacity(0.15)),
                ),
                child: const Text(
                  'Kepala Marketing',
                  style: TextStyle(color: Constants.primaryColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Constants.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Constants.borderColor),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.info_outline,
              iconColor: Constants.infoColor,
              title: 'Tentang Aplikasi',
              subtitle: 'Informasi versi & perusahaan',
              onTap: _showAboutDialog,
            ),
            const Divider(height: 1, indent: 64, color: Constants.borderColor),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              iconColor: Constants.accentColor,
              title: 'Pengaturan Notifikasi',
              subtitle: 'Kelola notifikasi push',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pengaturan notifikasi dapat dikelola dari Settings HP Anda'),
                    backgroundColor: Constants.infoColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 64, color: Constants.borderColor),
            _buildMenuItem(
              icon: Icons.school_outlined,
              iconColor: Colors.pink,
              title: 'Pelatihan Saya',
              subtitle: 'Riwayat & sertifikasi pelatihan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTrainingScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 64, color: Constants.borderColor),
            _buildMenuItem(
              icon: Icons.exit_to_app_rounded,
              iconColor: Colors.redAccent,
              title: 'Pengajuan Resign',
              subtitle: 'Formulir pengunduran diri',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestResignScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 64, color: Constants.borderColor),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              iconColor: Constants.errorColor,
              title: 'Logout',
              subtitle: 'Keluar dari aplikasi',
              onTap: _logout,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Constants.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Constants.errorColor : Constants.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Constants.textMedium)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Constants.textLight.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          AppConfig.companyName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.textMedium),
        ),
        const SizedBox(height: 4),
        Text(
          'Version ${AppConfig.appVersion}',
          style: const TextStyle(fontSize: 11, color: Constants.textLight),
        ),
      ],
    );
  }
}
