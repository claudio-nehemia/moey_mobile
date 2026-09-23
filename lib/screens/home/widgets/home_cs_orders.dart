import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../utils/constant.dart';
import '../../order_detail_screen.dart';

class HomeCsOrders extends StatelessWidget {
  final User? currentUser;
  final List<dynamic> csOrders;
  final VoidCallback onRefresh;

  const HomeCsOrders({
    super.key,
    required this.currentUser,
    required this.csOrders,
    required this.onRefresh,
  });

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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser?.isCustomerService != true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Daftar Proyek Anda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Constants.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (csOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 36,
                    color: Constants.textLight.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada proyek yang dibuat',
                    style: TextStyle(
                      fontSize: 13,
                      color: Constants.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(csOrders.length, (i) {
            final order = csOrders[i];
            final statusColor = _getStatusColor(order['project_status'] ?? 'pending');
            final dateStr = order['created_at'] != null
                ? _formatDate(DateTime.tryParse(order['created_at']) ?? DateTime.now())
                : '-';

            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: order['id']),
                  ),
                );
                if (result == true) {
                  onRefresh();
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: i < csOrders.length - 1 ? 10 : 0),
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Constants.primaryColor, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Constants.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.business_center_outlined,
                            size: 18,
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['nama_project'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Customer: ${order['customer_name'] ?? '-'} (${order['company_name'] ?? '-'})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Constants.textMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Dibuat: $dateStr',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Constants.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (order['tahapan_proyek'] ?? order['project_status'] ?? 'pending')
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
