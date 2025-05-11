class User {
  final String id;
  final String username;
  final String email;
  final int? age;
  final DateTime createdAt;
  final DateTime updateAt;
  final String? profileImage;
  final String? password;
  final String role;
  final String? phoneNumber;
  final bool emailVerified;
  final int loginAttempts;
  final String provider;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.age,
    required this.createdAt,
    required this.updateAt,
    this.profileImage,
    this.password,
    required this.role,
    this.phoneNumber,
    required this.emailVerified,
    required this.loginAttempts,
    required this.provider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      age: json['age'],
      createdAt: DateTime.parse(json['createdAt']),
      updateAt: DateTime.parse(json['updateAt']),
      profileImage: json['profileImage'],
      password: json['password'],
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      emailVerified: json['emailVerified'],
      loginAttempts: json['loginAttempts'],
      provider: json['provider'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'updateAt': updateAt.toIso8601String(),
      'profileImage': profileImage,
      'password': password,
      'role': role,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'loginAttempts': loginAttempts,
      'provider': provider,
    };
  }
}
