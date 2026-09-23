import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class OrderDetailHelpers {
  OrderDetailHelpers._();

  static Color getStatusColor(String status) {
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

  static Color getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Constants.errorColor;
      case 'medium':
        return Constants.warningColor;
      default:
        return Constants.successColor;
    }
  }

  static String formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
