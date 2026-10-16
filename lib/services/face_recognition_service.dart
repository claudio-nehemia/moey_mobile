import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import './auth_service.dart';
import '../utils/constant.dart';

class FaceRecognitionService {
  final AuthService _authService = AuthService();

  // Get master face registration status and list
  Future<Map<String, dynamic>> getFaceStatus() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/face-recognition'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat status wajah: ${e.toString()}'};
    }
  }

  // Upload a master face image for face recognition
  Future<Map<String, dynamic>> uploadFace({
    required Uint8List bytes,
    required String filename,
    String direction = 'front',
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final uri = Uri.parse('${Constants.baseUrl}/mobile/face-recognition');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['directions.0'] = direction;

      String mimeSubtype = 'jpeg';
      final lowerName = filename.toLowerCase();
      if (lowerName.endsWith('.png')) {
        mimeSubtype = 'png';
      } else if (lowerName.endsWith('.webp')) {
        mimeSubtype = 'webp';
      } else if (lowerName.endsWith('.heic')) {
        mimeSubtype = 'heic';
      } else if (lowerName.endsWith('.heif')) {
        mimeSubtype = 'heif';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengunggah foto wajah: ${e.toString()}'};
    }
  }

  // Delete a specific face by ID
  Future<Map<String, dynamic>> deleteFace(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/mobile/face-recognition/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus foto wajah: ${e.toString()}'};
    }
  }

  // Delete all faces
  Future<Map<String, dynamic>> deleteAllFaces() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/mobile/face-recognition'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus semua data wajah: ${e.toString()}'};
    }
  }
}
