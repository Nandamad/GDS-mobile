import 'user.dart'; // Pastikan file user.dart sudah ada

class AuditLog {
  final int? id;
  final int? tenantId;
  final int? changedBy;
  final String? event;
  final String? auditableType;
  final int? auditableId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? url;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi ke Model User (belongsTo 'changed_by')
  final User? user;

  AuditLog({
    this.id,
    this.tenantId,
    this.changedBy,
    this.event,
    this.auditableType,
    this.auditableId,
    this.oldValues,
    this.newValues,
    this.url,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      changedBy: json['changed_by'] as int?,
      event: json['event'] as String?,
      auditableType: json['auditable_type'] as String?,
      auditableId: json['auditable_id'] as int?,
      oldValues: json['old_values'] is Map<String, dynamic>
          ? json['old_values'] as Map<String, dynamic>
          : null,
      newValues: json['new_values'] is Map<String, dynamic>
          ? json['new_values'] as Map<String, dynamic>
          : null,
      url: json['url'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'changed_by': changedBy,
      'event': event,
      'auditable_type': auditableType,
      'auditable_id': auditableId,
      'old_values': oldValues,
      'new_values': newValues,
      'url': url,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}