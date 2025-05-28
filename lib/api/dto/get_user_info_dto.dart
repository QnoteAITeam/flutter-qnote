class FetchUserResponseDto {
  final String id;
  final String username;
  final String email;
  final int? age;
  final String? profileImage;
  final String? phoneNumber;
  final int loginAttempts;
  final String provider;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updateAt;
  final String role;

  FetchUserResponseDto({
    required this.id,
    required this.username,
    required this.email,
    required this.age,
    required this.profileImage,
    required this.phoneNumber,
    required this.loginAttempts,
    required this.provider,
    required this.emailVerified,
    required this.createdAt,
    required this.updateAt,
    required this.role,
  });

  factory FetchUserResponseDto.fromJson(Map<String, dynamic> json) {
    return FetchUserResponseDto(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      age: json['age'] ?? null,
      profileImage: json['profileImage'] ?? null,
      phoneNumber: json['phoneNumber'] ?? null,
      loginAttempts: json['loginAttempts'],
      provider: json['provider'] as String,
      emailVerified: json['emailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updateAt: DateTime.parse(json['updateAt'] as String),
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'age': age,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'loginAttempts': loginAttempts,
      'provider': provider,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updateAt': updateAt.toIso8601String(),
      'role': role,
    };
  }
}
