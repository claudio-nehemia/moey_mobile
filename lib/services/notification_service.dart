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
    return NotificationResponse(
      currentPage: json['current_page'] ?? 1,
      data: (json['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList(),
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