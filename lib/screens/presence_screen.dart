import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:camera/camera.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../utils/constant.dart';

class PresenceScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDashboardData;
  const PresenceScreen({super.key, this.initialDashboardData});

  @override
  State<PresenceScreen> createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String _statusMessage = 'Mendapatkan lokasi Anda...';
  Position? _currentPosition;
  File? _selfieFile;

  Map<String, dynamic>? _dashboardData;
  bool _hasCheckedInToday = false;
  bool _hasCheckedOutToday = false;
  bool _isBreakActive = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isWithinGeofence = false;
  double _distanceToOffice = 0.0;

  @override
  void initState() {
    super.initState();
    _dashboardData = widget.initialDashboardData;
    _parsePresenceStatus();
    _determinePosition();
    _refreshDashboard();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _parsePresenceStatus() {
    if (_dashboardData != null && _dashboardData!['presensi'] != null) {
      final p = _dashboardData!['presensi'];
      setState(() {
        _hasCheckedInToday = p['jam_in'] != null;
        _hasCheckedOutToday = p['jam_out'] != null;
        _isBreakActive = p['istirahat_out'] != null && p['istirahat_in'] == null;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    final freshData = await _authService.getDashboardData();
    if (freshData != null) {
      setState(() {
        _dashboardData = freshData;
      });
      _parsePresenceStatus();
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengecek izin GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan GPS tidak aktif pada perangkat ini.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin GPS ditolak.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin GPS ditolak permanen. Aktifkan manual di pengaturan.';
      }

      setState(() => _statusMessage = 'Membaca koordinat GPS...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = 'Lokasi siap.';
      });
      
      _checkGeofence();
      _initializeCamera();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = e.toString();
      });
    }
  }

  LatLng? _getOfficeLatLng() {
    final cabang = _dashboardData?['cabang'];
    if (cabang == null || cabang['lokasi_cabang'] == null) return null;
    final parts = cabang['lokasi_cabang'].toString().split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  double _getOfficeRadius() {
    final cabang = _dashboardData?['cabang'];
    if (cabang == null || cabang['radius_cabang'] == null) return 50.0;
    return double.tryParse(cabang['radius_cabang'].toString()) ?? 50.0;
  }

  void _checkGeofence() {
    final officeLatLng = _getOfficeLatLng();
    if (officeLatLng != null && _currentPosition != null) {
      final double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        officeLatLng.latitude,
        officeLatLng.longitude,
      );
      setState(() {
        _distanceToOffice = distance;
        _isWithinGeofence = distance <= _getOfficeRadius();
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCam = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      final file = await _cameraController!.takePicture();
      setState(() {
        _selfieFile = File(file.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menangkap foto: $e')),
      );
    }
  }

  Widget _buildCameraOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 160,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            borderRadius: const BorderRadius.all(Radius.elliptical(80, 100)),
          ),
          child: Center(
            child: Container(
              width: 154,
              height: 194,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                borderRadius: const BorderRadius.all(Radius.elliptical(77, 97)),
              ),
            ),
          ),
        ),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil selfie: $e')),
      );
    }
  }

  Future<void> _submitPresence(String type) async {
    if (await SecurityService.checkMockLocation(context)) {
      return;
    }

    if (_currentPosition == null) {
      await _determinePosition();
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan lokasi GPS terbaru.')),
        );
        return;
      }
    }

    if (type != 'istirahat' && _selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus mengambil foto selfie verifikasi wajah.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengirim data presensi...';
    });

    try {
      final token = await _authService.getToken();
      final String urlPath = type == 'masuk' 
          ? 'presensi/masuk' 
          : (type == 'pulang' ? 'presensi/pulang' : 'presensi/istirahat');

      final uri = Uri.parse('${Constants.baseUrl}/mobile/$urlPath');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      final String activeKodeJk = _dashboardData?['jam_kerja']?['kode_jam_kerja'] ?? '';
      request.fields['kode_jam_kerja'] = activeKodeJk;
      request.fields['lokasi'] = '${_currentPosition!.latitude},${_currentPosition!.longitude}';

      if (type != 'istirahat' && _selfieFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selfieFile!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print("DEBUG_PRESENCE: Status code = ${response.statusCode}");
      print("DEBUG_PRESENCE: Response body = ${response.body}");

      if (response.statusCode != 200) {
        print("=====================================================");
        print("❌❌❌ PRESENCE API ERROR DETECTED ❌❌❌");
        print("Request URL  : $uri");
        print("Status Code  : ${response.statusCode}");
        print("Response Body: ${response.body}");
        print("=====================================================");
      }

      final responseData = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Presensi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selfieFile = null;
        });
        await _refreshDashboard();
      } else {
        String errorMsg = responseData['message'] ?? 'Gagal memproses presensi.';
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
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e, stacktrace) {
      print("DEBUG_PRESENCE: Exception = $e");
      print("DEBUG_PRESENCE: Stacktrace = $stacktrace");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentJk = _dashboardData?['jam_kerja'] != null 
        ? '${_dashboardData!['jam_kerja']['nama_jam_kerja']} (${_dashboardData!['jam_kerja']['jam_masuk']} - ${_dashboardData!['jam_kerja']['jam_pulang']})'
        : 'Tidak ada jadwal hari ini';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Selfie & GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Jam Kerja Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Shift Hari Ini',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentJk,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Map Visualizer Card
            if (_currentPosition != null) ...[
              const Text(
                '📍 Peta Lokasi & Geofence',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      initialZoom: 16.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.moey.mobile',
                      ),
                      if (_getOfficeLatLng() != null) ...[
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _getOfficeLatLng()!,
                              radius: _getOfficeRadius(),
                              useRadiusInMeter: true,
                              color: _isWithinGeofence
                                  ? Colors.teal.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              borderColor: _isWithinGeofence ? Colors.teal : Colors.red,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _getOfficeLatLng()!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.business_rounded, color: Colors.blue, size: 30),
                            ),
                          ],
                        ),
                      ],
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.person_pin_circle_rounded, color: Colors.redAccent, size: 35),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final officeLatLng = _getOfficeLatLng();
                  
                  if (officeLatLng == null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        '⚠ Koordinat lokasi cabang belum dikonfigurasi di dashboard web.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    );
                  }

                  if (_currentPosition == null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '⏳ Sedang mendeteksi koordinat GPS...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isWithinGeofence ? Colors.teal.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _isWithinGeofence ? Colors.teal.shade200 : Colors.red.shade200),
                    ),
                    child: Text(
                      _isWithinGeofence
                          ? '✓ Anda berada di dalam radius kantor (${_distanceToOffice.toStringAsFixed(1)}m)'
                          : '✗ Anda berada di luar radius kantor (${_distanceToOffice.toStringAsFixed(1)}m, batas: ${_getOfficeRadius().toStringAsFixed(0)}m)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isWithinGeofence ? Colors.teal.shade800 : Colors.red.shade800,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              '📸 Verifikasi Selfie Wajah',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            // Inline Camera / Taken Selfie Preview
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: _selfieFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_selfieFile!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selfieFile = null;
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Foto Ulang', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isCameraInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              ClipRect(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _cameraController!.value.previewSize?.height ?? 1080,
                                    height: _cameraController!.value.previewSize?.width ?? 1920,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              ),
                              _buildCameraOverlay(),
                              Positioned(
                                bottom: 12,
                                child: FloatingActionButton(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.teal,
                                  onPressed: _captureImage,
                                  child: const Icon(Icons.camera_alt, size: 28),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
            ),
            const SizedBox(height: 20),

            // GPS status message
            Center(
              child: Text(
                '📍 $_statusMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons Block
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
            else ...[
              // Check In Button
              if (!_hasCheckedInToday)
                ElevatedButton.icon(
                  onPressed: () => _submitPresence('masuk'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('CHECK IN MASUK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Sudah Check-In Masuk pada jam: ${_dashboardData!['presensi']['jam_in']}',
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Break toggle (only if jam kerja has istirahat enabled)
              if (_hasCheckedInToday && !_hasCheckedOutToday && _dashboardData?['jam_kerja']?['istirahat'] == 1) ...[
                ElevatedButton.icon(
                  onPressed: () => _submitPresence('istirahat'),
                  icon: Icon(_isBreakActive ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(_isBreakActive ? 'MULAI KEMBALI BEKERJA' : 'MULAI ISTIRAHAT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreakActive ? Colors.blue : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Check Out Button
              if (_hasCheckedInToday && !_hasCheckedOutToday)
                ElevatedButton.icon(
                  onPressed: () => _submitPresence('pulang'),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('CHECK OUT PULANG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else if (_hasCheckedOutToday)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Sudah Check-Out Pulang pada jam: ${_dashboardData!['presensi']['jam_out']}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
