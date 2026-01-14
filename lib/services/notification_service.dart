import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../utils/constant.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  // Get all notifications
  Future<NotificationResponse> getNotifications({
    int page = 1,
    int perPage = 20,
    String filter = 'all', // all, unread, read
  }) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/notifications?page=$page&per_page=$perPage&filter=$filter'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationResponse.fromJson(data['data']);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return 0;
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mobile/notifications/$notificationId/mark-as-read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mobile/notifications/mark-all-as-read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Handle notification response
  Future<NotificationResponseResult> handleResponse(int notificationId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mobile/notifications/$notificationId/handle-response'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationResponseResult.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to handle notification');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Handle PM Response
  Future<Map<String, dynamic>> handlePmResponse(int notificationId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mobile/notifications/$notificationId/pm-response'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 403 || response.statusCode == 404) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to handle PM response');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// 🔥 FCM: UPDATE FCM TOKEN TO BACKEND
  /// Dipanggil oleh FCMService setelah dapat token dari Firebase
  /// ═══════════════════════════════════════════════════════════════
  Future<bool> updateFCMToken(String fcmToken) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        print('⚠️  [NotificationService] No auth token, skipping FCM token update');
        return false;
      }

      print('📤 [NotificationService] Sending FCM token to backend...');

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mobile/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ [NotificationService] FCM token updated successfully');
        return true;
      } else {
        print('❌ [NotificationService] Failed to update FCM token: ${response.statusCode}');
        print('❌ [NotificationService] Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ [NotificationService] Error updating FCM token: $e');
      return false;
    }
  }

}

// Response model for paginated notifications
class NotificationResponse {
  final int currentPage;
  final List<NotificationModel> data;
  final int total;
  final int perPage;
  final int lastPage;

  NotificationResponse({
    required this.currentPage,
    required this.data,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final notifications = (json['data'] as List)
        .map((item) => NotificationModel.fromJson(item))
        .toList();
    
    // 🔥 DEBUG: Log workplan notifications
    for (var notif in notifications) {
      if (notif.type == NotificationModel.typeWorkplanRequest) {
        print('=== MOBILE WORKPLAN DEBUG ===');
        print('Notification ID: ${notif.id}');
        print('Order ID: ${notif.order?.id}');
        print('Has Moodboard: ${notif.order?.moodboard != null}');
        
        if (notif.order?.moodboard?.itemPekerjaans != null) {
          print('Moodboard ItemPekerjaans count: ${notif.order!.moodboard!.itemPekerjaans!.length}');
          
          for (var ip in notif.order!.moodboard!.itemPekerjaans!) {
            print('  ItemPekerjaan ID: ${ip.id}');
            if (ip.workplanItems != null) {
              print('  Workplan Items count: ${ip.workplanItems!.length}');
              if (ip.workplanItems!.isNotEmpty) {
                final first = ip.workplanItems!.first;
                print('  First Workplan response_time: ${first.responseTime}');
                print('  First Workplan response_by: ${first.responseBy}');
              }
            }
          }
        } else {
          print('Moodboard ItemPekerjaans: NULL');
        }
        
        print('isResponded: ${notif.isResponded}');
        print('responseInfo: ${notif.responseInfo}');
        print('=== END MOBILE DEBUG ===');
      }
    }
    
    return NotificationResponse(
      currentPage: json['current_page'] ?? 1,
      data: notifications,
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 20,
      lastPage: json['last_page'] ?? 1,
    );
  }
}

// Response result model
class NotificationResponseResult {
  final bool success;
  final String message;
  final String? action; // 'create', 'view', null
  final Map<String, dynamic>? data;

  NotificationResponseResult({
    required this.success,
    required this.message,
    this.action,
    this.data,
  });

  factory NotificationResponseResult.fromJson(Map<String, dynamic> json) {
    return NotificationResponseResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      action: json['action'],
      data: json['data'],
    );
  }
}