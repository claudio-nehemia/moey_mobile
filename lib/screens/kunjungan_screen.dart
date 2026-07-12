import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../utils/constant.dart';

class KunjunganScreen extends StatefulWidget {
  const KunjunganScreen({super.key});

  @override
  State<KunjunganScreen> createState() => _KunjunganScreenState();
}

class _KunjunganScreenState extends State<KunjunganScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<dynamic> _visitList = [];

  // Form Fields
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  File? _selfieFile;

  @override
  void initState() {
    super.initState();
    _loadVisitList();
  }

  Future<void> _loadVisitList() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/kunjungan'),
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
            _visitList = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading visit list: $e");
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

  Future<void> _submitVisit() async {
    if (_clientController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama instansi/client harus diisi.')),
      );
      return;
    }
    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajib menyertakan foto selfie bukti kunjungan.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final token = await _authService.getToken();
      final uri = Uri.parse('${Constants.baseUrl}/mobile/kunjungan');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      final DateTime now = DateTime.now();
      final String dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      request.fields['deskripsi'] = 'Client: ${_clientController.text}\nKeterangan: ${_keteranganController.text}';
      request.fields['lokasi'] = '${position.latitude},${position.longitude}';
      request.fields['tanggal_kunjungan'] = dateStr;

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selfieFile!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("DEBUG_KUNJUNGAN: Status code = ${response.statusCode}");
      print("DEBUG_KUNJUNGAN: Response body = ${response.body}");

      final responseData = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunjungan lapangan berhasil dilaporkan!'), backgroundColor: Colors.green),
        );
        _clientController.clear();
        _keteranganController.clear();
        setState(() {
          _selfieFile = null;
        });
        Navigator.pop(context);
        _loadVisitList();
      } else {
        String errorMsg = responseData['message'] ?? 'Gagal memproses kunjungan.';
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
      print("DEBUG_KUNJUNGAN: Exception = $e");
      print("DEBUG_KUNJUNGAN: Stacktrace = $stacktrace");
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
                  'Laporkan Kunjungan Lapangan (Sales/Client Visit)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                ),
                const SizedBox(height: 16),

                // Client name
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(labelText: 'Nama Client / Instansi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Keterangan
                TextField(
                  controller: _keteranganController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Tujuan / Keterangan Kunjungan', border: OutlineInputBorder()),
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
                              Text('Ambil Selfie Bukti Kunjungan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _submitVisit,
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
        title: const Text('Sales / Client Visit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormDialog,
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Check-In Visit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadVisitList,
              child: _visitList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_location_alt_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada log kunjungan lapangan',
                            style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _visitList.length,
                      itemBuilder: (context, index) {
                        final item = _visitList[index];
                        final String imgUrl = item['foto'] != null 
                            ? '${Constants.baseUrl.replaceAll('/api', '')}/storage/uploads/kunjungan/${item['foto']}'
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
                                      item['client'] ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['keterangan'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Constants.textMedium),
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
