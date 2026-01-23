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
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
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
      case typeSurveyScheduleRequest:
      case typeSurveyUlangRequest: // WAJIB RESPONS
      case typeWorkplanRequest: // WAJIB RESPONS
        return true;

      // These types don't create records, just view/redirect
      case typeDesignApproval:
      case typeInvoiceRequest:
      case typeApprovalMaterialRequest:
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

      case typeSurveyScheduleRequest:
        // Check if survey schedule has been responded (survey_response_time exists)
        return order!.surveyResponseTime != null;

      case typeGambarKerjaRequest:
        // Check if gambar kerja has been responded (response_time exists)
        return order!.gambarKerja?.responseTime != null;

      case typeSurveyUlangRequest:
        // Check if survey ulang has been responded (response_time exists)
        return order!.surveyUlang?.responseTime != null;

      case typeWorkplanRequest:
        // Check if any workplan item has been responded (any response_time exists)
        // Check from both order.itemPekerjaans and order.moodboard.itemPekerjaans

        // Check from order.moodboard.itemPekerjaans first
        if (order!.moodboard?.itemPekerjaans != null) {
          for (var ip in order!.moodboard!.itemPekerjaans!) {
            if (ip.workplanItems != null) {
              for (var workplan in ip.workplanItems!) {
                if (workplan.responseTime != null) {
                  return true;
                }
              }
            }
          }
        }

        // Fallback to order.itemPekerjaans
        if (order!.itemPekerjaans != null) {
          for (var ip in order!.itemPekerjaans!) {
            if (ip.workplanItems != null) {
              for (var workplan in ip.workplanItems!) {
                if (workplan.responseTime != null) {
                  return true;
                }
              }
            }
          }
        }

        return false;

      default:
        return false;
    }
  }

  /// Get response status text
  String get responseStatusText {
    return isResponded ? 'Responded' : 'Pending Response';
  }

  /// Get action text based on notification type
  String get actionText {
    switch (type) {
      case typeSurveyRequest:
        return 'Response Survey Result';
      case typeSurveyUlangRequest:
        return 'Response Re-Survey Result';
      case typeSurveyScheduleRequest:
        return 'Response Survey Schedule';
      case typeMoodboardRequest:
        return 'Response Moodboard';
      case typeEstimasiRequest:
        return 'Response Estimation';
      case typeCommitmentFeeRequest:
        return 'Response Commitment Fee';
      case typeFinalDesignRequest:
        return 'Response Final Design';
      case typeItemPekerjaanRequest:
        return 'Response Item Pekerjaan';
      case typeRabInternalRequest:
        return 'Response RAB Internal';
      case typeKontrakRequest:
        return 'Response to Contract';
      case typeGambarKerjaRequest:
        return 'Response Gambar Kerja';
      case typeWorkplanRequest:
        return 'Create Workplan';
      default:
        return 'Respond';
    }
  }

  /// Get notification description based on type
  String get notificationDescription {
    switch (type) {
      case typeSurveyRequest:
        return 'Please complete the initial survey for this project';
      case typeSurveyUlangRequest:
        return 'Please complete the re-survey after customer DP payment';
      case typeMoodboardRequest:
        return 'Create moodboard design for this project';
      case typeEstimasiRequest:
        return 'Create cost estimation for this project';
      case typeWorkplanRequest:
        return 'Create work plan schedule for this project';
      default:
        return message;
    }
  }

  /// Get response info (who and when)
  Map<String, String?>? get responseInfo {
    if (!isResponded) return null;

    switch (type) {
      case typeSurveyRequest:
        return {
          'by': order?.surveyResults != null ? 'Survey Team' : null,
          'time': null,
        };

      case typeSurveyUlangRequest:
        return {
          'by': order?.surveyUlang?.responseBy,
          'time': order?.surveyUlang?.responseTime,
        };

      case typeGambarKerjaRequest:
        return {
          'by': order?.gambarKerja?.responseBy,
          'time': order?.gambarKerja?.responseTime,
        };

      case typeSurveyScheduleRequest:
        return {
          'by': order?.surveyResponseBy,
          'time': order?.surveyResponseTime,
        };

      case typeWorkplanRequest:
        // Get first responded workplan item from moodboard.itemPekerjaans first
        if (order?.moodboard?.itemPekerjaans != null) {
          for (var ip in order!.moodboard!.itemPekerjaans!) {
            if (ip.workplanItems != null) {
              for (var workplan in ip.workplanItems!) {
                if (workplan.responseTime != null) {
                  return {
                    'by': workplan.responseBy,
                    'time': workplan.responseTime,
                  };
                }
              }
            }
          }
        }

        // Fallback to order.itemPekerjaans
        if (order?.itemPekerjaans != null) {
          for (var ip in order!.itemPekerjaans!) {
            if (ip.workplanItems != null) {
              for (var workplan in ip.workplanItems!) {
                if (workplan.responseTime != null) {
                  return {
                    'by': workplan.responseBy,
                    'time': workplan.responseTime,
                  };
                }
              }
            }
          }
        }
        return null;

      default:
        return null;
    }
  }

  /// Get PM response info (who and when) - PM Response is separate from regular response
  Map<String, String?>? get pmResponseInfo {
    switch (type) {
      case typeSurveyRequest:
        if (order?.surveyResults?.pmResponseTime != null) {
          return {
            'by': order?.surveyResults?.pmResponseBy,
            'time': order?.surveyResults?.pmResponseTime,
          };
        }
        return null;

      case typeMoodboardRequest:
      case typeEstimasiRequest:
      case typeCommitmentFeeRequest:
      case typeFinalDesignRequest:
      case typeItemPekerjaanRequest:
        // Check if moodboard has PM response
        if (order?.moodboard?.pmResponseTime != null) {
          return {
            'by': order?.moodboard?.pmResponseBy,
            'time': order?.moodboard?.pmResponseTime,
          };
        }
        return null;

      case typeSurveyUlangRequest:
        if (order?.surveyUlang?.pmResponseTime != null) {
          return {
            'by': order?.surveyUlang?.pmResponseBy,
            'time': order?.surveyUlang?.pmResponseTime,
          };
        }
        return null;

      case typeSurveyScheduleRequest:
        if (order?.pmSurveyResponseTime != null) {
          return {
            'by': order?.pmSurveyResponseBy,
            'time': order?.pmSurveyResponseTime,
          };
        }
        return null;

      case typeGambarKerjaRequest:
        if (order?.gambarKerja?.pmResponseTime != null) {
          return {
            'by': order?.gambarKerja?.pmResponseBy,
            'time': order?.gambarKerja?.pmResponseTime,
          };
        }
        return null;

      case typeWorkplanRequest:
        // Get first PM responded workplan item
        if (order?.moodboard?.itemPekerjaans != null) {
          for (var ip in order!.moodboard!.itemPekerjaans!) {
            if (ip.workplanItems != null) {
              for (var workplan in ip.workplanItems!) {
                if (workplan.pmResponseTime != null) {
                  return {
                    'by': workplan.pmResponseBy,
                    'time': workplan.pmResponseTime,
                  };
                }
              }
            }
          }
        }

        // Fallback to order.itemPekerjaans
        if (order?.itemPekerjaans != null) {
          for (var ip in order!.itemPekerjaans!) {
            if (ip.workplanItems != null) {
              for (var workplan in ip.workplanItems!) {
                if (workplan.pmResponseTime != null) {
                  return {
                    'by': workplan.pmResponseBy,
                    'time': workplan.pmResponseTime,
                  };
                }
              }
            }
          }
        }
        return null;

      default:
        return null;
    }
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
  static const String typeProjectManagementRequest =
      'project_management_request';
}

