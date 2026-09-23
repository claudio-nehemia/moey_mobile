import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../utils/constant.dart';

class NotificationHelpers {
  NotificationHelpers._();

  static Color getColor(String type) {
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
      case NotificationModel.typeApprovalMaterialRequest:
        return Constants.approvalColor;
      case NotificationModel.typeProjectManagementRequest:
        return Constants.pmColor;
      case NotificationModel.typePengumuman:
        return Colors.purple;
      default:
        return Constants.konstruksiColor;
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case NotificationModel.typeSurveyRequest:
      case NotificationModel.typeSurveyUlangRequest:
        return Icons.assignment_outlined;
      case NotificationModel.typeSurveyScheduleRequest:
        return Icons.event_available_outlined;
      case NotificationModel.typeMoodboardRequest:
      case NotificationModel.typeFinalDesignRequest:
        return Icons.design_services_outlined;
      case NotificationModel.typeDesignApproval:
        return Icons.verified_outlined;
      case NotificationModel.typeEstimasiRequest:
      case NotificationModel.typeRabInternalRequest:
        return Icons.calculate_outlined;
      case NotificationModel.typeCommitmentFeeRequest:
      case NotificationModel.typeInvoiceRequest:
        return Icons.payment_outlined;
      case NotificationModel.typeKontrakRequest:
        return Icons.description_outlined;
      case NotificationModel.typeItemPekerjaanRequest:
        return Icons.build_outlined;
      case NotificationModel.typeWorkplanRequest:
        return Icons.calendar_today_outlined;
      case NotificationModel.typeGambarKerjaRequest:
        return Icons.architecture_outlined;
      case NotificationModel.typeApprovalMaterialRequest:
        return Icons.check_circle_outline;
      case NotificationModel.typeProjectManagementRequest:
        return Icons.account_tree_outlined;
      case NotificationModel.typePengumuman:
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  static String formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  static String formatResponseTime(String s) {
    try {
      final dt = DateTime.parse(s);
      return '${dt.day}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }
}
