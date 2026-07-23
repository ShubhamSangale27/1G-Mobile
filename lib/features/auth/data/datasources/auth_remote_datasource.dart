import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/user.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return _parseAuth(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String fullName,
    required String mobile,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/signup', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'mobile': mobile,
      });
      return SignupResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AuthSession> verifySignup({
    required String email,
    required String mobile,
    required String mobileOtp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/verify-signup', data: {
        'email': email,
        'mobile': mobile,
        'mobileOtp': mobileOtp,
      });
      return _parseAuth(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SignupResult> resendSignupOtp(String email, String mobile) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/resend-signup-otp', data: {
        'email': email,
        'mobile': mobile,
      });
      return SignupResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
  }

  Future<PasswordOtpResult> forgotPassword(String email) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/forgot-password', data: {'email': email});
      return PasswordOtpResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<PasswordOtpResult> sendChangePasswordOtp() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/change-password/send-otp');
      return PasswordOtpResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> changePassword({required String otp, required String newPassword}) async {
    try {
      await _dio.post('/auth/change-password', data: {'otp': otp, 'newPassword': newPassword});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _dio.post('/auth/send-email-verification');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<User> getProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<User> updateProfile({
    required String fullName,
    required String email,
    String? profileImageUrl,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/users/me', data: {
        'fullName': fullName,
        'email': email,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });
      return User.fromJson(res.data!);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await _dio.delete('/users/me', data: {'password': password});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  AuthSession _parseAuth(Map<String, dynamic> data) => AuthSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
      );
}
