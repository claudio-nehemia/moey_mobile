import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../utils/constant.dart';
import '../widgets/shimmer_loading.dart';
import 'dart:async';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _allNotifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, month, week

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _notificationService.getNotifications(perPage: 100);
      if (mounted) setState(() { _allNotifications = response.data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NotificationModel> get _completedTasks {
    final now = DateTime.now();
    return _allNotifications.where((n) {
      if (!n.requiresActionResponse || !n.isResponded) return false;
      if (_filter == 'month') {
        final created = DateTime.tryParse(n.createdAt);
        return created != null && created.month == now.month && created.year == now.year;
      } else if (_filter == 'week') {
        final created = DateTime.tryParse(n.createdAt);
        if (created == null) return false;
        final diff = now.difference(created).inDays;
        return diff <= 7;
      }
      return true;
    }).toList();
  }

  int get _totalCompleted => _allNotifications.where((n) => n.requiresActionResponse && n.isResponded).length;

  int get _monthCompleted {
    final now = DateTime.now();
    return _allNotifications.where((n) {
      if (!n.requiresActionResponse || !n.isResponded) return false;
      final created = DateTime.tryParse(n.createdAt);
      return created != null && created.month == now.month && created.year == now.year;
    }).length;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
      case NotificationModel.typeSurveyScheduleRequest:
        return Constants.surveyColor;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeDesignApproval:
      case NotificationModel.typeFinalDesignRequest:
        return Constants.designColor;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Constants.estimasiColor;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Constants.financeColor;
      case NotificationModel.typeKontrakRequest:
        return Constants.kontrakColor;
      case NotificationModel.typeGambarKerjaRequest:
        return Constants.gambarKerjaColor;
      default:
        return Constants.konstruksiColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
        return Icons.assignment_outlined;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeFinalDesignRequest:
        return Icons.design_services_outlined;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Icons.calculate_outlined;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Icons.payment_outlined;
      case NotificationModel.typeKontrakRequest:
        return Icons.description_outlined;
      case NotificationModel.typeGambarKerjaRequest:
        return Icons.architecture_outlined;
      case NotificationModel.typeItemPekerjaanRequest:
        return Icons.build_outlined;
      case NotificationModel.typeWorkplanRequest:
        return Icons.calendar_today_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _formatDate(String s) {
    try {
      final dt = DateTime.parse(s);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return s; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Padding(padding: EdgeInsets.only(top: 60), child: TaskSkeleton())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: Constants.accentColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text('Riwayat Tugas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Constants.textDark)),
                      const SizedBox(height: 16),

                      // Summary
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('$_totalCompleted', 'Total Tugas Selesai', Constants.successColor)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('$_monthCompleted', 'Bulan Ini', Constants.financeColor)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Filters
                      Row(
                        children: [
                          _buildChip('Semua', 'all'),
                          const SizedBox(width: 8),
                          _buildChip('Bulan Ini', 'month'),
                          const SizedBox(width: 8),
                          _buildChip('Minggu Ini', 'week'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Task list
                      if (_completedTasks.isEmpty)
                        _buildEmptyState()
                      else
                        ...List.generate(_completedTasks.length, (i) => _buildTaskCard(_completedTasks[i])),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Constants.textDark)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Constants.textMedium)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Constants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Constants.primaryColor : Constants.textLight.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? Colors.white : Constants.textMedium),
        ),
      ),
    );
  }

  Widget _buildTaskCard(NotificationModel n) {
    final color = _getTypeColor(n.type);
    final icon = _getTypeIcon(n.type);
    final responseTime = n.responseInfo?['time'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Constants.secondaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  n.order?.namaProject ?? '',
                  style: const TextStyle(fontSize: 12, color: Constants.textLight),
                ),
                if (responseTime != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Direspon:  ${_formatDate(responseTime)}',
                    style: TextStyle(fontSize: 11, color: Constants.successColor),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, size: 22, color: Constants.successColor.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Constants.textLight.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Belum ada tugas selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.textMedium)),
            const SizedBox(height: 6),
            Text('Tugas yang sudah direspon akan muncul di sini', style: TextStyle(fontSize: 13, color: Constants.textLight)),
          ],
        ),
      ),
    );
  }
}