class Order {
  final int id;
  final String namaProject;
  final String? customerName;
  final String? tahapanProyek;

  final String? surveyResponseTime;
  final String? surveyResponseBy;
  final String? pmSurveyResponseTime;
  final String? pmSurveyResponseBy;

  final String? projectStatus;
  final SurveyResults? surveyResults;
  final Moodboard? moodboard;
  final List<ItemPekerjaan>? itemPekerjaans;
  final GambarKerja? gambarKerja;
  final SurveyUlang? surveyUlang;

  Order({
    required this.id,
    required this.namaProject,
    this.customerName,
    this.tahapanProyek,
    this.projectStatus,

    this.surveyResponseTime,
    this.surveyResponseBy,
    this.pmSurveyResponseTime,
    this.pmSurveyResponseBy,

    this.surveyResults,
    this.moodboard,
    this.itemPekerjaans,
    this.gambarKerja,
    this.surveyUlang,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      namaProject: json['nama_project'] ?? '',
      customerName: json['customer_name'],
      tahapanProyek: json['tahapan_proyek'],
      projectStatus: json['project_status'],
      surveyResponseTime: json['survey_response_time'],
      surveyResponseBy: json['survey_response_by'],
      pmSurveyResponseTime: json['pm_survey_response_time'],
      pmSurveyResponseBy: json['pm_survey_response_by'],
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
      surveyUlang: json['survey_ulang'] != null
          ? SurveyUlang.fromJson(json['survey_ulang'])
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
      'survey_response_time': surveyResponseTime,
      'survey_response_by': surveyResponseBy,
      'pm_survey_response_time': pmSurveyResponseTime,
      'pm_survey_response_by': pmSurveyResponseBy,
      'survey_results': surveyResults?.toJson(),
      'moodboard': moodboard?.toJson(),
      'item_pekerjaans': itemPekerjaans?.map((item) => item.toJson()).toList(),
      'gambar_kerja': gambarKerja?.toJson(),
      'survey_ulang': surveyUlang?.toJson(),
    };
  }
}

// Related models for checking response status
class SurveyResults {
  final int id;
  final String? pmResponseTime;
  final String? pmResponseBy;

  SurveyResults({required this.id, this.pmResponseTime, this.pmResponseBy});

