import 'tenant.dart';
import 'karyawan.dart';

class User {
  final int? id;
  final int? tenantId;
  final int? karyawanId;
  final String? name;
  final String? username;
  final String? email;
  final String? password; // Biasanya null saat menerima response dari API (Hidden)
  final String? role;
  final DateTime? emailVerifiedAt;
  final String? rememberToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Tenant? tenant;
  final Karyawan? karyawan;

  User({
    this.id,
    this.tenantId,
    this.karyawanId,
    this.name,
    this.username,
    this.email,
    this.password,
    this.role,
    this.emailVerifiedAt,
    this.rememberToken,
    this.createdAt,
    this.updatedAt,
    this.tenant,
    this.karyawan,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      name: json['name'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      role: json['role'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
      rememberToken: json['remember_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
      karyawan: json['karyawan'] != null
          ? Karyawan.fromJson(json['karyawan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'karyawan_id': karyawanId,
      'name': name,
      'username': username,
      'email': email,
      if (password != null) 'password': password,
      'role': role,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'remember_token': rememberToken,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'tenant': tenant?.toJson(),
      'karyawan': karyawan?.toJson(),
    };
  }
}