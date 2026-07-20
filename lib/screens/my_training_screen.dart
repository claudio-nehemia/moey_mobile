import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payroll_service.dart';
import '../utils/constant.dart';
import 'package:intl/intl.dart';

class MyTrainingScreen extends StatefulWidget {
  const MyTrainingScreen({super.key});

  @override
  State<MyTrainingScreen> createState() => _MyTrainingScreenState();
}

class _MyTrainingScreenState extends State<MyTrainingScreen> {
  final PayrollService _payrollService = PayrollService();
  bool _isLoading = true;
  List<dynamic> _trainings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTrainings();
  }

  Future<void> _fetchTrainings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _payrollService.getMyTrainings();

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _trainings = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat data pelatihan';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lulus':
        return Colors.green;
      case 'tidak lulus':
        return Colors.red;
      case 'mengikuti':
      default:
        return Colors.orange;
    }
  }

  Future<void> _openCertificate(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka sertifikat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pelatihan Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTrainings,
        color: Constants.accentColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Constants.accentColor))
            : _errorMessage != null
                ? _buildErrorView()
                : _trainings.isEmpty
                    ? _buildEmptyView()
                    : _buildListView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Constants.errorColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Constants.textMedium, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTrainings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined, size: 64, color: Constants.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pelatihan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Constants.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Riwayat program pelatihan internal dan eksternal Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Constants.textLight, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _trainings.length,
      itemBuilder: (context, index) {
        final t = _trainings[index];
        final status = t['status_kelulusan'] ?? 'Mengikuti';
        final statusColor = _getStatusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Constants.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        t['nama_pelatihan'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Constants.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t['penyelenggara'] ?? '',
                  style: TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 20, color: Constants.borderColor),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: Constants.textLight),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(t['tanggal_mulai'])} - ${_formatDate(t['tanggal_selesai'])}',
                      style: TextStyle(fontSize: 12, color: Constants.textMedium),
                    ),
                    const Spacer(),
                    const Text(
                      'Nilai: ',
                      style: TextStyle(fontSize: 12, color: Constants.textLight, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      t['nilai'] ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Constants.textDark,
                      ),
                    ),
                  ],
                ),
                if (t['sertifikat_url'] != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openCertificate(t['sertifikat_url']),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Constants.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Constants.primaryColor),
                      label: const Text(
                        'Unduh Sertifikat',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.primaryColor),
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
