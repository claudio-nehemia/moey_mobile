import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../utils/constant.dart';

class AktivitasScreen extends StatefulWidget {
  const AktivitasScreen({super.key});

  @override
  State<AktivitasScreen> createState() => _AktivitasScreenState();
}

class _AktivitasScreenState extends State<AktivitasScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<dynamic> _activityList = [];

  // Form Fields
  final TextEditingController _activityController = TextEditingController();
  File? _selfieFile;

  @override
  void initState() {
    super.initState();
    _loadActivityList();
  }

  Future<void> _loadActivityList() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/aktivitas'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _activityList = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading activity list: $e");
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _selfieFile = File(photo.path);
        });
      }
    } catch (e) {
      print("Error picking photo: $e");
    }
  }

  Future<void> _submitActivity() async {
    if (await SecurityService.checkMockLocation(context)) {
      return;
    }
    if (_activityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan aktivitas kerja harus diisi.')),
      );
      return;
    }
    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajib menyertakan foto selfie bukti aktivitas kerja.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final token = await _authService.getToken();
      final uri = Uri.parse('${Constants.baseUrl}/mobile/aktivitas');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['aktivitas'] = _activityController.text;
      request.fields['lokasi'] = '${position.latitude},${position.longitude}';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selfieFile!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("DEBUG_AKTIVITAS: Status code = ${response.statusCode}");
      print("DEBUG_AKTIVITAS: Response body = ${response.body}");

      final responseData = jsonDecode(response.body);

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivitas kerja berhasil dilaporkan!'), backgroundColor: Colors.green),
        );
        _activityController.clear();
        setState(() {
          _selfieFile = null;
        });
        Navigator.pop(context);
        _loadActivityList();
      } else {
        String errorMsg = responseData['message'] ?? 'Gagal memproses aktivitas.';
        if (responseData['errors'] != null) {
          final Map<String, dynamic> errors = responseData['errors'];
          final List<String> allErrors = [];
          errors.forEach((key, value) {
            if (value is List) {
              allErrors.addAll(value.map((e) => e.toString()));
            } else {
              allErrors.add(value.toString());
            }
          });
          if (allErrors.isNotEmpty) {
            errorMsg = '$errorMsg: ${allErrors.join(", ")}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e, stacktrace) {
      print("DEBUG_AKTIVITAS: Exception = $e");
      print("DEBUG_AKTIVITAS: Stacktrace = $stacktrace");
      setState(() => _isLoading = false);
    }
  }

  void _showFormDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Laporkan Laporan Aktivitas Harian (Daily Activity Log)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                ),
                const SizedBox(height: 16),

                // Aktivitas
                TextField(
                  controller: _activityController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Deskripsi Detail Aktivitas Kerja', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                // Camera Selfie
                GestureDetector(
                  onTap: () async {
                    await _takeSelfie();
                    setModalState(() {});
                  },
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _selfieFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selfieFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey),
                              SizedBox(height: 6),
                              Text('Ambil Selfie Bukti Aktivitas Kerja', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _submitActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('KIRIM LAPORAN'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Aktivitas Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormDialog,
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Tambah Laporan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadActivityList,
              child: _activityList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada log aktivitas harian',
                            style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _activityList.length,
                      itemBuilder: (context, index) {
                        final item = _activityList[index];
                        final String imgUrl = item['foto'] != null 
                            ? '${Constants.baseUrl.replaceAll('/api', '')}/storage/uploads/aktivitas/${item['foto']}'
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Constants.borderColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imgUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(imgUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, o, s) => Container(width: 64, height: 64, color: Colors.grey.shade200)),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['aktivitas'] ?? '',
                                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tanggal: ${item['tanggal']} | Jam: ${item['jam']}',
                                      style: const TextStyle(fontSize: 10, color: Constants.textLight),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
