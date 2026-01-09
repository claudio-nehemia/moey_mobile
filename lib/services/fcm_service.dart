   import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as local_notif;
import 'package:flutter/material.dart';
import '../main.dart' show NavigationService;
import 'notification_service.dart';
import 'auth_service.dart';

   /// 🔥 TOP-LEVEL FUNCTION untuk handle background messages
   /// HARUS di luar class dan di-annotate dengan @pragma
   @pragma('vm:entry-point')
   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // Initialize Firebase jika belum
     await Firebase.initializeApp();
     
     print('📱 [FCM Background] Message received: ${message.messageId}');
     print('📱 [FCM Background] Title: ${message.notification?.title}');
     print('📱 [FCM Background] Body: ${message.notification?.body}');
     print('📱 [FCM Background] Data: ${message.data}');
     
     // You can show local notification here if needed
   }

   /// 🔥 FCM Service - Singleton Pattern
   /// Handles all Firebase Cloud Messaging operations
   class FCMService {
     // Singleton instance
     static final FCMService _instance = FCMService._internal();
     factory FCMService() => _instance;
     FCMService._internal();

     // Dependencies
     final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
     final local_notif.FlutterLocalNotificationsPlugin _localNotifications = 
         local_notif.FlutterLocalNotificationsPlugin();
     final NotificationService _notificationService = NotificationService();
     final AuthService _authService = AuthService();
     
     // State
     String? _fcmToken;
     bool _isInitialized = false;
     
     // Stream controller for notification taps
     final StreamController<Map<String, dynamic>> _notificationTapController = 
         StreamController<Map<String, dynamic>>.broadcast();
     
     // Expose stream for listening to notification taps
     Stream<Map<String, dynamic>> get onNotificationTap => 
         _notificationTapController.stream;

     /// ═══════════════════════════════════════════════════════════════
     /// INITIALIZE FCM SERVICE
     /// Call this in main() BEFORE runApp()
     /// ═══════════════════════════════════════════════════════════════
     Future<void> initialize() async {
       if (_isInitialized) {
         print('⚠️  [FCM] Already initialized');
         return;
       }

       try {
         print('🚀 [FCM] Initializing FCM Service...');

         // 1. Initialize Firebase
         await Firebase.initializeApp();
         print('✅ [FCM] Firebase initialized');

         // 2. Request notification permission (iOS auto-prompts, Android needs manual)
         NotificationSettings settings = await _firebaseMessaging.requestPermission(
           alert: true,
           announcement: false,
           badge: true,
           carPlay: false,
           criticalAlert: false,
           provisional: false,
           sound: true,
         );

         if (settings.authorizationStatus == AuthorizationStatus.authorized) {
           print('✅ [FCM] User granted notification permission');
         } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
           print('⚠️  [FCM] User granted provisional notification permission');
         } else {
           print('❌ [FCM] User declined notification permission');
         }

         // 3. Initialize local notifications for foreground display
         await _initializeLocalNotifications();
         print('✅ [FCM] Local notifications initialized');

         // 4. Setup message handlers (foreground, background, terminated)
         _setupMessageHandlers();
         print('✅ [FCM] Message handlers setup');

         // 5. Set foreground notification presentation options (iOS)
         await _firebaseMessaging.setForegroundNotificationPresentationOptions(
           alert: true,
           badge: true,
           sound: true,
         );
         print('✅ [FCM] Foreground presentation options set');

         _isInitialized = true;
         print('✅ [FCM] FCM Service initialized successfully');
       } catch (e, stackTrace) {
         print('❌ [FCM] Error initializing FCM: $e');
         print('❌ [FCM] StackTrace: $stackTrace');
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// SETUP AFTER USER LOGIN
     /// Call this after successful login to get & save FCM token
     /// ═══════════════════════════════════════════════════════════════
     Future<void> setupAfterLogin() async {
       try {
         print('🔐 [FCM] Setting up FCM after login...');
         
         // Get FCM token and send to backend
         await _getFCMToken();
         
         // Listen to token refresh
         _firebaseMessaging.onTokenRefresh.listen((newToken) {
           print('🔄 [FCM] Token refreshed: $newToken');
           _fcmToken = newToken;
           _sendTokenToBackend(newToken);
         });
         
         print('✅ [FCM] Setup after login complete');
       } catch (e) {
         print('❌ [FCM] Error setting up FCM after login: $e');
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// INITIALIZE LOCAL NOTIFICATIONS
     /// For showing notifications when app is in foreground
     /// ═══════════════════════════════════════════════════════════════
     Future<void> _initializeLocalNotifications() async {
       // Android settings
       const local_notif.AndroidInitializationSettings androidSettings = 
           local_notif.AndroidInitializationSettings('@mipmap/ic_launcher');

       // iOS settings
       const local_notif.DarwinInitializationSettings iosSettings = 
           local_notif.DarwinInitializationSettings(
             requestAlertPermission: true,
             requestBadgePermission: true,
             requestSoundPermission: true,
           );

       // Combined settings
       const local_notif.InitializationSettings initSettings = local_notif.InitializationSettings(
         android: androidSettings,
         iOS: iosSettings,
       );

       // Initialize with callback for notification taps
       await _localNotifications.initialize(
         initSettings,
         onDidReceiveNotificationResponse: (local_notif.NotificationResponse response) {
           _onNotificationTapped(response);
         },
       );

       // Create Android notification channel
       if (Platform.isAndroid) {
         final local_notif.AndroidNotificationChannel channel = local_notif.AndroidNotificationChannel(
           'moey_notifications', // ID (must match AndroidManifest.xml)
           'MOEY Notifications', // Name (displayed in settings)
           description: 'Notification channel for MOEY app notifications',
           importance: local_notif.Importance.high,
           playSound: true,
           enableVibration: true,
         );

         await _localNotifications
             .resolvePlatformSpecificImplementation<
                 local_notif.AndroidFlutterLocalNotificationsPlugin>()
             ?.createNotificationChannel(channel);
         
         print('✅ [FCM] Android notification channel created: ${channel.id}');
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// SETUP MESSAGE HANDLERS
     /// Handle foreground, background, and terminated state messages
     /// ═══════════════════════════════════════════════════════════════
     void _setupMessageHandlers() {
       // ──────────────────────────────────────────────────────────
       // 1. BACKGROUND MESSAGE HANDLER
       // When app is in background but not terminated
       // ──────────────────────────────────────────────────────────
       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

       // ──────────────────────────────────────────────────────────
       // 2. FOREGROUND MESSAGE HANDLER
       // When app is open and in use
       // ──────────────────────────────────────────────────────────
       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
         print('📨 [FCM Foreground] Message received!');
         print('📨 [FCM Foreground] Title: ${message.notification?.title}');
         print('📨 [FCM Foreground] Body: ${message.notification?.body}');
         print('📨 [FCM Foreground] Data: ${message.data}');

         // Show local notification in foreground
         if (message.notification != null) {
           _showLocalNotification(message);
         }
       });

       // ──────────────────────────────────────────────────────────
       // 3. NOTIFICATION OPENED APP FROM BACKGROUND
       // User tapped notification while app was in background
       // ──────────────────────────────────────────────────────────
       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
         print('🔔 [FCM] Notification opened from background!');
         print('🔔 [FCM] Data: ${message.data}');
         _handleNotificationTap(message.data);
       });

       // ──────────────────────────────────────────────────────────
       // 4. NOTIFICATION OPENED APP FROM TERMINATED STATE
       // User tapped notification while app was completely closed
       // ──────────────────────────────────────────────────────────
       _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
         if (message != null) {
           print('🔔 [FCM] App opened from terminated state via notification');
           print('🔔 [FCM] Data: ${message.data}');
           // Delay to ensure app is fully loaded
           Future.delayed(const Duration(seconds: 1), () {
             _handleNotificationTap(message.data);
           });
         }
       });
     }

     /// ═══════════════════════════════════════════════════════════════
     /// GET FCM TOKEN
     /// Request token from Firebase and send to backend
     /// ═══════════════════════════════════════════════════════════════
     Future<String?> _getFCMToken() async {
       try {
         // Request token from Firebase
         _fcmToken = await _firebaseMessaging.getToken();
         
         if (_fcmToken != null) {
           print('🎟️  [FCM] Token obtained: $_fcmToken');
           
           // Send to backend for storage
           await _sendTokenToBackend(_fcmToken!);
         } else {
           print('⚠️  [FCM] Failed to get FCM token');
         }
         
         return _fcmToken;
       } catch (e) {
         print('❌ [FCM] Error getting FCM token: $e');
         return null;
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// SEND FCM TOKEN TO BACKEND
     /// Store token in Laravel database for push notifications
     /// ═══════════════════════════════════════════════════════════════
     Future<void> _sendTokenToBackend(String token) async {
       try {
         // Check if user is logged in
         final isLoggedIn = await _authService.isLoggedIn();
         
         if (!isLoggedIn) {
           print('⚠️  [FCM] User not logged in, skipping token update');
           return;
         }

         // Send token to backend API
         final success = await _notificationService.updateFCMToken(token);
         
         if (success) {
           print('✅ [FCM] Token sent to backend successfully');
         } else {
           print('⚠️  [FCM] Failed to send token to backend');
         }
       } catch (e) {
         print('❌ [FCM] Error sending FCM token to backend: $e');
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// SHOW LOCAL NOTIFICATION
     /// Display notification when app is in foreground
     /// ═══════════════════════════════════════════════════════════════
     Future<void> _showLocalNotification(RemoteMessage message) async {
       final notification = message.notification;
       
       if (notification == null) return;

       try {
         await _localNotifications.show(
           notification.hashCode, // Unique ID
           notification.title,
           notification.body,
           local_notif.NotificationDetails(
             android: local_notif.AndroidNotificationDetails(
               'moey_notifications', // Must match channel ID
               'MOEY Notifications',
               channelDescription: 'Notification channel for MOEY app',
               importance: local_notif.Importance.high,
               priority: local_notif.Priority.high,
               icon: '@mipmap/ic_launcher',
               playSound: true,
               enableVibration: true,
               ticker: notification.title,
             ),
             iOS: const local_notif.DarwinNotificationDetails(
               presentAlert: true,
               presentBadge: true,
               presentSound: true,
             ),
           ),
           payload: message.data.toString(),
         );
         
         print('✅ [FCM] Local notification displayed');
       } catch (e) {
         print('❌ [FCM] Error showing local notification: $e');
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// HANDLE NOTIFICATION TAP
     /// Called when user taps a notification
     /// ═══════════════════════════════════════════════════════════════
     void _onNotificationTapped(local_notif.NotificationResponse response) {
       print('🔔 [FCM] Notification tapped!');
       print('🔔 [FCM] Payload: ${response.payload}');
       
       // Navigate to notification screen
       _navigateToNotifications();
     }

     void _handleNotificationTap(Map<String, dynamic> data) {
       print('🔔 [FCM] Handling notification tap');
       print('🔔 [FCM] Data: $data');
       
       // Broadcast to stream (if other parts of app want to listen)
       _notificationTapController.add(data);
       
       // Navigate to notification screen
       _navigateToNotifications();
     }

     /// ═══════════════════════════════════════════════════════════════
     /// NAVIGATE TO NOTIFICATIONS
     /// Navigate to NotificationScreen using global navigator
     /// ═══════════════════════════════════════════════════════════════
     void _navigateToNotifications() {
       // Use global navigator key to navigate
       final context = NavigationService.navigatorKey.currentContext;
       
       if (context != null) {
         // Navigate to notification screen
         // Adjust route name based on your routing setup
         Navigator.of(context).pushNamedAndRemoveUntil(
           '/notifications',
           (route) => false,
         );
       } else {
         print('⚠️  [FCM] Navigation context not available');
       }
     }

     /// ═══════════════════════════════════════════════════════════════
     /// PUBLIC GETTERS
     /// ═══════════════════════════════════════════════════════════════
     
     /// Get current FCM token
     String? get fcmToken => _fcmToken;
     
     /// Check if FCM is initialized
     bool get isInitialized => _isInitialized;
     
     /// Get Firebase Messaging instance (for advanced use)
     FirebaseMessaging get messaging => _firebaseMessaging;

     /// ═══════════════════════════════════════════════════════════════
     /// CLEANUP
     /// Call when app is disposed (optional)
     /// ═══════════════════════════════════════════════════════════════
     void dispose() {
       _notificationTapController.close();
     }
   }