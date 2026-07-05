import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constant.dart';
import 'auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  // Fetch data needed for create order form (marketings, drafters, desainers, jenis interiors)
  Future<Map<String, dynamic>> getCreateFormData() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/orders/form-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Gagal memuat data form dropdown');
    } catch (e) {
      throw Exception('Gagal memuat data: ${e.toString()}');
    }
  }

  // Submit a new order
  Future<Map<String, dynamic>> createOrder(
    Map<String, String> fields, {
    List<String>? momFilePaths,
    List<int>? userIds,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final uri = Uri.parse('${Constants.baseUrl}/mobile/orders');
      final request = http.MultipartRequest('POST', uri);

      // Add Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields.addAll(fields);

      // Add user ids (team members selection)
      if (userIds != null && userIds.isNotEmpty) {
        for (int i = 0; i < userIds.length; i++) {
          request.fields['user_ids[$i]'] = userIds[i].toString();
        }
      }

      // Add MOM Files if any
      if (momFilePaths != null && momFilePaths.isNotEmpty) {
        for (int i = 0; i < momFilePaths.length; i++) {
          final path = momFilePaths[i];
          final file = File(path);
          if (await file.exists()) {
            final multipartFile = await http.MultipartFile.fromPath(
              'mom_files[$i]',
              file.path,
            );
            request.files.add(multipartFile);
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal menyimpan order');
      }
    } catch (e) {
      throw Exception('Gagal mengirim order: ${e.toString()}');
    }
  }

  // Fetch list of orders visible to user (e.g. CS created orders)
  Future<List<dynamic>> getOrders() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
      }
      throw Exception('Gagal memuat daftar order');
    } catch (e) {
      throw Exception('Gagal memuat order: ${e.toString()}');
    }
  }

  // Fetch details of a single order
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Gagal memuat detail order');
    } catch (e) {
      throw Exception('Gagal memuat detail: ${e.toString()}');
    }
  }
}
