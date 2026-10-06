import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';
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
  
  // Lampiran (Sakit & Cuti: PDF / Gambar)
  File? _attachmentFile;
  Uint8List? _attachmentBytes;
  String? _attachmentFileName;
  bool _isAttachmentPdf = false;
  File? _sidFile;
  Uint8List? _sidBytes;
  String? _sidFileName;

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
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        final photo = response.file!;
        final bytes = await photo.readAsBytes();
        final file = File(photo.path);
        setState(() {
          _attachmentBytes = bytes;
          _attachmentFileName = photo.name;
          _attachmentFile = file;
          _isAttachmentPdf = false;
          _sidBytes = bytes;
          _sidFileName = photo.name;
          _sidFile = file;
        });
      }
    } catch (e) {
      debugPrint("Error retrieving lost image picker data: $e");
    }
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

  Future<void> _showAttachmentSourceDialog({StateSetter? setModalState}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Lampiran / Dokumen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mendukung format gambar (JPG/PNG) atau dokumen (PDF)',
                  style: TextStyle(fontSize: 12, color: Constants.textMedium),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                  ),
                  title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Ambil foto langsung dokumen bukti', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickFromCamera(setModalState: setModalState);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.green),
                  ),
                  title: const Text('Pilih dari Galeri Foto', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Pilih foto berkas dari galeri', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickFromGallery(setModalState: setModalState);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                  ),
                  title: const Text('Pilih Dokumen PDF / Berkas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Pilih file surat/dokumen PDF', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickDocumentFile(setModalState: setModalState);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera({StateSetter? setModalState}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final file = !kIsWeb ? File(photo.path) : null;
        if (setModalState != null) {
          setModalState(() {
            _attachmentBytes = bytes;
            _attachmentFileName = photo.name;
            _attachmentFile = file;
            _isAttachmentPdf = false;
            _sidBytes = bytes;
            _sidFileName = photo.name;
            _sidFile = file;
          });
        }
        setState(() {
          _attachmentBytes = bytes;
          _attachmentFileName = photo.name;
          _attachmentFile = file;
          _isAttachmentPdf = false;
          _sidBytes = bytes;
          _sidFileName = photo.name;
          _sidFile = file;
        });
      }
    } catch (e) {
      debugPrint("Error picking camera: $e");
    }
  }

  Future<void> _pickFromGallery({StateSetter? setModalState}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final file = !kIsWeb ? File(photo.path) : null;
        if (setModalState != null) {
          setModalState(() {
            _attachmentBytes = bytes;
            _attachmentFileName = photo.name;
            _attachmentFile = file;
            _isAttachmentPdf = false;
            _sidBytes = bytes;
            _sidFileName = photo.name;
            _sidFile = file;
          });
        }
        setState(() {
          _attachmentBytes = bytes;
          _attachmentFileName = photo.name;
          _attachmentFile = file;
          _isAttachmentPdf = false;
          _sidBytes = bytes;
          _sidFileName = photo.name;
          _sidFile = file;
        });
      }
    } catch (e) {
      debugPrint("Error picking gallery: $e");
    }
  }

  Future<void> _pickDocumentFile({StateSetter? setModalState}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final fileItem = result.files.single;
        final bool isPdf = (fileItem.extension?.toLowerCase() == 'pdf') || fileItem.name.toLowerCase().endsWith('.pdf');
        final file = (!kIsWeb && fileItem.path != null) ? File(fileItem.path!) : null;

        if (setModalState != null) {
          setModalState(() {
            _attachmentBytes = fileItem.bytes;
            _attachmentFileName = fileItem.name;
            _attachmentFile = file;
            _isAttachmentPdf = isPdf;
            _sidBytes = fileItem.bytes;
            _sidFileName = fileItem.name;
            _sidFile = file;
          });
        }
        setState(() {
          _attachmentBytes = fileItem.bytes;
          _attachmentFileName = fileItem.name;
          _attachmentFile = file;
          _isAttachmentPdf = isPdf;
          _sidBytes = fileItem.bytes;
          _sidFileName = fileItem.name;
          _sidFile = file;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
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

      if (_jenisIzin == 'c') {
        request.fields['kode_cuti'] = 'C01';
      }

      if (_attachmentBytes != null || _attachmentFile != null || _sidBytes != null || _sidFile != null) {
        final bytes = _attachmentBytes ?? _sidBytes;
        final file = _attachmentFile ?? _sidFile;
        final name = _attachmentFileName ?? _sidFileName ?? 'lampiran_${DateTime.now().millisecondsSinceEpoch}.${_isAttachmentPdf ? "pdf" : "jpg"}';
        final isPdf = _isAttachmentPdf || name.toLowerCase().endsWith('.pdf');
        final mediaType = isPdf
            ? MediaType('application', 'pdf')
            : MediaType('image', name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg');

        final String fieldName = switch (_jenisIzin) {
          'c' => 'doc_cuti',
          's' => 'sid',
          'd' => 'doc_dinas',
          'k' => 'doc_koreksi',
          _ => 'doc_izin',
        };

        if (bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: name,
              contentType: mediaType,
            ),
          );
          request.files.add(
            http.MultipartFile.fromBytes(
              'lampiran',
              bytes,
              filename: name,
              contentType: mediaType,
            ),
          );
        } else if (!kIsWeb && file != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              fieldName,
              file.path,
              contentType: mediaType,
            ),
          );
          request.files.add(
            await http.MultipartFile.fromPath(
              'lampiran',
              file.path,
              contentType: mediaType,
            ),
          );
        }
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
          _attachmentFile = null;
          _attachmentBytes = null;
          _attachmentFileName = null;
          _isAttachmentPdf = false;
          _sidFile = null;
          _sidBytes = null;
          _sidFileName = null;
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

  Widget _buildAttachmentPickerSection(StateSetter setModalState) {
    final bool hasFile = _attachmentBytes != null ||
        _attachmentFile != null ||
        _sidBytes != null ||
        _sidFile != null;
    final String currentFileName = _attachmentFileName ?? _sidFileName ?? 'Lampiran';
    final bool isPdf = _isAttachmentPdf || currentFileName.toLowerCase().endsWith('.pdf');
    final String sectionTitle = switch (_jenisIzin) {
      's' => 'Surat Keterangan Dokter / Bukti Sakit',
      'c' => 'Dokumen / Lampiran Pendukung Cuti',
      'd' => 'Surat Tugas / Bukti Dinas Luar',
      'k' => 'Bukti Koreksi Absen (Foto / Dokumen)',
      _ => 'Lampiran / Dokumen Pendukung Izin',
    };
    final IconData sectionIcon = switch (_jenisIzin) {
      's' => Icons.medical_services_outlined,
      'd' => Icons.business_center_outlined,
      'k' => Icons.access_time_rounded,
      _ => Icons.attach_file_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sectionIcon,
                size: 18,
                color: Constants.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Constants.textDark,
                  ),
                ),
              ),
              Text(
                '(Opsional)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasFile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: isPdf
                        ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 26)
                        : (_attachmentBytes != null
                            ? Image.memory(
                                _attachmentBytes!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              )
                            : (_attachmentFile != null && !kIsWeb
                                ? Image.file(
                                    _attachmentFile!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image, color: Colors.blue, size: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentFileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Constants.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPdf ? 'Berkas PDF' : 'Berkas Gambar',
                          style: TextStyle(
                            fontSize: 11,
                            color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Hapus Berkas',
                    onPressed: () {
                      setModalState(() {
                        _attachmentFile = null;
                        _attachmentBytes = null;
                        _attachmentFileName = null;
                        _isAttachmentPdf = false;
                        _sidFile = null;
                        _sidBytes = null;
                        _sidFileName = null;
                      });
                      setState(() {
                        _attachmentFile = null;
                        _attachmentBytes = null;
                        _attachmentFileName = null;
                        _isAttachmentPdf = false;
                        _sidFile = null;
                        _sidBytes = null;
                        _sidFileName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => _showAttachmentSourceDialog(setModalState: setModalState),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Constants.primaryColor.withOpacity(0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file_rounded, color: Constants.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Pilih Berkas (PDF / Foto)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Format didukung: PDF, JPG, PNG (Maks. 10MB)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
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

                // Attachment Field (Semua Jenis Izin: PDF / Gambar)
                _buildAttachmentPickerSection(setModalState),
                const SizedBox(height: 16),

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
                              if (item['doc_url'] != null || item['doc_sid_url'] != null) ...[
                                Builder(
                                  builder: (context) {
                                    final String docUrl = (item['doc_url'] ?? item['doc_sid_url']).toString();
                                    if (docUrl.trim().isEmpty) return const SizedBox.shrink();
                                    final bool isPdf = docUrl.toLowerCase().contains('.pdf');
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          final uri = Uri.parse(docUrl);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Tidak dapat membuka lampiran.')),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPdf ? Colors.red.shade200 : Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                                size: 16,
                                                color: isPdf ? Colors.red : Colors.blue.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isPdf ? 'Lihat Lampiran PDF' : 'Lihat Lampiran Foto',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPdf ? Colors.red.shade900 : Colors.blue.shade800,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.open_in_new,
                                                size: 12,
                                                color: isPdf ? Colors.red.shade900 : Colors.blue.shade800,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
