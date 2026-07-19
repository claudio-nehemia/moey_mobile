import 'dart:convert';
import 'package:http/http.dart' as http;
import './auth_service.dart';
import '../utils/constant.dart';

class PayrollService {
  final AuthService _authService = AuthService();

  // Fetch list of published payslips
  Future<Map<String, dynamic>> getSlipGajiList() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/slipgaji'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat data: ${e.toString()}'};
    }
  }

  // Fetch details of a specific payslip
  Future<Map<String, dynamic>> getSlipGajiDetail(int bulan, int tahun) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/slipgaji/$bulan/$tahun'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat detail slip gaji: ${e.toString()}'};
    }
  }
}
