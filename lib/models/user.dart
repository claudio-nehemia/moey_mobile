class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final int? roleId;
  final bool isKepalaMarketing;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.roleId,
    this.isKepalaMarketing = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      roleId: json['role_id'],
      isKepalaMarketing: json['is_kepala_marketing'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'role_id': roleId,
      'is_kepala_marketing': isKepalaMarketing,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}