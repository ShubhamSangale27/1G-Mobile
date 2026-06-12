import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.mobile,
    required this.role,
    required this.emailVerified,
    required this.mobileVerified,
    this.active,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        role: json['role'] as String? ?? 'USER',
        emailVerified: json['emailVerified'] as bool? ?? false,
        mobileVerified: json['mobileVerified'] as bool? ?? false,
        active: json['active'] as bool?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'mobile': mobile,
        'role': role,
        'emailVerified': emailVerified,
        'mobileVerified': mobileVerified,
        if (active != null) 'active': active,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      };

  final int id;
  final String email;
  final String fullName;
  final String mobile;
  final String role;
  final bool emailVerified;
  final bool mobileVerified;
  final bool? active;
  final String? profileImageUrl;

  bool get isLoggedIn => true;

  @override
  List<Object?> get props => [id, email, role, profileImageUrl];
}

class AuthSession extends Equatable {
  const AuthSession({required this.user, required this.accessToken, required this.refreshToken});

  final User user;
  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [user.id, accessToken];
}

class SignupResult {
  const SignupResult({
    required this.message,
    required this.email,
    required this.mobile,
    this.resendAttemptsRemaining,
    this.resendAvailableAt,
  });

  factory SignupResult.fromJson(Map<String, dynamic> json) => SignupResult(
        message: json['message'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        resendAttemptsRemaining: json['resendAttemptsRemaining'] as int?,
        resendAvailableAt: json['resendAvailableAt'] as String?,
      );

  final String message;
  final String email;
  final String mobile;
  final int? resendAttemptsRemaining;
  final String? resendAvailableAt;
}

class PasswordOtpResult {
  const PasswordOtpResult({required this.message, this.maskedMobile});

  factory PasswordOtpResult.fromJson(Map<String, dynamic> json) => PasswordOtpResult(
        message: json['message'] as String? ?? '',
        maskedMobile: json['maskedMobile'] as String?,
      );

  final String message;
  final String? maskedMobile;
}
