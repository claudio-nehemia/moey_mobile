class NotificationModel {
  final int id;
  final int userId;
  final int? orderId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final String updatedAt;
  final Order? order;

  NotificationModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.order,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      orderId: json['order_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'order': order?.toJson(),
    };
  }

  /// Check if notification requires creating a record (action response)
  /// Returns true for notification types that create records
  bool get requiresActionResponse {
    switch (type) {
      case typeSurveyRequest:
      case typeMoodboardRequest:
      case typeEstimasiRequest:
      case typeCommitmentFeeRequest:
      case typeFinalDesignRequest:
      case typeItemPekerjaanRequest:
      case typeRabInternalRequest:
      case typeKontrakRequest:
      case typeGambarKerjaRequest:
        return true;
      
      // These types don't create records, just view/redirect
      case typeDesignApproval:
      case typeInvoiceRequest:
      case typeSurveyScheduleRequest:
      case typeSurveyUlangRequest:
      case typeApprovalMaterialRequest:
      case typeWorkplanRequest:
      case typeProjectManagementRequest:
        return false;
      
      default:
        return false;
    }
  }

  /// Check if notification has been responded to
  /// Returns true if the related record exists based on notification type
  bool get isResponded {
    if (order == null) return false;

    // For view-only notifications, always return false (no response tracking)
    if (!requiresActionResponse) return false;

    switch (type) {
      case typeSurveyRequest:
        return order!.surveyResults != null;
      
      case typeMoodboardRequest:
        return order!.moodboard != null;
      
      case typeEstimasiRequest:
        return order!.moodboard?.estimasi != null;
      
      case typeCommitmentFeeRequest:
        return order!.moodboard?.commitmentFee != null;
      
      case typeFinalDesignRequest:
        return order!.moodboard?.moodboardFinal != null || 
               (order!.moodboard?.finalFiles?.isNotEmpty ?? false);
      
      case typeItemPekerjaanRequest:
        return order!.itemPekerjaans?.isNotEmpty ?? false;
      
      case typeRabInternalRequest:
        final itemPekerjaan = order!.itemPekerjaans?.firstOrNull;
        return itemPekerjaan?.rabInternal != null;
      
      case typeKontrakRequest:
        final itemPekerjaan = order!.itemPekerjaans?.firstOrNull;
        return itemPekerjaan?.kontrak != null;
      
      case typeGambarKerjaRequest:
        return order!.gambarKerja != null;
      
      default:
        return false;
    }
  }

  /// Get response status text
  String get responseStatusText {
    return isResponded ? 'Responded' : 'Pending Response';
  }

  // Notification type constants
  static const String typeSurveyRequest = 'survey_request';
  static const String typeMoodboardRequest = 'moodboard_request';
  static const String typeEstimasiRequest = 'estimasi_request';
  static const String typeDesignApproval = 'design_approval';
  static const String typeCommitmentFeeRequest = 'commitment_fee_request';
  static const String typeFinalDesignRequest = 'final_design_request';
  static const String typeItemPekerjaanRequest = 'item_pekerjaan_request';
  static const String typeRabInternalRequest = 'rab_internal_request';
  static const String typeKontrakRequest = 'kontrak_request';
  static const String typeInvoiceRequest = 'invoice_request';
  static const String typeSurveyScheduleRequest = 'survey_schedule_request';
  static const String typeSurveyUlangRequest = 'survey_ulang_request';
  static const String typeGambarKerjaRequest = 'gambar_kerja_request';
  static const String typeApprovalMaterialRequest = 'approval_material_request';
  static const String typeWorkplanRequest = 'workplan_request';
  static const String typeProjectManagementRequest = 'project_management_request';
}

class Order {
  final int id;
  final String namaProject;
  final String? customerName;
  final String? tahapanProyek;
  final String? projectStatus;
  final SurveyResults? surveyResults;
  final Moodboard? moodboard;
  final List<ItemPekerjaan>? itemPekerjaans;
  final GambarKerja? gambarKerja;

