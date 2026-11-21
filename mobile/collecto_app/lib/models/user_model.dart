class UserModel {
  final int id;
  final String phoneNumber;
  final String fullName;
  final String role;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phone_number'],
      fullName: json['full_name'],
      role: json['role'],
    );
  }
}
