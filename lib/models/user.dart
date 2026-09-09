class User {
  final int id;
  final String name;
  final String? email;
  final String? mobile;
  final String role;
  final int? adminUserId;
  final bool? isAvailable;
  final String? tradeType;

  User({
    required this.id,
    required this.name,
    this.email,
    this.mobile,
    required this.role,
    this.adminUserId,
    this.isAvailable,
    this.tradeType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      role: json['role']?.toString() ?? 'staff',
      adminUserId: json['admin_user_id'] != null
          ? (json['admin_user_id'] is int
              ? json['admin_user_id']
              : int.tryParse(json['admin_user_id'].toString()))
          : null,
      isAvailable: json['is_available'] as bool?,
      tradeType: json['trade_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      'role': role,
      if (adminUserId != null) 'admin_user_id': adminUserId,
      if (isAvailable != null) 'is_available': isAvailable,
      if (tradeType != null) 'trade_type': tradeType,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? mobile,
    String? role,
    int? adminUserId,
    bool? isAvailable,
    String? tradeType,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      adminUserId: adminUserId ?? this.adminUserId,
      isAvailable: isAvailable ?? this.isAvailable,
      tradeType: tradeType ?? this.tradeType,
    );
  }
}
