import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
  Future<Map<String, dynamic>> getSlipGajiDetail(int uuidOrId, int tahun) async {
    // wait, keep it as is, or we can use arguments
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/slipgaji/$uuidOrId/$tahun'),
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

  // Fetch training sessions
  Future<Map<String, dynamic>> getMyTrainings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/pelatihan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat pelatihan: ${e.toString()}'};
    }
  }

  // Fetch resignation status
  Future<Map<String, dynamic>> getResignStatus() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/resign'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat status resign: ${e.toString()}'};
    }
  }

  // Submit resignation request
  Future<Map<String, dynamic>> submitResign({
    required String tanggalEfektif,
    required String alasan,
    String? filePath,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final uri = Uri.parse('${Constants.baseUrl}/mobile/resign');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['tanggal_efektif'] = tanggalEfektif;
      request.fields['alasan'] = alasan;

      if (filePath != null && filePath.isNotEmpty) {
        final ext = filePath.split('.').last.toLowerCase();
        MediaType mediaType;
        if (ext == 'pdf') {
          mediaType = MediaType('application', 'pdf');
        } else {
          mediaType = MediaType('image', ext == 'png' ? 'png' : 'jpeg');
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            contentType: mediaType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim pengajuan: ${e.toString()}'};
    }
  }
}
