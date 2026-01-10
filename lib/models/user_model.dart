class User {
  final String loginId;
  final String password;
  final String fullName;

  User({
    required this.loginId,
    required this.password,
    required this.fullName,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'loginId': loginId,
      'password': password,
      'fullName': fullName,
    };
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      loginId: json['loginId'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
    );
  }
}
