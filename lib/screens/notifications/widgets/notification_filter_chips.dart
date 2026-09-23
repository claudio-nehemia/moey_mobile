import 'package:flutter/material.dart';
import '../../../utils/constant.dart';

class NotificationFilterChips extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const NotificationFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          _buildChip('Semua', 'all'),
          const SizedBox(width: 8),
          _buildChip('Belum Dibaca', 'unread'),
          const SizedBox(width: 8),
          _buildChip('Sudah Dibaca', 'read'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final active = currentFilter == value;
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Constants.primaryColor.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? Constants.primaryColor : Constants.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Constants.primaryColor : Constants.textMedium,
          ),
        ),
      ),
    );
  }
}