  Order({
    required this.id,
    required this.namaProject,
    this.customerName,
    this.tahapanProyek,
    this.projectStatus,
    this.surveyResults,
    this.moodboard,
    this.itemPekerjaans,
    this.gambarKerja,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      namaProject: json['nama_project'] ?? '',
      customerName: json['customer_name'],
      tahapanProyek: json['tahapan_proyek'],
      projectStatus: json['project_status'],
      surveyResults: json['survey_results'] != null 
          ? SurveyResults.fromJson(json['survey_results']) 
          : null,
      moodboard: json['moodboard'] != null 
          ? Moodboard.fromJson(json['moodboard']) 
          : null,
      itemPekerjaans: json['item_pekerjaans'] != null
          ? (json['item_pekerjaans'] as List)
              .map((item) => ItemPekerjaan.fromJson(item))
              .toList()
          : null,
      gambarKerja: json['gambar_kerja'] != null 
          ? GambarKerja.fromJson(json['gambar_kerja']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_project': namaProject,
      'customer_name': customerName,
      'tahapan_proyek': tahapanProyek,
      'project_status': projectStatus,
      'survey_results': surveyResults?.toJson(),
      'moodboard': moodboard?.toJson(),
      'item_pekerjaans': itemPekerjaans?.map((item) => item.toJson()).toList(),
      'gambar_kerja': gambarKerja?.toJson(),
    };
  }
}

// Related models for checking response status
class SurveyResults {
  final int id;

  SurveyResults({required this.id});

  factory SurveyResults.fromJson(Map<String, dynamic> json) {
    return SurveyResults(id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class Moodboard {
  final int id;
  final String? moodboardFinal;
  final Estimasi? estimasi;
  final CommitmentFee? commitmentFee;
  final List<dynamic>? finalFiles;

  Moodboard({
    required this.id,
    this.moodboardFinal,
    this.estimasi,
    this.commitmentFee,
    this.finalFiles,
  });

  factory Moodboard.fromJson(Map<String, dynamic> json) {
    return Moodboard(
      id: json['id'],
      moodboardFinal: json['moodboard_final'],
      estimasi: json['estimasi'] != null 
          ? Estimasi.fromJson(json['estimasi']) 
          : null,
      commitmentFee: json['commitment_fee'] != null 
          ? CommitmentFee.fromJson(json['commitment_fee']) 
          : null,
      finalFiles: json['final_files'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodboard_final': moodboardFinal,
      'estimasi': estimasi?.toJson(),
      'commitment_fee': commitmentFee?.toJson(),
      'final_files': finalFiles,
    };
  }
}

class Estimasi {
  final int id;

  Estimasi({required this.id});

  factory Estimasi.fromJson(Map<String, dynamic> json) {
    return Estimasi(id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class CommitmentFee {
  final int id;

  CommitmentFee({required this.id});

  factory CommitmentFee.fromJson(Map<String, dynamic> json) {
    return CommitmentFee(id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class ItemPekerjaan {
  final int id;
  final RabInternal? rabInternal;
  final Kontrak? kontrak;

  ItemPekerjaan({
    required this.id,
    this.rabInternal,
    this.kontrak,
  });

  factory ItemPekerjaan.fromJson(Map<String, dynamic> json) {
    return ItemPekerjaan(
      id: json['id'],
      rabInternal: json['rab_internal'] != null 
          ? RabInternal.fromJson(json['rab_internal']) 
          : null,
      kontrak: json['kontrak'] != null 
          ? Kontrak.fromJson(json['kontrak']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rab_internal': rabInternal?.toJson(),
      'kontrak': kontrak?.toJson(),
    };
  }
}

class RabInternal {
  final int id;

  RabInternal({required this.id});

  factory RabInternal.fromJson(Map<String, dynamic> json) {
    return RabInternal(id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class Kontrak {
  final int id;

  Kontrak({required this.id});

  factory Kontrak.fromJson(Map<String, dynamic> json) {
    return Kontrak(id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class GambarKerja {
  final int id;

  GambarKerja({required this.id});

  factory GambarKerja.fromJson(Map<String, dynamic> json) {
    return GambarKerja(id: json['id']);
  }

  Map<String, dynamic> toJson() => {'id': id};
}

// Extension for null-safe access
extension ListExtension<T> on List<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }
}