  factory SurveyResults.fromJson(Map<String, dynamic> json) {
    return SurveyResults(
      id: json['id'],
      pmResponseTime: json['pm_response_time'],
      pmResponseBy: json['pm_response_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pm_response_time': pmResponseTime,
    'pm_response_by': pmResponseBy,
  };
}

class Moodboard {
  final int id;
  final String? moodboardFinal;
  final Estimasi? estimasi;
  final CommitmentFee? commitmentFee;
  final List<dynamic>? finalFiles;
  final List<ItemPekerjaan>? itemPekerjaans;
  final String? pmResponseTime;
  final String? pmResponseBy;

  Moodboard({
    required this.id,
    this.moodboardFinal,
    this.estimasi,
    this.commitmentFee,
    this.finalFiles,
    this.itemPekerjaans,
    this.pmResponseTime,
    this.pmResponseBy,
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
      itemPekerjaans: json['item_pekerjaans'] != null
          ? (json['item_pekerjaans'] as List)
                .map((item) => ItemPekerjaan.fromJson(item))
                .toList()
          : null,
      pmResponseTime: json['pm_response_time'],
      pmResponseBy: json['pm_response_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodboard_final': moodboardFinal,
      'estimasi': estimasi?.toJson(),
      'commitment_fee': commitmentFee?.toJson(),
      'final_files': finalFiles,
      'item_pekerjaans': itemPekerjaans?.map((item) => item.toJson()).toList(),
      'pm_response_time': pmResponseTime,
      'pm_response_by': pmResponseBy,
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
  final List<WorkplanItem>? workplanItems;

  ItemPekerjaan({
    required this.id,
    this.rabInternal,
    this.kontrak,
    this.workplanItems,
  });

  factory ItemPekerjaan.fromJson(Map<String, dynamic> json) {
    List<WorkplanItem>? workplanItems;

    // Parse nested workplan_items dari produks
    if (json['produks'] != null) {
      final produks = json['produks'] as List;
      workplanItems = [];
      for (var produk in produks) {
        if (produk['workplan_items'] != null) {
          final items = (produk['workplan_items'] as List)
              .map((item) => WorkplanItem.fromJson(item))
              .toList();
          workplanItems.addAll(items);
        }
      }
    }

    return ItemPekerjaan(
      id: json['id'],
      rabInternal: json['rab_internal'] != null
          ? RabInternal.fromJson(json['rab_internal'])
          : null,
      kontrak: json['kontrak'] != null
          ? Kontrak.fromJson(json['kontrak'])
          : null,
      workplanItems: workplanItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rab_internal': rabInternal?.toJson(),
      'kontrak': kontrak?.toJson(),
      'workplan_items': workplanItems?.map((item) => item.toJson()).toList(),
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

class WorkplanItem {
  final int id;
  final String? responseTime;
  final String? responseBy;
  final String? pmResponseTime;
  final String? pmResponseBy;

  WorkplanItem({
    required this.id,
    this.responseTime,
    this.responseBy,
    this.pmResponseTime,
    this.pmResponseBy,
  });

  factory WorkplanItem.fromJson(Map<String, dynamic> json) {
    return WorkplanItem(
      id: json['id'],
      responseTime: json['response_time'],
      responseBy: json['response_by'],
      pmResponseTime: json['pm_response_time'],
      pmResponseBy: json['pm_response_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'response_time': responseTime,
    'response_by': responseBy,
    'pm_response_time': pmResponseTime,
    'pm_response_by': pmResponseBy,
  };
}

class GambarKerja {
  final int id;
  final String? responseTime;
  final String? responseBy;
  final String? pmResponseTime;
  final String? pmResponseBy;

  GambarKerja({
    required this.id,
    this.responseTime,
    this.responseBy,
    this.pmResponseTime,
    this.pmResponseBy,
  });

  factory GambarKerja.fromJson(Map<String, dynamic> json) {
    return GambarKerja(
      id: json['id'],
      responseTime: json['response_time'],
      responseBy: json['response_by'],
      pmResponseTime: json['pm_response_time'],
      pmResponseBy: json['pm_response_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'response_time': responseTime,
    'response_by': responseBy,
    'pm_response_time': pmResponseTime,
    'pm_response_by': pmResponseBy,
  };
}

class SurveyUlang {
  final int id;
  final String? responseTime;
  final String? responseBy;
  final String? pmResponseTime;
  final String? pmResponseBy;

  SurveyUlang({
    required this.id,
    this.responseTime,
    this.responseBy,
    this.pmResponseTime,
    this.pmResponseBy,
  });

  factory SurveyUlang.fromJson(Map<String, dynamic> json) {
    return SurveyUlang(
      id: json['id'],
      responseTime: json['response_time'],
      responseBy: json['response_by'],
      pmResponseTime: json['pm_response_time'],
      pmResponseBy: json['pm_response_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'response_time': responseTime,
    'response_by': responseBy,
    'pm_response_time': pmResponseTime,
    'pm_response_by': pmResponseBy,
  };
}

// Extension for null-safe access
extension ListExtension<T> on List<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }
}
