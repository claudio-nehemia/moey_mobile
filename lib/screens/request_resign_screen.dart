import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/payroll_service.dart';
import '../utils/constant.dart';
import 'package:intl/intl.dart';

class RequestResignScreen extends StatefulWidget {
  const RequestResignScreen({super.key});

  @override
  State<RequestResignScreen> createState() => _RequestResignScreenState();
}

class _RequestResignScreenState extends State<RequestResignScreen> {
  final PayrollService _payrollService = PayrollService();
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _resignStatus;
  
  DateTime? _selectedDate;
  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _payrollService.getResignStatus();

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _resignStatus = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal memuat status pengajuan')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime minDate = DateTime.now().add(const Duration(days: 30));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Constants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Constants.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih dokumen: $e')),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih tanggal efektif resign')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final response = await _payrollService.submitResign(
      tanggalEfektif: dateStr,
      alasan: _alasanController.text.trim(),
      filePath: _selectedFile?.path,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan resign berhasil dikirim'), backgroundColor: Colors.green),
        );
        _checkStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengirim pengajuan'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pengajuan Resign',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.accentColor))
          : _resignStatus != null && _resignStatus!['status_approval'] != 'Ditolak'
              ? _buildStatusView()
              : _buildFormView(),
    );
  }

  Widget _buildStatusView() {
    final status = _resignStatus!['status_approval'] ?? 'Pending';
    final statusColor = _getStatusColor(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Constants.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status.toLowerCase() == 'disetujui'
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_rounded,
                    size: 48,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Status Pengajuan Resign',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Rincian Pengajuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Constants.textDark)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tanggal Pengajuan', _formatDate(_resignStatus!['tanggal_pengajuan'])),
                const Divider(height: 24, color: Constants.borderColor),
                _buildInfoRow('Tanggal Efektif Resign', _formatDate(_resignStatus!['tanggal_efektif'])),
                const Divider(height: 24, color: Constants.borderColor),
                const Text('Alasan Pengunduran Diri:', style: TextStyle(fontSize: 12, color: Constants.textLight)),
                const SizedBox(height: 6),
                Text(
                  _resignStatus!['alasan'] ?? '',
                  style: const TextStyle(fontSize: 13, color: Constants.textDark, height: 1.4),
                ),
                if (_resignStatus!['catatan_hrd'] != null && _resignStatus!['catatan_hrd'].toString().isNotEmpty) ...[
                  const Divider(height: 24, color: Constants.borderColor),
                  const Text('Catatan HRD:', style: TextStyle(fontSize: 12, color: Constants.textLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    _resignStatus!['catatan_hrd'],
                    style: const TextStyle(fontSize: 13, color: Constants.textDark, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Constants.textLight)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark)),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_resignStatus != null && _resignStatus!['status_approval'] == 'Ditolak') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pengajuan Sebelumnya Ditolak',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Catatan HRD: ${_resignStatus!['catatan_hrd'] ?? '-'}',
                      style: const TextStyle(color: Constants.textDark, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
            const Text(
              'Tanggal Efektif Pengunduran Diri',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Constants.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Pilih Tanggal (Min. H+30)'
                          : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedDate == null ? Constants.textLight : Constants.textDark,
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Alasan Pengunduran Diri',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _alasanController,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(fontSize: 13, color: Constants.textDark),
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan pengunduran diri Anda secara singkat dan jelas...',
                hintStyle: const TextStyle(color: Constants.textLight, fontSize: 12),
                fillColor: Constants.cardColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Constants.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Constants.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Constants.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alasan resign tidak boleh kosong';
                }
                if (value.trim().length < 20) {
                  return 'Berikan alasan yang lebih detail (min. 20 karakter)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Unggah Surat Resmi (Opsional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 36, color: Constants.primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName ?? 'Pilih file Surat Resign (PDF/Image)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedFileName == null ? Constants.textLight : Constants.textDark,
                        fontWeight: _selectedFileName == null ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Constants.borderColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim Pengajuan Resign',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
