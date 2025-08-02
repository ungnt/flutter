class UserModel {
  final String? id;
  final String email;
  final String name;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.email,
    required this.name,
    this.isPremium = false,
    this.premiumExpiresAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isPremium: json['is_premium'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null 
          ? DateTime.parse(json['premium_expires_at'] as String) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'email': email,
      'name': name,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
    };
    
    if (id != null) map['id'] = id!;
    if (premiumExpiresAt != null) map['premium_expires_at'] = premiumExpiresAt!.toIso8601String();
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, isPremium: $isPremium)';
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
    };
  }

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
    );
  }
}

class AuthResponse {
  final UserModel user;
  final String token;
  final DateTime expiresAt;

  AuthResponse({
    required this.user,
    required this.token,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}