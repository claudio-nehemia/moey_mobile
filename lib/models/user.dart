class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final int? roleId;
  final String? roleName;
  final bool isKepalaMarketing;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? nearestTask;
  final Map<String, dynamic>? nearestPayment;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.roleId,
    this.roleName,
    this.isKepalaMarketing = false,
    this.createdAt,
    this.updatedAt,
    this.nearestTask,
    this.nearestPayment,
  });

  bool get isCustomerService => roleName == 'Customer Service';
  bool get isLegalAdmin => roleName == 'Legal Admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      roleId: json['role_id'],
      roleName: json['role_name'],
      isKepalaMarketing: json['is_kepala_marketing'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      nearestTask: json['nearest_task'],
      nearestPayment: json['nearest_payment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'role_id': roleId,
      'role_name': roleName,
      'is_kepala_marketing': isKepalaMarketing,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'nearest_task': nearestTask,
      'nearest_payment': nearestPayment,
    };
  }
}