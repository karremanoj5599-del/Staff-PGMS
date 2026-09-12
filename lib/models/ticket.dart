class Ticket {
  final int id;
  final int? tenantId;
  final String issueCategory;
  final String description;
  final String status;
  final String createdAt;
  final String? adminNotes;
  final int? rating;
  final String? feedback;
  final String? tenantName;
  final String? tenantMobile;
  final String? tenantRoom;
  final String? tenantBed;

  Ticket({
    required this.id,
    this.tenantId,
    required this.issueCategory,
    required this.description,
    required this.status,
    required this.createdAt,
    this.adminNotes,
    this.rating,
    this.feedback,
    this.tenantName,
    this.tenantMobile,
    this.tenantRoom,
    this.tenantBed,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      tenantId: json['tenant_id'] != null
          ? (json['tenant_id'] is int
              ? json['tenant_id']
              : int.tryParse(json['tenant_id'].toString()))
          : null,
      issueCategory: json['issue_category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      adminNotes: json['admin_notes']?.toString(),
      rating: json['rating'] != null ? int.tryParse(json['rating'].toString()) : null,
      feedback: json['feedback']?.toString(),
      tenantName: json['tenant_name']?.toString() ?? json['name']?.toString(),
      tenantMobile: json['tenant_mobile']?.toString() ?? json['mobile']?.toString(),
      tenantRoom: json['tenant_room']?.toString() ?? json['room_number']?.toString() ?? json['room']?.toString(),
      tenantBed: json['tenant_bed']?.toString() ?? json['bed_number']?.toString() ?? json['bed']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      'issue_category': issueCategory,
      'description': description,
      'status': status,
      'created_at': createdAt,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (rating != null) 'rating': rating,
      if (feedback != null) 'feedback': feedback,
      if (tenantName != null) 'tenant_name': tenantName,
      if (tenantMobile != null) 'tenant_mobile': tenantMobile,
      if (tenantRoom != null) 'tenant_room': tenantRoom,
      if (tenantBed != null) 'tenant_bed': tenantBed,
    };
  }

  Ticket copyWith({
    int? id,
    int? tenantId,
    String? issueCategory,
    String? description,
    String? status,
    String? createdAt,
    String? adminNotes,
    int? rating,
    String? feedback,
    String? tenantName,
    String? tenantMobile,
    String? tenantRoom,
    String? tenantBed,
  }) {
    return Ticket(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      issueCategory: issueCategory ?? this.issueCategory,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminNotes: adminNotes ?? this.adminNotes,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      tenantName: tenantName ?? this.tenantName,
      tenantMobile: tenantMobile ?? this.tenantMobile,
      tenantRoom: tenantRoom ?? this.tenantRoom,
      tenantBed: tenantBed ?? this.tenantBed,
    );
  }
}
