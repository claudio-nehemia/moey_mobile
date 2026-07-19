import 'package:flutter/material.dart';
import '../services/payroll_service.dart';
import '../utils/constant.dart';
import 'package:intl/intl.dart';

class SlipGajiScreen extends StatefulWidget {
  const SlipGajiScreen({super.key});

  @override
  State<SlipGajiScreen> createState() => _SlipGajiScreenState();
}

class _SlipGajiScreenState extends State<SlipGajiScreen> {
  final PayrollService _payrollService = PayrollService();
  bool _isLoading = true;
  List<dynamic> _slips = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSlips();
  }

  Future<void> _fetchSlips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _payrollService.getSlipGajiList();

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _slips = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat slip gaji';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Slip Gaji',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSlips,
        color: Constants.accentColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _slips.isEmpty
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
              onPressed: _fetchSlips,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
            )
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
            Icon(Icons.description_outlined, size: 64, color: Constants.textLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada slip gaji yang diterbitkan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Constants.textMedium, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _slips.length,
      itemBuilder: (context, index) {
        final slip = _slips[index];
        final String namaBulan = slip['nama_bulan'] ?? '';
        final int tahun = slip['tahun'] ?? DateTime.now().year;
        final String periodeDari = slip['periode_dari'] ?? '';
        final String periodeSampai = slip['periode_sampai'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Constants.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: InkWell(
            onTap: () => _openSlipDetail(slip['bulan'], tahun, namaBulan),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Constants.financeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Constants.financeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$namaBulan $tahun',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Constants.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Periode: $periodeDari s/d $periodeSampai',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Constants.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Constants.textLight,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSlipDetail(int bulan, int tahun, String namaBulan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SlipDetailBottomSheet(
        bulan: bulan,
        tahun: tahun,
        namaBulan: namaBulan,
        payrollService: _payrollService,
        formatCurrency: _formatCurrency,
      ),
    );
  }
}

class _SlipDetailBottomSheet extends StatefulWidget {
  final int bulan;
  final int tahun;
  final String namaBulan;
  final PayrollService payrollService;
  final String Function(num) formatCurrency;

  const _SlipDetailBottomSheet({
    required this.bulan,
    required this.tahun,
    required this.namaBulan,
    required this.payrollService,
    required this.formatCurrency,
  });

  @override
  State<_SlipDetailBottomSheet> createState() => _SlipDetailBottomSheetState();
}

class _SlipDetailBottomSheetState extends State<_SlipDetailBottomSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _detail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final response = await widget.payrollService.getSlipGajiDetail(widget.bulan, widget.tahun);

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _detail = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat detail slip';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Constants.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Drag indicator bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rincian Slip Gaji',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Constants.textDark),
                    ),
                    Text(
                      'Periode ${widget.namaBulan} ${widget.tahun}',
                      style: const TextStyle(fontSize: 12, color: Constants.textMedium),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Constants.textMedium),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Constants.borderColor),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorContent()
                    : _buildDetailContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Constants.errorColor),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat rincian',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Constants.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_detail == null) return const SizedBox.shrink();

    final karyawan = _detail!['karyawan'] ?? {};
    final summary = _detail!['summary'] ?? {};
    final penerimaan = _detail!['penerimaan'] ?? {};
    final potongan = _detail!['potongan'] ?? {};
    
    final num totalPenerimaan = _detail!['total_penerimaan'] ?? 0;
    final num totalPotongan = _detail!['total_potongan'] ?? 0;
    final num gajiBersih = _detail!['gaji_bersih'] ?? 0;

    final String namaKaryawan = karyawan['nama_karyawan'] ?? '';
    final String nik = karyawan['nik_show'] ?? karyawan['nik'] ?? '';
    final String jabatan = karyawan['nama_jabatan'] ?? '';
    final String departemen = karyawan['nama_dept'] ?? '';

    final List<dynamic> tunjanganList = penerimaan['tunjangan'] ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Employee Info & Net Salary highlight card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade800.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaKaryawan,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$jabatan - $departemen',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                        Text(
                          'NIK: $nik',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      karyawan['jenis_upah'] ?? 'Bulanan',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Colors.white24, height: 1),
              ),
              const Text(
                'GAJI BERSIH (TAKE HOME PAY)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                widget.formatCurrency(gajiBersih),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Kehadiran / Attendance Summary section
        _buildSectionHeader('Ringkasan Kehadiran', Icons.event_available_outlined, Colors.teal),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Constants.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttendanceItem('Hari Kerja', summary['hari_kerja']?.toString() ?? '0', Colors.teal),
              _buildAttendanceItem('Hadir', summary['hari_hadir']?.toString() ?? '0', Colors.green),
              _buildAttendanceItem('Terlambat', summary['hari_terlambat']?.toString() ?? '0', Colors.orange),
              _buildAttendanceItem('Lembur', '${summary['jam_lembur']?.toString() ?? '0'} jam', Colors.redAccent),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Penerimaan / Earnings section
        _buildSectionHeader('Penerimaan (A)', Icons.add_circle_outline_rounded, Colors.green),
        Container(
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Constants.borderColor),
          ),
          child: Column(
            children: [
              _buildDetailItem('Gaji Pokok', penerimaan['gaji_pokok'] ?? 0),
              if (tunjanganList.isNotEmpty)
                ...tunjanganList.map((t) => _buildDetailItem(t['nama'] ?? 'Tunjangan', t['jumlah'] ?? 0)),
              if ((penerimaan['upah_lembur'] ?? 0) > 0)
                _buildDetailItem('Upah Lembur', penerimaan['upah_lembur'] ?? 0),
              if ((penerimaan['tunjangan_pajak'] ?? 0) > 0)
                _buildDetailItem('Tunjangan PPh 21 (Gross-Up)', penerimaan['tunjangan_pajak'] ?? 0),
              if ((penerimaan['penambah'] ?? 0) > 0)
                _buildDetailItem('Penyesuaian (+) : ${penerimaan['keterangan_penyesuaian'] ?? ''}', penerimaan['penambah'] ?? 0),
              const Divider(height: 1, color: Constants.borderColor),
              _buildTotalItem('Total Penerimaan Bruto', totalPenerimaan, Colors.green),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Potongan / Deductions section
        _buildSectionHeader('Potongan (B)', Icons.remove_circle_outline_rounded, Colors.redAccent),
        Container(
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Constants.borderColor),
          ),
          child: Column(
            children: [
              if ((potongan['potongan_jam'] ?? 0) > 0)
                _buildDetailItem('Potongan Jam Kerja', potongan['potongan_jam'] ?? 0),
              if ((potongan['denda'] ?? 0) > 0)
                _buildDetailItem('Denda Keterlambatan', potongan['denda'] ?? 0),
              if ((potongan['bpjs_kesehatan'] ?? 0) > 0)
                _buildDetailItem('BPJS Kesehatan', potongan['bpjs_kesehatan'] ?? 0),
              if ((potongan['bpjs_tenagakerja'] ?? 0) > 0)
                _buildDetailItem('BPJS Ketenagakerjaan', potongan['bpjs_tenagakerja'] ?? 0),
              if ((potongan['cicilan_pinjaman'] ?? 0) > 0)
                _buildDetailItem('Cicilan Pinjaman', potongan['cicilan_pinjaman'] ?? 0),
              if ((potongan['potongan_pph21'] ?? 0) > 0)
                _buildDetailItem('Potongan Pajak PPh 21', potongan['potongan_pph21'] ?? 0),
              if ((potongan['pengurang'] ?? 0) > 0)
                _buildDetailItem('Penyesuaian (-)', potongan['pengurang'] ?? 0),
              const Divider(height: 1, color: Constants.borderColor),
              _buildTotalItem('Total Potongan', totalPotongan, Colors.redAccent),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Constants.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Constants.textMedium, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            widget.formatCurrency(value),
            style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, num value, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.formatCurrency(value),
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
