/// User model representing a user in the attendance system
class UserModel {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String password;
  final int departmentId;
  final String? position;
  final String? contactNumber;

  UserModel({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.departmentId,
    this.position,
    this.contactNumber,
  });

  /// Factory constructor for creating UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      email: json['user_email'] ?? '',
      firstName: json['user_fname'] ?? '',
      lastName: json['user_lname'] ?? '',
      password: json['user_password'] ?? '',
      departmentId: json['user_department'] ?? 0,
      position: json['position'],
      contactNumber: json['contact_number'],
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_email': email,
      'user_fname': firstName,
      'user_lname': lastName,
      'user_password': password,
      'user_department': departmentId,
      'position': position,
      'contact_number': contactNumber,
    };
  }

  /// Get full name
  String get fullName => '$firstName $lastName';
}
