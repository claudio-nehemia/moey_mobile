import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/order_service.dart';
import '../utils/constant.dart';

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

  Widget _buildPipelineStepper(String? currentPhase) {
    final phases = ['survey', 'moodboard', 'rab_internal', 'kontrak'];
    final phaseLabels = ['Survey', 'Desain', 'RAB', 'Kontrak'];
    
    int activeIndex = 0;
    final normalized = (currentPhase ?? 'survey').toLowerCase();
    if (normalized.contains('survey')) activeIndex = 0;
    else if (normalized.contains('moodboard') || normalized.contains('desain')) activeIndex = 1;
    else if (normalized.contains('rab') || normalized.contains('estimasi')) activeIndex = 2;
    else if (normalized.contains('kontrak') || normalized.contains('selesai')) activeIndex = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(phases.length, (index) {
          final isCompleted = index < activeIndex;
          final isActive = index == activeIndex;
          final color = isCompleted
              ? Constants.successColor
              : isActive
                  ? Constants.primaryColor
                  : Constants.textLight.withOpacity(0.4);

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (isCompleted || isActive)
                                ? Constants.successColor
                                : Constants.borderColor,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: isActive ? 6 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Constants.primaryColor.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == phases.length - 1
                            ? Colors.transparent
                            : isCompleted
                                ? Constants.successColor
                                : Constants.borderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  phaseLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Constants.textDark : Constants.textMedium.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_orderData == null) return const SizedBox.shrink();

    final order = _orderData!;
    final statusColor = _getStatusColor(order['project_status'] ?? 'pending');
    final dateIn = order['tanggal_masuk_customer'] != null
        ? _formatDate(DateTime.tryParse(order['tanggal_masuk_customer']) ?? DateTime.now())
        : '-';
    final dateSurvey = order['tanggal_survey'] != null
        ? _formatDate(DateTime.tryParse(order['tanggal_survey']) ?? DateTime.now())
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
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Constants.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Constants.primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_center_rounded, color: Constants.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['nama_project'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Constants.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (order['tahapan_proyek'] ?? order['project_status'] ?? 'pending')
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(order['priority_level']).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'PRIORITAS: ${order['priority_level']}'.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _getPriorityColor(order['priority_level']),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPipelineStepper(order['tahapan_proyek'] ?? order['project_status']),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Informasi Client & Lokasi
            _buildSectionCard(
              title: 'Informasi Klien & Alamat',
              icon: Icons.person_outline,
              children: [
                _buildInfoGridRow(
                  leftIcon: Icons.badge_outlined,
                  leftLabel: 'Nama Customer',
                  leftValue: order['customer_name'],
                  rightIcon: Icons.domain_outlined,
                  rightLabel: 'Developer / Perusahaan',
                  rightValue: order['company_name'],
                ),
                const SizedBox(height: 16),
                _buildInfoGridRow(
                  leftIcon: Icons.phone_android_outlined,
                  leftLabel: 'Nomor Telepon',
                  leftValue: order['phone_number'],
                  rightIcon: Icons.tag_outlined,
                  rightLabel: 'Nomor Unit',
                  rightValue: order['nomor_unit'] ?? '-',
                ),
                const SizedBox(height: 16),
                _buildInfoSingleRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Lengkap Proyek',
                  value: order['alamat'],
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildInfoSingleRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Catatan Customer',
                  value: order['customer_additional_info'] != null && order['customer_additional_info'].toString().trim().isNotEmpty
                      ? order['customer_additional_info']
                      : '-',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 2: Detail Parameter Proyek
            _buildSectionCard(
              title: 'Parameter Proyek',
              icon: Icons.tune_rounded,
              children: [
                _buildInfoGridRow(
                  leftIcon: Icons.category_outlined,
                  leftLabel: 'Tipe Interior',
                  leftValue: order['jenis_interior'],
                  rightIcon: Icons.calendar_month_outlined,
                  rightLabel: 'Tanggal Masuk',
                  rightValue: dateIn,
                ),
                const SizedBox(height: 16),
                _buildInfoSingleRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Rencana Tanggal Survey',
                  value: dateSurvey,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 3: Penugasan Tim
            _buildTeamSection(order['users'] as List<dynamic>?),
            const SizedBox(height: 20),

            // Card 4: Lampiran Dokumen (MOM)
            _buildAttachmentsSection(order['mom_files'] as List<dynamic>?),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Constants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Constants.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGridRow({
    required IconData leftIcon,
    required String leftLabel,
    required String? leftValue,
    required IconData rightIcon,
    required String rightLabel,
    required String? rightValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(leftIcon, size: 14, color: Constants.textMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leftLabel,
                      style: const TextStyle(fontSize: 10, color: Constants.textLight, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      leftValue ?? '-',
                      style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(rightIcon, size: 14, color: Constants.textMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rightLabel,
                      style: const TextStyle(fontSize: 10, color: Constants.textLight, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rightValue ?? '-',
                      style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSingleRow({required IconData icon, required String label, required String? value, int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Constants.textMedium),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Constants.textLight, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? '-',
                style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.w600),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(List<dynamic>? users) {
    final Map<String, List<Map<String, String>>> roleGroups = {
      'Kepala Marketing': [],
      'Surveyor / Drafter': [],
      'Desainer': [],
    };

    if (users != null) {
      for (final u in users) {
        final role = u['role'] as String? ?? 'Anggota';
        final name = u['name'] as String? ?? '';
        final email = u['email'] as String? ?? '';

        final userMap = {'name': name, 'email': email};

        if (role == 'Kepala Marketing') {
          roleGroups['Kepala Marketing']!.add(userMap);
        } else if (role == 'Surveyor' || role == 'Drafter') {
          roleGroups['Surveyor / Drafter']!.add(userMap);
        } else if (role == 'Desainer') {
          roleGroups['Desainer']!.add(userMap);
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 18, color: Constants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Penugasan Tim Kerja',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Constants.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleListRow('Kepala Marketing', roleGroups['Kepala Marketing']!, Colors.indigo.withOpacity(0.08), Colors.indigo),
                const SizedBox(height: 16),
                _buildRoleListRow('Surveyor / Drafter', roleGroups['Surveyor / Drafter']!, Colors.amber.withOpacity(0.08), Colors.amber[800]!),
                const SizedBox(height: 16),
                _buildRoleListRow('Desainer', roleGroups['Desainer']!, Colors.purple.withOpacity(0.08), Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleListRow(String roleLabel, List<Map<String, String>> members, Color avatarBg, Color avatarText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          roleLabel,
          style: const TextStyle(fontSize: 10, color: Constants.textLight, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
        const SizedBox(height: 6),
        members.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Belum ditugaskan',
                  style: TextStyle(fontSize: 12, color: Constants.textMedium, fontStyle: FontStyle.italic),
                ),
              )
            : Column(
                children: members.map((u) {
                  final name = u['name'] ?? '';
                  final email = u['email'] ?? '';
                  final initials = name.isNotEmpty
                      ? name.split(' ').map((p) => p[0]).take(2).join('').toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Constants.surfaceColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Constants.borderColor.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: avatarBg,
                          child: Text(
                            initials,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: avatarText),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Constants.textDark),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                email,
                                style: const TextStyle(fontSize: 10, color: Constants.textLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildAttachmentsSection(List<dynamic>? momFiles) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.attachment_rounded, size: 18, color: Constants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Minutes of Meeting (MOM)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Constants.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: momFiles == null || momFiles.isEmpty
                ? const Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined, size: 16, color: Constants.textMedium),
                      SizedBox(width: 10),
                      Text(
                        'Tidak ada lampiran dokumen MOM',
                        style: TextStyle(
                          fontSize: 12,
                          color: Constants.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: momFiles.map((fileObj) {
                      final path = fileObj['path'] as String? ?? '';
                      final fileName = path.split('/').last;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Constants.borderColor),
                        ),
                        child: InkWell(
                          onTap: () => _openFile(path),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Constants.primaryColor.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.insert_drive_file_outlined, size: 16, color: Constants.primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Constants.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Constants.primaryColor.withOpacity(0.06),
                                  ),
                                  child: const Icon(Icons.open_in_new_rounded, size: 12, color: Constants.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'completed':
      case 'active':
        return Constants.successColor;
      case 'progress':
      case 'in_progress':
      case 'survey':
      case 'moodboard':
      case 'estimasi':
        return Constants.primaryColor;
      case 'pending':
      case 'menunggu':
        return Constants.warningColor;
      default:
        return Constants.textMedium;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Constants.errorColor;
      case 'medium':
        return Constants.warningColor;
      default:
        return Constants.successColor;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
