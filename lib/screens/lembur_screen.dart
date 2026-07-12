import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../utils/constant.dart';

class LemburScreen extends StatefulWidget {
  const LemburScreen({super.key});

  @override
  State<LemburScreen> createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<dynamic> _lemburList = [];

  // Form Fields
  DateTime _dariDateTime = DateTime.now();
  DateTime _sampaiDateTime = DateTime.now().add(const Duration(hours: 3));
  final TextEditingController _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLemburList();
  }

  Future<void> _loadLemburList() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/lembur'),
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
            _lemburList = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading lembur list: $e");
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isDari) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isDari ? _dariDateTime : _sampaiDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isDari ? _dariDateTime : _sampaiDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          if (isDari) {
            _dariDateTime = dt;
            if (_sampaiDateTime.isBefore(_dariDateTime)) {
              _sampaiDateTime = _dariDateTime.add(const Duration(hours: 3));
            }
          } else {
            _sampaiDateTime = dt;
          }
        });
      }
    }
  }

  Future<void> _submitOvertimeRequest() async {
    if (_keteranganController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan lembur harus diisi.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      
      final String fromStr = "${_dariDateTime.year}-${_dariDateTime.month.toString().padLeft(2, '0')}-${_dariDateTime.day.toString().padLeft(2, '0')} ${_dariDateTime.hour.toString().padLeft(2, '0')}:${_dariDateTime.minute.toString().padLeft(2, '0')}";
      final String toStr = "${_sampaiDateTime.year}-${_sampaiDateTime.month.toString().padLeft(2, '0')}-${_sampaiDateTime.day.toString().padLeft(2, '0')} ${_sampaiDateTime.hour.toString().padLeft(2, '0')}:${_sampaiDateTime.minute.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mobile/lembur'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'dari': fromStr,
          'sampai': toStr,
          'keterangan': _keteranganController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan lembur berhasil disimpan!'), backgroundColor: Colors.green),
        );
        _keteranganController.clear();
        Navigator.pop(context);
        _loadLemburList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Gagal memproses pengajuan lembur.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLemburAbsen(int lemburId, bool hasIn) async {
    setState(() => _isLoading = true);
    try {
      // Get location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Get photo selfie
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (photo == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto selfie wajib untuk absen lembur.')),
        );
        return;
      }

      final token = await _authService.getToken();
      final uri = Uri.parse('${Constants.baseUrl}/mobile/lembur/presensi');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['id_lembur'] = lemburId.toString();
      request.fields['status'] = !hasIn ? '1' : '2';
      request.fields['lokasi'] = '${position.latitude},${position.longitude}';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          photo.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print("DEBUG_LEMBUR: Status code = ${response.statusCode}");
      print("DEBUG_LEMBUR: Response body = ${response.body}");

      final responseData = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Absen lembur berhasil!'), backgroundColor: Colors.green),
        );
        _loadLemburList();
      } else {
        String errorMsg = responseData['message'] ?? 'Gagal memproses absen lembur.';
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
      print("DEBUG_LEMBUR: Exception = $e");
      print("DEBUG_LEMBUR: Stacktrace = $stacktrace");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
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
                  'Formulir Pengajuan Lembur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                ),
                const SizedBox(height: 16),

                // Date Picker Dari
                OutlinedButton.icon(
                  onPressed: () async {
                    await _selectDateTime(context, true);
                    setModalState(() {});
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('Mulai: ${_dariDateTime.day}/${_dariDateTime.month} ${_dariDateTime.hour.toString().padLeft(2, '0')}:${_dariDateTime.minute.toString().padLeft(2, '0')}'),
                ),
                const SizedBox(height: 12),

                // Date Picker Sampai
                OutlinedButton.icon(
                  onPressed: () async {
                    await _selectDateTime(context, false);
                    setModalState(() {});
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('Selesai: ${_sampaiDateTime.day}/${_sampaiDateTime.month} ${_sampaiDateTime.hour.toString().padLeft(2, '0')}:${_sampaiDateTime.minute.toString().padLeft(2, '0')}'),
                ),
                const SizedBox(height: 16),

                // Keterangan Textfield
                TextField(
                  controller: _keteranganController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Tugas / Keterangan Lembur', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _submitOvertimeRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SUBMIT LEMBUR'),
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
        title: const Text('Rencana & Riwayat Lembur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormDialog,
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Lembur Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadLemburList,
              child: _lemburList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alarm_on_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada riwayat lembur',
                            style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _lemburList.length,
                      itemBuilder: (context, index) {
                        final item = _lemburList[index];
                        
                        String statusText = 'Pending';
                        Color statusColor = Colors.orange;
                        final statusVal = item['status'];
                        if (statusVal == 1 || statusVal == '1') {
                          statusText = 'Disetujui';
                          statusColor = Colors.teal;
                        } else if (statusVal == 2 || statusVal == '2') {
                          statusText = 'Ditolak';
                          statusColor = Colors.redAccent;
                        }

                        final bool isApproved = statusVal == 1 || statusVal == '1';
                        final bool hasIn = item['lembur_in'] != null;
                        final bool hasOut = item['lembur_out'] != null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Constants.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Lembur Tanggal: ${item['tanggal']}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                  Text(
                                    statusText,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Rencana Jam: ${item['lembur_mulai'] != null ? item['lembur_mulai'].toString().substring(11, 16) : '-'} s.d ${item['lembur_selesai'] != null ? item['lembur_selesai'].toString().substring(11, 16) : '-'}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['keterangan'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                              ),
                              const SizedBox(height: 10),
                              
                              // Realisasi lembur scan check-in/out
                              if (isApproved) ...[
                                const Divider(),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('In: ${item['lembur_in'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
                                    Text('Out: ${item['lembur_out'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                                  ],
                                ),
                                if (!hasIn || !hasOut) ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => _submitLemburAbsen(item['id'], hasIn),
                                    icon: const Icon(Icons.fingerprint, size: 16),
                                    label: Text(!hasIn ? 'ABSEN LEMBUR MASUK' : 'ABSEN LEMBUR PULANG'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: !hasIn ? Colors.teal : Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
