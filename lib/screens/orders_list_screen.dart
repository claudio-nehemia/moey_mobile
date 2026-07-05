import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../utils/constant.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final OrderService _orderService = OrderService();
  final _searchController = TextEditingController();

  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getOrders();
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _filteredOrders = orders;
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

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders.where((order) {
          final projectName = (order['nama_project'] ?? '').toString().toLowerCase();
          final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
          final companyName = (order['company_name'] ?? '').toString().toLowerCase();
          final interiorType = (order['jenis_interior'] ?? '').toString().toLowerCase();
          final status = (order['project_status'] ?? '').toString().toLowerCase();

          return projectName.contains(query) ||
              customerName.contains(query) ||
              companyName.contains(query) ||
              interiorType.contains(query) ||
              status.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _navigateToCreateOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
    );

    if (result == true) {
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Order Proyek',
          style: TextStyle(
            color: Constants.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Constants.cardColor,
        elevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Constants.borderColor, width: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Constants.textDark, size: 20),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildOrdersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateOrder,
        backgroundColor: Constants.primaryColor,
        elevation: 3,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text(
          'Buat Order',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.1),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: Constants.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Constants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Constants.borderColor),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 13, color: Constants.textDark),
          decoration: InputDecoration(
            hintText: 'Cari nama proyek, customer, dll...',
            hintStyle: const TextStyle(color: Constants.textLight, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Constants.textMedium, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Constants.textMedium),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
          ),
        ),
      ),
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
              _errorMessage ?? 'Gagal memuat order',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Constants.textDark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
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

  Widget _buildMiniStepper(String? currentPhase) {
    final phases = ['survey', 'moodboard', 'rab_internal', 'kontrak'];
    final phaseLabels = ['Survey', 'Desain', 'RAB', 'Kontrak'];
    
    int activeIndex = 0;
    final normalized = (currentPhase ?? 'survey').toLowerCase();
    if (normalized.contains('survey')) activeIndex = 0;
    else if (normalized.contains('moodboard') || normalized.contains('desain')) activeIndex = 1;
    else if (normalized.contains('rab') || normalized.contains('estimasi')) activeIndex = 2;
    else if (normalized.contains('kontrak') || normalized.contains('selesai')) activeIndex = 3;

    return Row(
      children: List.generate(phases.length, (index) {
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        final circleColor = isCompleted
            ? Constants.successColor
            : isActive
                ? Constants.primaryColor
                : Constants.textLight.withOpacity(0.3);
        
        return Expanded(
          child: Row(
            children: [
              // Circle indicator
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleColor,
                    width: isActive ? 4 : 1,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 4),
              // Label text
              Text(
                phaseLabels[index],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Constants.textDark : Constants.textMedium.withOpacity(0.8),
                ),
              ),
              if (index < phases.length - 1) ...[
                const SizedBox(width: 4),
                // Connector line
                Expanded(
                  child: Container(
                    height: 1,
                    color: isCompleted ? Constants.successColor : Constants.borderColor,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center_outlined, size: 40, color: Constants.textLight.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isNotEmpty ? 'Pencarian tidak ditemukan' : 'Belum ada order proyek',
                style: const TextStyle(fontSize: 13, color: Constants.textMedium, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Constants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          final statusColor = _getStatusColor(order['project_status'] ?? 'pending');
          final dateStr = order['created_at'] != null
              ? _formatDate(DateTime.tryParse(order['created_at']) ?? DateTime.now())
              : '-';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(orderId: order['id']),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Constants.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: statusColor, width: 4.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order['nama_project'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Constants.textDark,
                              ),
                            ),
                          ),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.business_outlined, 'Perusahaan', order['company_name']),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.person_outline, 'Customer', order['customer_name']),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.category_outlined, 'Tipe Interior', order['jenis_interior']),
                      const Divider(height: 20, color: Constants.borderColor),
                      _buildMiniStepper(order['tahapan_proyek'] ?? order['project_status']),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dibuat: $dateStr',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Constants.textLight,
                            ),
                          ),
                          Text(
                            'ID: #${order['id']}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Constants.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Constants.surfaceColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: Constants.textMedium),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Constants.textLight),
        ),
        Expanded(
          child: Text(
            value ?? '-',
            style: const TextStyle(fontSize: 11, color: Constants.textDark, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
