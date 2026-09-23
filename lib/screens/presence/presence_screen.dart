import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';
import '../../utils/constant.dart';
import 'widgets/presence_action_buttons.dart';
import 'widgets/presence_camera_card.dart';
import 'widgets/presence_map_card.dart';
import 'widgets/presence_shift_card.dart';

class PresenceScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDashboardData;
  const PresenceScreen({super.key, this.initialDashboardData});

  @override
  State<PresenceScreen> createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> {
  final AuthService _authService = AuthService();

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
  int _selectedCameraIndex = 0;
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
        _isBreakActive =
            p['istirahat_out'] != null && p['istirahat_in'] == null;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    final freshData = await _authService.getDashboardData();
    if (freshData != null && mounted) {
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

      if (!mounted) return;
      setState(() => _statusMessage = 'Membaca koordinat GPS...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = 'Lokasi siap.';
      });

      _checkGeofence();
      _initializeCamera();
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _initializeCamera({int? cameraIndex}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription selectedCam;
        if (cameraIndex != null && cameraIndex < _cameras!.length) {
          selectedCam = _cameras![cameraIndex];
          _selectedCameraIndex = cameraIndex;
        } else {
          final frontCamIndex = _cameras!.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );
          if (frontCamIndex != -1) {
            selectedCam = _cameras![frontCamIndex];
            _selectedCameraIndex = frontCamIndex;
          } else {
            selectedCam = _cameras!.first;
            _selectedCameraIndex = 0;
          }
        }

        _cameraController = CameraController(
          selectedCam,
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
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    int nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _initializeCamera(cameraIndex: nextIndex);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      final file = await _cameraController!.takePicture();
      if (!mounted) return;
      setState(() {
        _selfieFile = File(file.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menangkap foto: $e')),
      );
    }
  }

  Future<void> _submitPresence(String type) async {
    if (!mounted) return;
    if (await SecurityService.checkMockLocation(context)) {
      return;
    }

    if (_currentPosition == null) {
      await _determinePosition();
      if (_currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan lokasi GPS terbaru.'),
          ),
        );
        return;
      }
    }

    if (type != 'istirahat' && _selfieFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus mengambil foto selfie verifikasi wajah.'),
        ),
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

      final String activeKodeJk =
          _dashboardData?['jam_kerja']?['kode_jam_kerja'] ?? '';
      request.fields['kode_jam_kerja'] = activeKodeJk;
      request.fields['lokasi'] =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';

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
      final responseData = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Presensi berhasil disimpan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selfieFile = null;
        });
        await _refreshDashboard();
      } else {
        String errorMsg =
            responseData['message'] ?? 'Gagal memproses presensi.';
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
        title: const Text(
          'Presensi Selfie & GPS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PresenceShiftCard(shiftInfo: currentJk),
            const SizedBox(height: 20),
            PresenceMapCard(
              currentPosition: _currentPosition,
              officeLatLng: _getOfficeLatLng(),
              officeRadius: _getOfficeRadius(),
              isWithinGeofence: _isWithinGeofence,
              distanceToOffice: _distanceToOffice,
            ),
            PresenceCameraCard(
              selfieFile: _selfieFile,
              isCameraInitialized: _isCameraInitialized,
              cameraController: _cameraController,
              cameras: _cameras,
              onRetakePhoto: () => setState(() => _selfieFile = null),
              onSwitchCamera: _switchCamera,
              onCaptureImage: _captureImage,
            ),
            PresenceActionButtons(
              isLoading: _isLoading,
              statusMessage: _statusMessage,
              hasCheckedInToday: _hasCheckedInToday,
              hasCheckedOutToday: _hasCheckedOutToday,
              isBreakActive: _isBreakActive,
              dashboardData: _dashboardData,
              onSubmitPresence: _submitPresence,
            ),
          ],
        ),
      ),
    );
  }
}
