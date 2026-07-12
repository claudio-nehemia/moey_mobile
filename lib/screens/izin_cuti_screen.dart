import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../utils/constant.dart';

class IzinCutiScreen extends StatefulWidget {
  const IzinCutiScreen({super.key});

  @override
  State<IzinCutiScreen> createState() => _IzinCutiScreenState();
}

class _IzinCutiScreenState extends State<IzinCutiScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<dynamic> _izinList = [];

  // Form Fields
  String _jenisIzin = 'i'; // i=absen, s=sakit, c=cuti, d=dinas, k=koreksi
  DateTime _dariDate = DateTime.now();
  DateTime _sampaiDate = DateTime.now();
  final TextEditingController _keteranganController = TextEditingController();
  
  // Sakit specific
  File? _sidFile;

  // Koreksi specific
  final TextEditingController _jamInController = TextEditingController(text: '08:00');
  final TextEditingController _jamOutController = TextEditingController(text: '17:00');
  String _kodeJamKerja = 'JK01';

  int _calculateDays(String dariStr, String sampaiStr) {
    try {
      final dari = DateTime.parse(dariStr);
      final sampai = DateTime.parse(sampaiStr);
      return sampai.difference(dari).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  int _calculateSisaCuti() {
    int maxCuti = 12; // Standard 12 days
    int currentYear = DateTime.now().year;
    int usedCuti = 0;
    for (var item in _izinList) {
      if (item['ket'] == 'c' && (item['status'] == 1 || item['status'] == '1')) {
        try {
          final dari = DateTime.parse(item['dari']);
          if (dari.year == currentYear) {
            usedCuti += _calculateDays(item['dari'], item['sampai']);
          }
        } catch (_) {}
      }
    }
    return maxCuti - usedCuti;
  }

  @override
  void initState() {
    super.initState();
    _loadIzinList();
  }

  Future<void> _loadIzinList() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mobile/izin'),
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
            _izinList = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading leave list: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDari) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDari ? _dariDate : _sampaiDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        if (isDari) {
          _dariDate = picked;
          if (_sampaiDate.isBefore(_dariDate)) {
            _sampaiDate = _dariDate;
          }
        } else {
          _sampaiDate = picked;
        }
      });
    }
  }

  Future<void> _pickSidFile() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _sidFile = File(photo.path);
        });
      }
    } catch (e) {
      print("Error picking SID: $e");
    }
  }

  Future<void> _submitRequest() async {
    if (_jenisIzin == 'c') {
      final int sisa = _calculateSisaCuti();
      final int requested = _dariDate == _sampaiDate ? 1 : _sampaiDate.difference(_dariDate).inDays + 1;
      if (requested > sisa) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengajuan ($requested hari) melebihi sisa cuti Anda ($sisa hari).'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (_keteranganController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan pengajuan harus diisi.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${Constants.baseUrl}/mobile/izin');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['jenis_izin'] = _jenisIzin;
      request.fields['dari'] = "${_dariDate.year}-${_dariDate.month.toString().padLeft(2, '0')}-${_dariDate.day.toString().padLeft(2, '0')}";
      request.fields['sampai'] = "${_sampaiDate.year}-${_sampaiDate.month.toString().padLeft(2, '0')}-${_sampaiDate.day.toString().padLeft(2, '0')}";
      request.fields['keterangan'] = _keteranganController.text;

      if (_jenisIzin == 's' && _sidFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'sid',
            _sidFile!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      if (_jenisIzin == 'k') {
        request.fields['kode_jam_kerja'] = _kodeJamKerja;
        request.fields['jam_in'] = _jamInController.text;
        request.fields['jam_out'] = _jamOutController.text;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("DEBUG_IZIN_CUTI: Status code = ${response.statusCode}");
      print("DEBUG_IZIN_CUTI: Response body = ${response.body}");

      final responseData = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan berhasil dikirim!'), backgroundColor: Colors.green),
        );
        _keteranganController.clear();
        setState(() {
          _sidFile = null;
        });
        Navigator.pop(context); // Close the sheet/form dialog
        _loadIzinList();
      } else {
        String errorMsg = responseData['message'] ?? 'Gagal memproses pengajuan.';
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
      print("DEBUG_IZIN_CUTI: Exception = $e");
      print("DEBUG_IZIN_CUTI: Stacktrace = $stacktrace");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _cancelRequest(String kode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pengajuan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pengajuan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/mobile/izin/$kode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan berhasil dibatalkan.')),
        );
        _loadIzinList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal membatalkan pengajuan.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showFormDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Formulir Pengajuan Izin & Kehadiran',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 12),

                // Jatah Cuti Info Banner (Only if Cuti selected)
                if (_jenisIzin == 'c') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal.shade800, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sisa jatah cuti tahunan Anda: ${_calculateSisaCuti()} hari',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Dropdown Jenis Izin
                DropdownButtonFormField<String>(
                  value: _jenisIzin,
                  decoration: InputDecoration(
                    labelText: 'Jenis Pengajuan',
                    prefixIcon: const Icon(Icons.category_outlined, color: Constants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Constants.primaryColor, width: 1.5),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'i', child: Text('Izin Absen')),
                    DropdownMenuItem(value: 's', child: Text('Sakit')),
                    DropdownMenuItem(value: 'c', child: Text('Cuti')),
                    DropdownMenuItem(value: 'd', child: Text('Dinas Luar')),
                    DropdownMenuItem(value: 'k', child: Text('Koreksi Absen')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => _jenisIzin = val);
                      setState(() => _jenisIzin = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Dari & Sampai Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _selectDate(context, true);
                          setModalState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Constants.primaryColor),
                        label: Text(
                          'Dari:\n${_dariDate.day}/${_dariDate.month}/${_dariDate.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Constants.textDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Hide sampai if it's correction (koreksi only has 1 date)
                    if (_jenisIzin != 'k')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _selectDate(context, false);
                            setModalState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Constants.primaryColor),
                          label: Text(
                            'Sampai:\n${_sampaiDate.day}/${_sampaiDate.month}/${_sampaiDate.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Constants.textDark, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sakit Attachment Field
                if (_jenisIzin == 's') ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _pickSidFile();
                      setModalState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    icon: Icon(
                      _sidFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                      color: _sidFile != null ? Colors.teal : Constants.primaryColor,
                    ),
                    label: Text(
                      _sidFile != null ? 'Surat Dokter Terlampir ✓' : 'Upload Surat Dokter (SID)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _sidFile != null ? Colors.teal : Constants.textDark,
                      ),
                    ),
                  ),
                  if (_sidFile != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_sidFile!, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // Koreksi Fields
                if (_jenisIzin == 'k') ...[
                  TextField(
                    controller: _jamInController,
                    decoration: InputDecoration(
                      labelText: 'Jam Masuk (Format: HH:MM)',
                      prefixIcon: const Icon(Icons.login_rounded, color: Constants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _jamOutController,
                    decoration: InputDecoration(
                      labelText: 'Jam Pulang (Format: HH:MM)',
                      prefixIcon: const Icon(Icons.logout_rounded, color: Constants.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Keterangan Textfield
                TextField(
                  controller: _keteranganController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Keterangan Alasan Pengajuan',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: Constants.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: const Text(
                    'SUBMIT PENGAJUAN',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
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
        title: const Text('Pengajuan & Riwayat Izin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormDialog,
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Izin Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadIzinList,
              child: _izinList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada pengajuan izin/cuti',
                            style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _izinList.length,
                      itemBuilder: (context, index) {
                        final item = _izinList[index];
                        final String dateRange = item['dari'] == item['sampai'] 
                            ? '${item['dari']}' 
                            : '${item['dari']} s.d ${item['sampai']}';

                        // Format status
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

                        // Type label
                        String typeLabel = 'Izin';
                        if (item['ket'] == 's') typeLabel = 'Sakit';
                        if (item['ket'] == 'c') typeLabel = 'Cuti';
                        if (item['ket'] == 'd') typeLabel = 'Dinas';
                        if (item['ket'] == 'k') typeLabel = 'Koreksi Absen';

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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      typeLabel.toUpperCase(),
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                  Text(
                                    statusText,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                dateRange,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['keterangan'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                              ),
                              if (item['status'] == 0 || item['status'] == '0') ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _cancelRequest(item['kode']),
                                    icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.redAccent),
                                    label: const Text('Batalkan', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ),
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
