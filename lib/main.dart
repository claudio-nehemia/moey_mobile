import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/notification_screen.dart';
import 'services/auth_service.dart';
import 'utils/constant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOEY Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Constants.primaryColor),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        // Navigate to notifications
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          ),
        );
      } else {
        // Navigate to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_active,
              size: 100,
              color: Constants.accentColor,
            ),
            const SizedBox(height: 24),
            Text(
              'MOEY MOBILE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Constants.primaryColor,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notification System',
              style: TextStyle(
                fontSize: 16,
                color: Constants.textLight,
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Constants.accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
