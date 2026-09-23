import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/order_service.dart';
import '../../../utils/constant.dart';
import 'helpers/order_detail_helpers.dart';
import 'widgets/order_header_card.dart';
import 'widgets/order_info_card.dart';
import 'widgets/order_team_section.dart';
import 'widgets/order_attachments_section.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _orderService.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _orderData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openFile(String path) async {
    final domain = Constants.baseUrl.replaceAll('/api', '');
    final urlString = '$domain/storage/$path';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Sistem tidak menemukan aplikasi untuk membuka tautan ini');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka berkas: ${e.toString()}'),
            backgroundColor: Constants.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _orderData != null ? 'Detail Proyek #${_orderData!['id']}' : 'Detail Proyek',
          style: const TextStyle(
            color: Constants.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Constants.cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Constants.textDark),
        shape: const Border(
          bottom: BorderSide(color: Constants.borderColor, width: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadOrderDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDetailContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Constants.errorColor),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat detail proyek',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_orderData == null) return const SizedBox.shrink();

    final order = _orderData!;
    final dateIn = order['tanggal_masuk_customer'] != null
        ? OrderDetailHelpers.formatDate(DateTime.tryParse(order['tanggal_masuk_customer']) ?? DateTime.now())
        : '-';
    final dateSurvey = order['tanggal_survey'] != null
        ? OrderDetailHelpers.formatDate(DateTime.tryParse(order['tanggal_survey']) ?? DateTime.now())
        : '-';

    return RefreshIndicator(
      onRefresh: _loadOrderDetail,
      color: Constants.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderHeaderCard(order: order),
            const SizedBox(height: 20),

            // Card 1: Informasi Client & Lokasi
            SectionCard(
              title: 'Informasi Klien & Alamat',
              icon: Icons.person_outline,
              children: [
                InfoGridRow(
                  leftIcon: Icons.badge_outlined,
                  leftLabel: 'Nama Customer',
                  leftValue: order['customer_name'],
                  rightIcon: Icons.domain_outlined,
                  rightLabel: 'Developer / Perusahaan',
                  rightValue: order['company_name'],
                ),
                const SizedBox(height: 16),
                InfoGridRow(
                  leftIcon: Icons.phone_android_outlined,
                  leftLabel: 'Nomor Telepon',
                  leftValue: order['phone_number'],
                  rightIcon: Icons.tag_outlined,
                  rightLabel: 'Nomor Unit',
                  rightValue: order['nomor_unit'] ?? '-',
                ),
                const SizedBox(height: 16),
                InfoSingleRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Lengkap Proyek',
                  value: order['alamat'],
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InfoSingleRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Catatan Customer',
                  value: order['customer_additional_info'] != null &&
                          order['customer_additional_info'].toString().trim().isNotEmpty
                      ? order['customer_additional_info']
                      : '-',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 2: Detail Parameter Proyek
            SectionCard(
              title: 'Parameter Proyek',
              icon: Icons.tune_rounded,
              children: [
                InfoGridRow(
                  leftIcon: Icons.category_outlined,
                  leftLabel: 'Tipe Interior',
                  leftValue: order['jenis_interior'],
                  rightIcon: Icons.calendar_month_outlined,
                  rightLabel: 'Tanggal Masuk',
                  rightValue: dateIn,
                ),
                const SizedBox(height: 16),
                InfoSingleRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Rencana Tanggal Survey',
                  value: dateSurvey,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 3: Penugasan Tim
            OrderTeamSection(users: order['users'] as List<dynamic>?),
            const SizedBox(height: 20),

            // Card 4: Lampiran Dokumen (MOM)
            OrderAttachmentsSection(
              momFiles: order['mom_files'] as List<dynamic>?,
              onOpenFile: _openFile,
            ),
          ],
        ),
      ),
    );
  }
}
